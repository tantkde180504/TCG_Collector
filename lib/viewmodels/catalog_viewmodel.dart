import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pokemon_card.dart';
import '../services/database_service.dart';
import '../services/tcg_api_service.dart';

class CatalogViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<PokemonCard> _allCards = [];
  List<PokemonCard> _filteredCards = [];
  bool _isLoading = false;
  
  String _searchQuery = '';
  String _selectedType = 'All'; // All, Fire, Water, Grass, Lightning, Psychic, Dark, Colorless
  String _sortBy = 'Name'; // Name, PriceAsc, PriceDesc, HP

  Timer? _debounce;

  List<PokemonCard> get cards => _filteredCards;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  String get sortBy => _sortBy;

  CatalogViewModel() {
    Future.microtask(() => loadCatalog());
  }

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<PokemonCard> fetched = [];
      if (_searchQuery.isEmpty) {
        fetched = await TcgApiService.instance.fetchCards(query: 'set.id:sv3pt5', pageSize: 40);
      } else {
        fetched = await TcgApiService.instance.fetchCards(query: 'name:"*$_searchQuery*"', pageSize: 40);
      }

      if (fetched.isNotEmpty) {
        // Before caching, merge the current SQLite stock values so they are preserved
        final cachedCards = await _db.getCards();
        final stockMap = {for (var c in cachedCards) c.id: c.stockQuantity};

        // Apply existing stock to newly fetched cards
        final mergedCards = fetched.map((card) {
          final existingStock = stockMap[card.id];
          if (existingStock != null) {
            return PokemonCard(
              id: card.id, name: card.name, type: card.type, rarity: card.rarity,
              marketPrice: card.marketPrice, priceHistory: card.priceHistory,
              description: card.description, imageUrl: card.imageUrl, hp: card.hp,
              attackName: card.attackName, attackDamage: card.attackDamage,
              weakness: card.weakness, retreatCost: card.retreatCost,
              stockQuantity: existingStock,
            );
          }
          return card;
        }).toList();

        _allCards = mergedCards;
        await _db.cacheCards(_allCards);
      } else if (_allCards.isEmpty) {
        _allCards = await _db.getCards();
      } else {
        // Re-read from SQLite to pick up any stock changes made while app is running
        final refreshed = await _db.getCards();
        if (refreshed.isNotEmpty) _allCards = refreshed;
      }

      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error loading cards: $e');
      // On error, still try to read from local DB so stock changes show
      final local = await _db.getCards();
      if (local.isNotEmpty) {
        _allCards = local;
        _applyFilterAndSort();
      }
    }

    _isLoading = false;
    notifyListeners();
  }


  void setSearchQuery(String query) {
    _searchQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      loadCatalog();
    });
    // Optional: apply local filter immediately while waiting for API
    _applyFilterAndSort();
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _selectedType = type;
    _applyFilterAndSort();
    notifyListeners();
  }

  void setSortOption(String sortOption) {
    _sortBy = sortOption;
    _applyFilterAndSort();
    notifyListeners();
  }

  /// Cập nhật tồn kho một thẻ ngay trong bộ nhớ (không cần re-fetch từ network)
  void updateCardStockInMemory(String cardId, int newStock) {
    final idx = _allCards.indexWhere((c) => c.id == cardId);
    if (idx < 0) return;
    final old = _allCards[idx];
    _allCards[idx] = PokemonCard(
      id: old.id, name: old.name, type: old.type, rarity: old.rarity,
      marketPrice: old.marketPrice, priceHistory: old.priceHistory,
      description: old.description, imageUrl: old.imageUrl, hp: old.hp,
      attackName: old.attackName, attackDamage: old.attackDamage,
      weakness: old.weakness, retreatCost: old.retreatCost,
      stockQuantity: newStock,
    );
    _applyFilterAndSort();
    notifyListeners();
  }

  void _applyFilterAndSort() {
    List<PokemonCard> temp = List.from(_allCards);

    // Filter by card system type
    if (_selectedType != 'All') {
      temp = temp.where((card) => card.type.toLowerCase() == _selectedType.toLowerCase()).toList();
    }

    // Sorting logic
    switch (_sortBy) {
      case 'PriceAsc':
        temp.sort((a, b) => a.marketPrice.compareTo(b.marketPrice));
        break;
      case 'PriceDesc':
        temp.sort((a, b) => b.marketPrice.compareTo(a.marketPrice));
        break;
      case 'HP':
        temp.sort((a, b) => b.hp.compareTo(a.hp)); // descending HP
        break;
      case 'Name':
      default:
        temp.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    _filteredCards = temp;
  }
}
