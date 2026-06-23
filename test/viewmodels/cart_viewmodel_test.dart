import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tcg/viewmodels/cart_viewmodel.dart';
import 'package:tcg/models/pokemon_card.dart';
import 'package:tcg/models/cart_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CartViewModel Tests', () {
    late CartViewModel cartViewModel;

    setUp(() {
      cartViewModel = CartViewModel();
    });

    group('Cart Item Management', () {
      test('Initial cart should be empty', () {
        expect(cartViewModel.items.isEmpty, true);
      });

      test('addToCart should add item to cart', () async {
        final card = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        await cartViewModel.addToCart(card, quantity: 2);

        expect(cartViewModel.items.length, 1);
        expect(cartViewModel.items[0].quantity, 2);
        expect(cartViewModel.items[0].card.id, 'card1');
      });

      test('addToCart should increase quantity if card already in cart', () async {
        final card = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        await cartViewModel.addToCart(card, quantity: 1);
        await cartViewModel.addToCart(card, quantity: 2);

        expect(cartViewModel.items.length, 1);
        expect(cartViewModel.items[0].quantity, 3);
      });

      test('removeFromCart should remove item from cart', () async {
        final card = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        await cartViewModel.addToCart(card);
        await cartViewModel.removeFromCart('card1');

        expect(cartViewModel.items.isEmpty, true);
      });

      test('updateQuantity should update item quantity', () async {
        final card = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        await cartViewModel.addToCart(card, quantity: 1);
        await cartViewModel.updateQuantity('card1', 5);

        expect(cartViewModel.items[0].quantity, 5);
      });

      test('updateQuantity to 0 or less should remove item', () async {
        final card = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        await cartViewModel.addToCart(card);
        await cartViewModel.updateQuantity('card1', 0);

        expect(cartViewModel.items.isEmpty, true);
      });
    });

    group('Cart Pricing Calculations', () {
      test('subtotal should calculate correctly', () async {
        final card1 = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        final card2 = PokemonCard(
          id: 'card2',
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

        await cartViewModel.addToCart(card1, quantity: 2);
        await cartViewModel.addToCart(card2, quantity: 1);

        final expectedSubtotal = (25.50 * 2) + 150.00;
        expect(cartViewModel.subtotal, closeTo(expectedSubtotal, 0.01));
      });

      test('shippingCost should be 0 if subtotal > 150', () async {
        final card = PokemonCard(
          id: 'card1',
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

        await cartViewModel.addToCart(card, quantity: 2);

        expect(cartViewModel.shippingCost, 0.0);
      });

      test('shippingCost should be 7.99 if subtotal <= 150', () async {
        final card = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 25.50,
          priceHistory: [20.0, 22.0, 25.50],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        await cartViewModel.addToCart(card, quantity: 2);

        expect(cartViewModel.shippingCost, 7.99);
      });

      test('discountAmount should calculate correctly', () async {
        final card = PokemonCard(
          id: 'card1',
          name: 'Pikachu',
          type: 'Lightning',
          rarity: 'Rare Holo',
          marketPrice: 100.0,
          priceHistory: [90.0, 95.0, 100.0],
          description: 'Electric mouse Pokémon',
          imageUrl: 'https://example.com/pikachu.png',
          hp: 40,
          attackName: 'Thunderbolt',
          attackDamage: 30,
          weakness: 'Fighting',
          retreatCost: 1,
        );

        await cartViewModel.addToCart(card, quantity: 1);
        expect(cartViewModel.discountAmount, 0.0);
      });
    });

    group('Checkout State Management', () {
      test('checkoutStep should start at 0', () {
        expect(cartViewModel.checkoutStep, 0);
      });

      test('initial shipping info should be empty', () {
        expect(cartViewModel.shippingName, isEmpty);
        expect(cartViewModel.shippingAddress, isEmpty);
        expect(cartViewModel.shippingPhone, isEmpty);
      });

      test('initial payment method should be Credit Card', () {
        expect(cartViewModel.selectedPaymentMethod, 'Credit Card');
      });
    });
  });
}