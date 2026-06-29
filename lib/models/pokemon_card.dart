class PokemonCard {
  final String id;
  final String name;
  final String type; // Fire, Water, Grass, Lightning, Psychic, Dark, Colorless
  final String rarity; // Common, Uncommon, Rare Holo, Ultra Rare, Secret Rare
  final double marketPrice;
  final List<double> priceHistory; // 7 days of price points
  final String description;
  final String imageUrl;
  final int hp;
  final String attackName;
  final int attackDamage;
  final String weakness;
  final int retreatCost;

  PokemonCard({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.marketPrice,
    required this.priceHistory,
    required this.description,
    required this.imageUrl,
    required this.hp,
    required this.attackName,
    required this.attackDamage,
    required this.weakness,
    required this.retreatCost,
  });

  // Convert a PokemonCard into a Map. The keys must correspond to the database columns.
  Map<String, dynamic> toMap() {
    return {
      'card_id': id,
      'name': name,
      'type': type,
      'rarity': rarity,
      'market_price': marketPrice,
      'price_history': priceHistory.join(','), // store as comma-separated string in DB
      'description': description,
      'image_url': imageUrl,
      'hp': hp,
      'attack_name': attackName,
      'attack_damage': attackDamage,
      'weakness': weakness,
      'retreat_cost': retreatCost,
    };
  }

  // Create a PokemonCard from a Map.
  factory PokemonCard.fromMap(Map<String, dynamic> map) {
    List<double> history;
    final rawHistory = map['price_history'];
    if (rawHistory != null) {
      if (rawHistory is List) {
        // Firestore Array type: [115.0, 118.0, ...]
        history = rawHistory
            .map((e) => (e as num?)?.toDouble() ?? 0.0)
            .where((v) => v > 0 && !v.isNaN && !v.isInfinite)
            .toList();
      } else {
        // String type (SQLite or old Firestore): "115.0,118.0,..."
        final str = rawHistory.toString().trim();
        // Strip surrounding brackets if present: "[115.0, 118.0]"
        final cleaned = str.startsWith('[') && str.endsWith(']')
            ? str.substring(1, str.length - 1)
            : str;
        history = cleaned
            .split(',')
            .map((e) => double.tryParse(e.trim()) ?? 0.0)
            .where((v) => v > 0 && !v.isNaN && !v.isInfinite)
            .toList();
      }
    } else {
      history = [];
    }

    // Fallback: nếu history rỗng, dùng marketPrice làm điểm duy nhất
    if (history.isEmpty) {
      final mp = (map['market_price'] as num?)?.toDouble() ?? 0.0;
      if (mp > 0) history = [mp];
    }


    return PokemonCard(
      id: map['card_id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Colorless',
      rarity: map['rarity'] ?? 'Common',
      marketPrice: (map['market_price'] as num?)?.toDouble() ?? 0.0,
      priceHistory: history,
      description: map['description'] ?? '',
      imageUrl: map['image_url'] ?? '',
      hp: map['hp'] ?? 0,
      attackName: map['attack_name'] ?? '',
      attackDamage: map['attack_damage'] ?? 0,
      weakness: map['weakness'] ?? 'None',
      retreatCost: map['retreat_cost'] ?? 1,
    );
  }
}
