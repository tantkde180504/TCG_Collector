import 'package:flutter_test/flutter_test.dart';
import 'package:tcg/models/pokemon_card.dart';
import 'package:tcg/viewmodels/cart_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartViewModel Unit Tests', () {
    late CartViewModel cartViewModel;
    late PokemonCard card1;
    late PokemonCard card2;

    setUp(() {
      cartViewModel = CartViewModel();
      
      card1 = PokemonCard(
        id: 'p-test-01',
        name: 'Test Charizard',
        type: 'Fire',
        rarity: 'Ultra Rare',
        marketPrice: 100.0,
        priceHistory: [95, 100],
        description: 'Test fire description',
        imageUrl: '',
        hp: 300,
        attackName: 'Fire blast',
        attackDamage: 200,
        weakness: 'Water x2',
        retreatCost: 2,
      );

      card2 = PokemonCard(
        id: 'p-test-02',
        name: 'Test Pikachu',
        type: 'Lightning',
        rarity: 'Common',
        marketPrice: 50.0,
        priceHistory: [48, 50],
        description: 'Test electric description',
        imageUrl: '',
        hp: 100,
        attackName: 'Thunderbolt',
        attackDamage: 80,
        weakness: 'Fighting x2',
        retreatCost: 1,
      );
    });

    test('Initial cart is empty', () {
      expect(cartViewModel.items.isEmpty, true);
      expect(cartViewModel.subtotal, 0.0);
      expect(cartViewModel.grandTotal, 7.99); // Shipping cost default
    });

    test('Adding cards to cart updates totals', () async {
      await cartViewModel.addToCart(card1, quantity: 2);
      expect(cartViewModel.items.length, 1);
      expect(cartViewModel.items.first.card.id, 'p-test-01');
      expect(cartViewModel.items.first.quantity, 2);
      expect(cartViewModel.subtotal, 200.0);
      expect(cartViewModel.shippingCost, 0.0); // Subtotal > 150 gets free shipping!
      expect(cartViewModel.grandTotal, 200.0);
    });

    test('Quantity update adjust calculations', () async {
      await cartViewModel.addToCart(card2, quantity: 1);
      expect(cartViewModel.subtotal, 50.0);
      expect(cartViewModel.shippingCost, 7.99); // < 150 pays shipping
      expect(cartViewModel.grandTotal, 57.99);

      await cartViewModel.updateQuantity(card2.id, 3);
      expect(cartViewModel.items.first.quantity, 3);
      expect(cartViewModel.subtotal, 150.0);
      expect(cartViewModel.shippingCost, 7.99); // exactly 150 pays shipping
      expect(cartViewModel.grandTotal, 157.99);
    });

    test('Applying coupon codes affects grand total', () async {
      await cartViewModel.addToCart(card1, quantity: 1); // Subtotal = $100
      expect(cartViewModel.grandTotal, 107.99); // $100 + $7.99 shipping

      // Apply 10% coupon
      final success = cartViewModel.applyCoupon('PIKACHU10');
      expect(success, true);
      expect(cartViewModel.appliedCoupon, 'PIKACHU10');
      expect(cartViewModel.discountAmount, 10.0);
      expect(cartViewModel.grandTotal, 97.99); // $100 - $10 + $7.99

      // Apply 20% coupon
      final success2 = cartViewModel.applyCoupon('CHARIZARD20');
      expect(success2, true);
      expect(cartViewModel.appliedCoupon, 'CHARIZARD20');
      expect(cartViewModel.discountAmount, 20.0);
      expect(cartViewModel.grandTotal, 87.99); // $100 - $20 + $7.99
    });

    test('Removing cards from cart works', () async {
      await cartViewModel.addToCart(card1, quantity: 1);
      await cartViewModel.addToCart(card2, quantity: 1);
      expect(cartViewModel.items.length, 2);

      await cartViewModel.removeFromCart(card1.id);
      expect(cartViewModel.items.length, 1);
      expect(cartViewModel.items.first.card.id, 'p-test-02');
    });

    test('Clearing cart resets all states', () async {
      await cartViewModel.addToCart(card1, quantity: 5);
      expect(cartViewModel.items.isNotEmpty, true);

      await cartViewModel.clearCart();
      expect(cartViewModel.items.isEmpty, true);
      expect(cartViewModel.subtotal, 0.0);
    });
  });
}
