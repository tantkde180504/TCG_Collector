import 'dart:convert';
import 'cart_item.dart';
import 'pokemon_card.dart';

class OrderItem {
  final String orderId;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // Pending, Processing, Shipped, Delivered
  final DateTime timestamp;
  final String shippingAddress;
  final String paymentMethod;

  OrderItem({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.timestamp,
    required this.shippingAddress,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'items_json': json.encode(
        items.map((i) => {
          'card_id': i.card.id,
          'quantity': i.quantity,
          'price_at_purchase': i.card.marketPrice,
          'card_name': i.card.name,
          'card_image': i.card.imageUrl,
          'card_type': i.card.type,
        }).toList(),
      ),
      'total_amount': totalAmount,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map, List<PokemonCard> catalog) {
    final List<dynamic> itemsList = json.decode(map['items_json'] ?? '[]');
    
    final List<CartItem> parsedItems = itemsList.map((item) {
      final String cardId = item['card_id'] ?? '';
      // Find card in catalog or recreate it from serialized info
      PokemonCard card;
      final match = catalog.where((c) => c.id == cardId);
      if (match.isNotEmpty) {
        card = match.first;
      } else {
        card = PokemonCard(
          id: cardId,
          name: item['card_name'] ?? 'Unknown Card',
          type: item['card_type'] ?? 'Colorless',
          rarity: 'Common',
          marketPrice: (item['price_at_purchase'] as num?)?.toDouble() ?? 0.0,
          priceHistory: [],
          description: '',
          imageUrl: item['card_image'] ?? '',
          hp: 0,
          attackName: '',
          attackDamage: 0,
          weakness: 'None',
          retreatCost: 1,
        );
      }
      return CartItem(
        card: card,
        quantity: item['quantity'] ?? 1,
      );
    }).toList();

    return OrderItem(
      orderId: map['order_id'] ?? '',
      userId: map['user_id'] ?? '',
      items: parsedItems,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      shippingAddress: map['shipping_address'] ?? '',
      paymentMethod: map['payment_method'] ?? 'PokeGold',
    );
  }
}
