import 'package:flutter/material.dart';
import '../models/pokemon_card.dart';
import '../services/database_service.dart';

class CatalogViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<PokemonCard> _allCards = [];
  List<PokemonCard> _filteredCards = [];
  bool _isLoading = false;
  
  String _searchQuery = '';
  String _selectedType = 'All'; // All, Fire, Water, Grass, Lightning, Psychic, Dark, Colorless
  String _sortBy = 'Name'; // Name, PriceAsc, PriceDesc, HP

  List<PokemonCard> get cards => _filteredCards;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  String get sortBy => _sortBy;

  CatalogViewModel() {
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allCards = await _db.getCards();
      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error loading cards: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
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

    // 1. Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((card) => 
        card.name.toLowerCase().contains(query) || 
        card.attackName.toLowerCase().contains(query) ||
        card.description.toLowerCase().contains(query)
      ).toList();
    }

    // 2. Filter by card system type
    if (_selectedType != 'All') {
      temp = temp.where((card) => card.type.toLowerCase() == _selectedType.toLowerCase()).toList();
    }

    // 3. Sorting logic
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
