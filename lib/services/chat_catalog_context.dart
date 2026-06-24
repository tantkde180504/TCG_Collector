import '../models/pokemon_card.dart';

/// Builds catalog text from live database data for chat AI context.
class ChatCatalogContext {
  static const shopPolicies = '''
Shop policies:
- Standard shipping: 2-4 business days; free express delivery on orders above \$150.00, otherwise \$7.99
- Coupon codes: "PIKACHU10" (10% off), "CHARIZARD20" (20% off selected products)
- All cards are 100% authentic with a 3-step verification process
''';

  static String build(List<PokemonCard> cards) {
    if (cards.isEmpty) {
      return 'Shop catalog: no cards available right now.\n$shopPolicies';
    }

    final buffer = StringBuffer()
      ..writeln('Current shop catalog (${cards.length} cards):');

    for (final card in cards) {
      buffer.writeln(
        '- ${card.name} (ID: ${card.id}): ${card.type}-type, ${card.rarity}, '
        '\$${card.marketPrice.toStringAsFixed(2)}, ${card.hp} HP, '
        'attack "${card.attackName}" (${card.attackDamage} dmg), '
        'weakness: ${card.weakness}, retreat: ${card.retreatCost}. '
        '${card.description}',
      );
    }

    buffer.write(shopPolicies);
    return buffer.toString().trim();
  }
}
