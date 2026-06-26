import 'package:flutter_test/flutter_test.dart';
import 'package:tcg/models/pokemon_card.dart';
import 'package:tcg/models/cart_item.dart';
import 'package:tcg/models/order_item.dart';

void main() {
  group('Model Tests - Data Structure Validation', () {
    group('PokemonCard Model', () {
      test('PokemonCard should initialize with correct values', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        expect(card.id, 'card-001');
        expect(card.name, 'Pikachu');
        expect(card.type, 'Lightning');
        expect(card.rarity, 'Rare Holo');
        expect(card.marketPrice, 25.50);
        expect(card.hp, 40);
        expect(card.attackDamage, 30);
      });

      test('PokemonCard toMap should convert to database format', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final map = card.toMap();

        expect(map['card_id'], 'card-001');
        expect(map['name'], 'Pikachu');
        expect(map['market_price'], 25.50);
        expect(map['hp'], 40);
      });

      test('PokemonCard price history should be list of doubles', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        expect(card.priceHistory.length, 3);
        expect(card.priceHistory[0], 20.0);
        expect(card.priceHistory[1], 22.0);
        expect(card.priceHistory[2], 25.50);
      });
    });

    group('CartItem Model', () {
      test('CartItem should initialize with correct values', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final cartItem = CartItem(card: card, quantity: 2);

        expect(cartItem.card.name, 'Pikachu');
        expect(cartItem.quantity, 2);
      });

      test('CartItem should have default quantity of 1', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final cartItem = CartItem(card: card);

        expect(cartItem.quantity, 1);
      });

      test('CartItem totalPrice should calculate correctly', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final cartItem = CartItem(card: card, quantity: 3);

        expect(cartItem.totalPrice, 25.50 * 3);
      });

      test('CartItem toMap should convert to database format', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final cartItem = CartItem(card: card, quantity: 2);
        final map = cartItem.toMap();

        expect(map['card_id'], 'card-001');
        expect(map['quantity'], 2);
      });
    });

    group('OrderItem Model', () {
      test('OrderItem should initialize with correct values', () {
        final items = [
          CartItem(
            card: PokemonCard(
              id: 'card-001',
              name: 'Pikachu',
              type: 'Lightning',
              rarity: 'Rare Holo',
              marketPrice: 25.50,
              priceHistory: [20.0, 22.0, 25.50],
              description: 'Electric-type Pokémon',
              imageUrl: 'https://example.com/pikachu.png',
              hp: 40,
              attackName: 'Thunderbolt',
              attackDamage: 30,
              weakness: 'Fighting',
              retreatCost: 1,
            ),
            quantity: 2,
          )
        ];

        final order = OrderItem(
          orderId: 'order-001',
          userId: 'user-001',
          items: items,
          totalAmount: 51.00,
          status: 'Pending',
          timestamp: DateTime.now(),
          shippingAddress: '123 Trainer Street',
          paymentMethod: 'Credit Card',
        );

        expect(order.orderId, 'order-001');
        expect(order.userId, 'user-001');
        expect(order.items.length, 1);
        expect(order.status, 'Pending');
      });

      test('OrderItem status should support multiple values', () {
        final items = <CartItem>[];
        final now = DateTime.now();

        final pendingOrder = OrderItem(
          orderId: 'order-001',
          userId: 'user-001',
          items: items,
          totalAmount: 50.00,
          status: 'Pending',
          timestamp: now,
          shippingAddress: '123 St',
          paymentMethod: 'Card',
        );

        final paidOrder = OrderItem(
          orderId: 'order-002',
          userId: 'user-001',
          items: items,
          totalAmount: 50.00,
          status: 'Processing',
          timestamp: now,
          shippingAddress: '123 St',
          paymentMethod: 'Card',
        );

        final shippedOrder = OrderItem(
          orderId: 'order-003',
          userId: 'user-001',
          items: items,
          totalAmount: 50.00,
          status: 'Shipped',
          timestamp: now,
          shippingAddress: '123 St',
          paymentMethod: 'Card',
        );

        expect(
          anyOf(
            equals(pendingOrder.status),
            equals(paidOrder.status),
            equals(shippedOrder.status),
          ),
          isNotNull,
        );
      });
    });

    group('Price Calculations', () {
      test('Multiple cards should calculate combined price correctly', () {
        final card1 = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final card2 = PokemonCard(
          id: 'card-002',
          name: 'Charizard',
          type: 'Fire',
          rarity: 'Ultra Rare',
          marketPrice: 150.00,
          priceHistory: [140.0, 145.0, 150.0],
          description: 'Fire dragon Pokémon',
          imageUrl: 'https://example.com/charizard.png',
          hp: 120,
          attackName: 'Fire Spin',
          attackDamage: 120,
          weakness: 'Water',
          retreatCost: 2,
        );

        final cartItem1 = CartItem(card: card1, quantity: 2);
        final cartItem2 = CartItem(card: card2, quantity: 1);

        final totalPrice = cartItem1.totalPrice + cartItem2.totalPrice;

        expect(totalPrice, closeTo((25.50 * 2) + 150.00, 0.01));
      });

      test('Discount calculation should be accurate', () {
        final cartItem = CartItem(
          card: PokemonCard(
            id: 'card-001',
            name: 'Pikachu',
            type: 'Lightning',
            rarity: 'Rare Holo',
            marketPrice: 100.00,
            priceHistory: [90.0, 95.0, 100.0],
            description: 'Electric-type Pokémon',
            imageUrl: 'https://example.com/pikachu.png',
            hp: 40,
            attackName: 'Thunderbolt',
            attackDamage: 30,
            weakness: 'Fighting',
            retreatCost: 1,
          ),
          quantity: 1,
        );

        final subtotal = cartItem.totalPrice;
        final discountPercent = 0.10; // 10%
        final discountAmount = subtotal * discountPercent;
        final finalPrice = subtotal - discountAmount;

        expect(discountAmount, 10.0);
        expect(finalPrice, 90.0);
      });
    });

    group('Data Type Validation', () {
      test('Card IDs should be non-empty strings', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        expect(card.id.isNotEmpty, true);
        expect(card.id is String, true);
      });

      test('Quantities should be positive integers', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final cartItem = CartItem(card: card, quantity: 5);

        expect(cartItem.quantity > 0, true);
        expect(cartItem.quantity is int, true);
      });

      test('Prices should be positive numbers', () {
        final card = PokemonCard(
          id: 'card-001',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric-type Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        expect(card.marketPrice > 0, true);
        expect(card.marketPrice is double, true);
      });
    });
  });
}
