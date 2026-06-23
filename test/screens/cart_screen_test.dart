import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:tcg/viewmodels/auth_viewmodel.dart';
import 'package:tcg/viewmodels/catalog_viewmodel.dart';
import 'package:tcg/viewmodels/cart_viewmodel.dart';
import 'package:tcg/viewmodels/chat_viewmodel.dart';
import 'package:tcg/viewmodels/notification_viewmodel.dart';

import 'package:tcg/views/cart_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CartScreen Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => CatalogViewModel()),
          ChangeNotifierProvider(create: (_) => CartViewModel()),
          ChangeNotifierProvider(create: (_) => ChatViewModel()),
          ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ],
        child: MaterialApp(
          home: const CartScreen(),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: Colors.amber,
          ),
        ),
      );
    }

    testWidgets('CartScreen should render', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('Empty cart should display empty cart icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('Empty cart should display title message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.text('Your Shopping Cart is Empty'), findsOneWidget);
    });

    testWidgets('Empty cart should display description message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(
          find.text('Add rare cards from the shop to start collection!'),
          findsOneWidget);
    });

    testWidgets('Empty cart should not show coupon field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Empty cart should not show checkout button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.text('PROCEED TO CHECKOUT'), findsNothing);
    });

    testWidgets('Empty cart should contain Scaffold',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Empty cart screen should contain Column layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('Empty cart screen should contain Center widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('Empty cart should render without exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}