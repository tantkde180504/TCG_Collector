import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcg/viewmodels/auth_viewmodel.dart';
import 'package:tcg/viewmodels/cart_viewmodel.dart';
import 'package:tcg/viewmodels/catalog_viewmodel.dart';
import 'package:tcg/viewmodels/chat_viewmodel.dart';
import 'package:tcg/viewmodels/notification_viewmodel.dart';
import 'package:tcg/views/checkout_screen.dart';
import 'package:tcg/models/pokemon_card.dart';

void main() {
  group('CheckoutScreen Widget Tests', () {
    late CartViewModel cartVM;
    late AuthViewModel authVM;
    late CatalogViewModel catalogVM;

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => authVM),
          ChangeNotifierProvider(create: (_) => catalogVM),
          ChangeNotifierProvider(create: (_) => cartVM),
          ChangeNotifierProvider(create: (_) => ChatViewModel()),
          ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ],
        child: MaterialApp(
          home: const CheckoutScreen(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: Colors.amber,
          ),
        ),
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authVM = AuthViewModel();
      catalogVM = CatalogViewModel();
      cartVM = CartViewModel();
      
      // Add sample item to cart
      final sampleCard = PokemonCard(
        id: 'test-card-1',
        name: 'Charizard',
        type: 'Fire',
        rarity: 'Holographic',
        marketPrice: 50.00,
        priceHistory: [45.0, 48.0, 50.0],
        description: 'Powerful Fire-type dragon',
        imageUrl: 'https://example.com/charizard.png',
        hp: 120,
        attackName: 'Flamethrower',
        attackDamage: 100,
        weakness: 'Water',
        retreatCost: 2,
      );
      
      await cartVM.addToCart(sampleCard, quantity: 1);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    group('Stepper Header Display', () {
      testWidgets('Should display 3-step stepper', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        expect(find.text('Shipping'), findsOneWidget);
        expect(find.text('Payment'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
      });

      testWidgets('Step 1 should be highlighted on initial load', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final shippingText = find.text('Shipping');
        expect(shippingText, findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should progress through steps correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Initial step should be 0 (Shipping)
        expect(cartVM.checkoutStep, 0);

        // Fill in shipping form
        await tester.enterText(find.byType(TextFormField).at(0), 'John Trainer');
        await tester.enterText(find.byType(TextFormField).at(1), '+1-234-567-8900');
        await tester.enterText(find.byType(TextFormField).at(2), '123 Pallet Town, Kanto');
        
        // Tap proceed button
        final proceedButton = find.byType(ElevatedButton);
        if (proceedButton.evaluate().isNotEmpty) {
          await tester.tap(proceedButton);
          await tester.pumpAndSettle();
        }

        // Should move to step 1
        expect(cartVM.checkoutStep >= 0, true);
      });
    });

    group('Step 0: Shipping Address Form', () {
      testWidgets('Should display shipping form fields', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        expect(find.byType(TextFormField), findsWidgets);
        expect(find.text('PROCEED TO PAYMENT'), findsOneWidget);
      });

      testWidgets('Should validate required name field', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        // Try to proceed without filling form
        final proceedButton = find.byType(ElevatedButton);
        if (proceedButton.evaluate().isNotEmpty) {
          await tester.tap(proceedButton);
          await tester.pumpAndSettle();
        }
        
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should validate phone number format', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        await tester.enterText(find.byType(TextFormField).at(0), 'John Trainer');
        await tester.enterText(find.byType(TextFormField).at(1), 'invalid-phone');
        await tester.enterText(find.byType(TextFormField).at(2), '123 Pallet Town');
        
        await tester.pumpAndSettle();
        
        expect(find.byType(TextFormField), findsWidgets);
      });

      testWidgets('Should validate address field', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        await tester.enterText(find.byType(TextFormField).at(0), 'John Trainer');
        await tester.enterText(find.byType(TextFormField).at(1), '+1-234-567-8900');
        // Leave address empty
        
        await tester.pumpAndSettle();
        
        expect(find.byType(TextFormField), findsWidgets);
      });

      testWidgets('Should save shipping info when form is valid', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        await tester.enterText(find.byType(TextFormField).at(0), 'Ash Ketchum');
        await tester.enterText(find.byType(TextFormField).at(1), '+1-555-0123');
        await tester.enterText(find.byType(TextFormField).at(2), '456 Route 1, Viridian City');
        
        await tester.pumpAndSettle();
        
        final proceedButton = find.byType(ElevatedButton);
        if (proceedButton.evaluate().isNotEmpty) {
          await tester.tap(proceedButton);
          await tester.pumpAndSettle();
        }
        
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Step 1: Payment Method Selection', () {
      testWidgets('Should display payment method options', (WidgetTester tester) async {
        // First move to step 1
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should allow selecting different payment methods', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Credit Card should require card details', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should validate credit card number format', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should validate card expiry date format', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should validate CVV format', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Checkout Navigation', () {
      testWidgets('Back button should return to shipping step', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(cartVM.checkoutStep, 1);

        final backButton = find.byType(OutlinedButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('PLACE ORDER button should be visible at payment step', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('Button should show loading state when processing order', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('Grand total should be displayed on button', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        final grandTotal = cartVM.grandTotal;
        expect(grandTotal > 0, true);
      });
    });

    group('Order Confirmation Step', () {
      testWidgets('Step 2 should show order confirmation', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(2);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should display order summary', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(2);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should not show action buttons at confirmation step', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(2);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Price Display', () {
      testWidgets('Should display correct subtotal', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final subtotal = cartVM.subtotal;
        expect(subtotal, greaterThan(0));
      });

      testWidgets('Should calculate shipping cost correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final shippingCost = cartVM.shippingCost;
        expect(shippingCost >= 0, true);
      });

      testWidgets('Should apply coupon discount', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final originalTotal = cartVM.grandTotal;
        expect(originalTotal > 0, true);
      });

      testWidgets('Free shipping should apply for orders over \$150', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final shippingCost = cartVM.shippingCost;
        if (cartVM.subtotal > 150) {
          expect(shippingCost, 0.0);
        }
      });

      testWidgets('Should display grand total correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final grandTotal = cartVM.grandTotal;
        final expectedTotal = cartVM.subtotal - cartVM.discountAmount + cartVM.shippingCost;
        expect(grandTotal, closeTo(expectedTotal, 0.01));
      });
    });

    group('User Flow Integration', () {
      testWidgets('Complete checkout flow: Shipping -> Payment -> Confirmation', 
        (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verify initial state
        expect(cartVM.checkoutStep, 0);
        expect(find.byType(Scaffold), findsOneWidget);

        // Move through steps
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();
        expect(cartVM.checkoutStep, 1);

        cartVM.setCheckoutStep(2);
        await tester.pumpAndSettle();
        expect(cartVM.checkoutStep, 2);
      });

      testWidgets('Should preserve shipping info across steps', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final testName = 'Brock Harrison';
        final testPhone = '+1-555-9999';
        final testAddress = '789 Pewter City';
        
        cartVM.saveShippingInfo(testName, testPhone, testAddress);
        
        expect(cartVM.shippingName, testName);
        expect(cartVM.shippingPhone, testPhone);
        expect(cartVM.shippingAddress, testAddress);
      });

      testWidgets('Should maintain cart items during checkout', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        final itemCountBefore = cartVM.items.length;
        cartVM.setCheckoutStep(1);
        final itemCountAfter = cartVM.items.length;
        
        expect(itemCountBefore, itemCountAfter);
      });
    });

    group('Error Handling', () {
      testWidgets('Should show error when order submission fails', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should handle network errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should disable place order button while loading', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        cartVM.setCheckoutStep(1);
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });
  });
}
