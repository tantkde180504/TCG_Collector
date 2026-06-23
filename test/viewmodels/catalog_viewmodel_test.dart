import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tcg/viewmodels/catalog_viewmodel.dart';
import 'package:tcg/models/pokemon_card.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CatalogViewModel Tests', () {
    late CatalogViewModel catalogViewModel;

    setUp(() {
      catalogViewModel = CatalogViewModel();
    });

    group('Search and Filter', () {
      test('setSearchQuery should update searchQuery', () {
        catalogViewModel.setSearchQuery('Pikachu');
        expect(catalogViewModel.searchQuery, 'Pikachu');
      });

      test('setTypeFilter should update selectedType', () {
        catalogViewModel.setTypeFilter('Fire');
        expect(catalogViewModel.selectedType, 'Fire');
      });

      test('setSortOption should update sortBy', () {
        catalogViewModel.setSortOption('PriceAsc');
        expect(catalogViewModel.sortBy, 'PriceAsc');
      });

      test('setSearchQuery should filter cards correctly', () {
        catalogViewModel.setSearchQuery('');
        final initialCount = catalogViewModel.cards.length;
        catalogViewModel.setSearchQuery('Pikachu');
        expect(catalogViewModel.cards.length, lessThanOrEqualTo(initialCount));
      });

      test('setTypeFilter should filter cards by type', () {
        catalogViewModel.setTypeFilter('All');
        final allCount = catalogViewModel.cards.length;
        catalogViewModel.setTypeFilter('Fire');
        expect(catalogViewModel.cards.length, lessThanOrEqualTo(allCount));
        for (var card in catalogViewModel.cards) {
          expect(card.type.toLowerCase(), 'fire');
        }
      });
    });

    group('Sorting Options', () {
      test('PriceAsc sorting should sort by price ascending', () {
        catalogViewModel.setSortOption('PriceAsc');
        for (int i = 0; i < catalogViewModel.cards.length - 1; i++) {
          expect(catalogViewModel.cards[i].marketPrice,
              lessThanOrEqualTo(catalogViewModel.cards[i + 1].marketPrice));
        }
      });

      test('PriceDesc sorting should sort by price descending', () {
        catalogViewModel.setSortOption('PriceDesc');
        for (int i = 0; i < catalogViewModel.cards.length - 1; i++) {
          expect(catalogViewModel.cards[i].marketPrice,
              greaterThanOrEqualTo(catalogViewModel.cards[i + 1].marketPrice));
        }
      });

      test('HP sorting should sort by HP descending', () {
        catalogViewModel.setSortOption('HP');
        for (int i = 0; i < catalogViewModel.cards.length - 1; i++) {
          expect(catalogViewModel.cards[i].hp,
              greaterThanOrEqualTo(catalogViewModel.cards[i + 1].hp));
        }
      });

      test('Name sorting should sort alphabetically', () {
        catalogViewModel.setSortOption('Name');
        for (int i = 0; i < catalogViewModel.cards.length - 1; i++) {
          expect(
              catalogViewModel.cards[i].name
                  .compareTo(catalogViewModel.cards[i + 1].name),
              lessThanOrEqualTo(0));
        }
      });
    });

    group('Combined Filtering and Sorting', () {
      test('Search + Type filter + Sort should work together', () {
        catalogViewModel.setTypeFilter('Fire');
        catalogViewModel.setSearchQuery('Char');
        catalogViewModel.setSortOption('PriceAsc');
        for (var card in catalogViewModel.cards) {
          expect(card.type.toLowerCase(), 'fire');
          expect(
              card.name.toLowerCase().contains('char') ||
                  card.attackName.toLowerCase().contains('char') ||
                  card.description.toLowerCase().contains('char'),
              true);
        }
        for (int i = 0; i < catalogViewModel.cards.length - 1; i++) {
          expect(catalogViewModel.cards[i].marketPrice,
              lessThanOrEqualTo(catalogViewModel.cards[i + 1].marketPrice));
        }
      });

      test('Clearing filter should show all cards', () {
        catalogViewModel.setTypeFilter('Fire');
        final filteredCount = catalogViewModel.cards.length;
        catalogViewModel.setTypeFilter('All');
        final allCount = catalogViewModel.cards.length;
        expect(allCount, greaterThanOrEqualTo(filteredCount));
      });
    });

    group('Search Query Case Insensitivity', () {
      test('Search should be case insensitive', () {
        catalogViewModel.setSearchQuery('pikachu');
        final lowercaseResults = catalogViewModel.cards.length;
        catalogViewModel.setSearchQuery('PIKACHU');
        final uppercaseResults = catalogViewModel.cards.length;
        catalogViewModel.setSearchQuery('PiKaChU');
        final mixedResults = catalogViewModel.cards.length;
        expect(lowercaseResults, uppercaseResults);
        expect(uppercaseResults, mixedResults);
      });
    });

    group('Default State', () {
      test('Default search query should be empty', () {
        expect(catalogViewModel.searchQuery, isEmpty);
      });

      test('Default type filter should be All', () {
        expect(catalogViewModel.selectedType, 'All');
      });

      test('Default sort option should be Name', () {
        expect(catalogViewModel.sortBy, 'Name');
      });

      test('isLoading should be false after initialization', () {
        expect(catalogViewModel.isLoading, false);
      });
    });
  });
}