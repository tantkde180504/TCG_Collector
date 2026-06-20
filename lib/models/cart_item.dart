import 'pokemon_card.dart';

class CartItem {
  final PokemonCard card;
  int quantity;

  CartItem({
    required this.card,
    this.quantity = 1,
  });

  double get totalPrice => card.marketPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'card_id': card.id,
      'quantity': quantity,
    };
  }
}
