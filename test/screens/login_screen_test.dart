import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tcg/viewmodels/auth_viewmodel.dart';
import 'package:tcg/views/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidget() {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Email field exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Login button exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Password visibility toggle works',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('Demo credential button fills fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(
        find.text(
          'Use Demo Credentials (trainer.red@kanto.com)',
        ),
      );

      await tester.pump();

      expect(
        find.text('trainer.red@kanto.com'),
        findsOneWidget,
      );

      expect(
        find.text('123456'),
        findsOneWidget,
      );
    });

    testWidgets('Empty email validation blocks submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byType(TextFormField).at(1),
        '123456',
      );

      await tester.tap(find.byType(ElevatedButton));

      await tester.pumpAndSettle();

      expect(
        find.byType(LoginScreen),
        findsOneWidget,
      );
    });

    testWidgets('Invalid email validation blocks submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byType(TextFormField).first,
        'invalidemail',
      );

      await tester.enterText(
        find.byType(TextFormField).last,
        '123456',
      );

      await tester.tap(find.byType(ElevatedButton));

      await tester.pumpAndSettle();

      expect(
        find.byType(LoginScreen),
        findsOneWidget,
      );
    });

    testWidgets('Short password validation blocks submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byType(TextFormField).first,
        'trainer@test.com',
      );

      await tester.enterText(
        find.byType(TextFormField).last,
        '123',
      );

      await tester.tap(find.byType(ElevatedButton));

      await tester.pumpAndSettle();

      expect(
        find.byType(LoginScreen),
        findsOneWidget,
      );
    });

    testWidgets('Valid credentials can be entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byType(TextFormField).first,
        'trainer@test.com',
      );

      await tester.enterText(
        find.byType(TextFormField).last,
        '123456',
      );

      await tester.pump();

      expect(find.text('trainer@test.com'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('Social login buttons exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Nintendo'), findsOneWidget);
    });
  });
}