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
        // Fetch popular cards from a cool set (e.g., Pokémon 151)
        fetched = await TcgApiService.instance.fetchCards(query: 'set.id:sv3pt5', pageSize: 40);
      } else {
        // Dynamic search by name
        fetched = await TcgApiService.instance.fetchCards(query: 'name:"*$_searchQuery*"', pageSize: 40);
      }
      
      if (fetched.isNotEmpty) {
        _allCards = fetched;
        // Save them to local database to ensure cart and offline capabilities work
        await _db.cacheCards(_allCards);
      } else if (_allCards.isEmpty) {
        // Fallback to cached cards if offline and we have no cards currently
        _allCards = await _db.getCards();
      }

      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error loading cards: $e');
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
