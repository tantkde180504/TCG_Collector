import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/pokemon_card.dart';

class TcgApiService {
  static final TcgApiService instance = TcgApiService._();
  TcgApiService._();

  static const String _baseUrl = 'https://api.pokemontcg.io/v2/cards';

  /// Fetch a list of cards from the API based on an optional search query.
  Future<List<PokemonCard>> fetchCards({
    String query = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl?page=$page&pageSize=$pageSize${query.isNotEmpty ? '&q=${Uri.encodeComponent(query)}' : ''}');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('TcgApiService: Failed to fetch cards (status ${response.statusCode})');
        return [];
      }

      final data = json.decode(response.body)['data'] as List<dynamic>?;
      if (data == null) return [];

      final List<PokemonCard> cards = [];
      for (var item in data) {
        cards.add(_parseCard(item as Map<String, dynamic>));
      }
      return cards;
    } catch (e) {
      debugPrint('TcgApiService: Error fetching cards: $e');
      return [];
    }
  }

  /// Fetch a single card by its exact ID (e.g., 'sv3pt5-199')
  Future<PokemonCard?> fetchCardById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body)['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      return _parseCard(data);
    } catch (e) {
      debugPrint('TcgApiService: Error fetching card $id: $e');
      return null;
    }
  }

  PokemonCard _parseCard(Map<String, dynamic> raw) {
    String? attackName;
    int attackDamage = 0;
    if (raw['attacks'] != null && raw['attacks'].isNotEmpty) {
      final atk = raw['attacks'].last;
      attackName = atk['name'];
      String dmgStr = atk['damage']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      attackDamage = int.tryParse(dmgStr) ?? 0;
    }

    String description = raw['flavorText'] ?? '';
    if (description.isEmpty && raw['rules'] != null && raw['rules'].isNotEmpty) {
      description = raw['rules'].first;
    }

    double livePrice = 0.0;
    if (raw['tcgplayer'] != null && raw['tcgplayer']['prices'] != null) {
      final pricesMap = raw['tcgplayer']['prices'];
      final priceEntry = (pricesMap['holofoil'] ??
          pricesMap['normal'] ??
          pricesMap['1stEditionHolofoil'] ??
          pricesMap.values.first);
      livePrice = (priceEntry['market'] ?? priceEntry['mid'] ?? 0.0).toDouble();
    } else if (raw['cardmarket'] != null && raw['cardmarket']['prices'] != null) {
      livePrice = (raw['cardmarket']['prices']['trendPrice'] ?? 0.0).toDouble();
    }

    return PokemonCard(
      id: raw['id'] ?? '',
      name: raw['name'] ?? 'Unknown',
      type: (raw['types'] != null && raw['types'].isNotEmpty) ? raw['types'].first : 'Colorless',
      rarity: raw['rarity'] ?? 'Common',
      marketPrice: livePrice,
      priceHistory: [livePrice], // API just provides current prices
      description: description,
      imageUrl: raw['images']?['large'] ?? raw['images']?['small'] ?? '',
      hp: int.tryParse(raw['hp'] ?? '') ?? 0,
      attackName: attackName ?? 'Tackle',
      attackDamage: attackDamage,
      weakness: (raw['weaknesses'] != null && raw['weaknesses'].isNotEmpty)
          ? '${raw['weaknesses'].first['type']} ${raw['weaknesses'].first['value']}'
          : 'None',
      retreatCost: (raw['retreatCost'] != null) ? (raw['retreatCost'] as List).length : 0,
    );
  }
}
