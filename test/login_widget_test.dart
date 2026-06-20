import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcg/viewmodels/auth_viewmodel.dart';
import 'package:tcg/viewmodels/catalog_viewmodel.dart';
import 'package:tcg/viewmodels/cart_viewmodel.dart';
import 'package:tcg/viewmodels/chat_viewmodel.dart';
import 'package:tcg/viewmodels/notification_viewmodel.dart';
import 'package:tcg/views/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CatalogViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Login screen elements are rendered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(); // Settle now works because SharedPreferences completes instantly!

      // Verify branding titles are present
      expect(find.text('POKÉMON TCG'), findsOneWidget);
      expect(find.text('TRAINER PORTAL'), findsOneWidget);

      // Verify email and password text fields are present
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Trainer Email'), findsOneWidget);
      expect(find.text('Secret Code'), findsOneWidget);

      // Verify login buttons are present
      expect(find.text('ENTER POKÉMON WORLD'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Nintendo'), findsOneWidget);
    });

    testWidgets('Submitting empty form triggers validation error alerts', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the Submit button without typing anything
      await tester.tap(find.text('ENTER POKÉMON WORLD'));
      await tester.pump(); // Trigger frame to show error texts

      // Verify validation warning messages are shown
      expect(find.text('Please enter a valid trainer email'), findsOneWidget);
      expect(find.text('Code must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Auto-fill credentials helper button works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on the demo credentials helper button
      final demoButton = find.text('Use Demo Credentials (trainer.red@kanto.com)');
      expect(demoButton, findsOneWidget);
      await tester.tap(demoButton);
      await tester.pump(); // Trigger frame to populate fields

      // Verify the TextFormFields have been populated
      expect(find.text('trainer.red@kanto.com'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
    });
  });
}
