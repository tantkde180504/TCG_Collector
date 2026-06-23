import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcg/viewmodels/auth_viewmodel.dart';

void main() {
  group('AuthViewModel Tests', () {
    late AuthViewModel authViewModel;

    setUp(() async {
      // Reset SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      authViewModel = AuthViewModel();
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    group('Authentication State', () {
      test('Should start as not authenticated', () async {
        authViewModel = AuthViewModel();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(authViewModel.isAuthenticated, false);
      });

      test('Initial displayName should have default value', () {
        expect(authViewModel.displayName, isNotEmpty);
      });

      test('Initial email should have default value', () {
        expect(authViewModel.email, isNotEmpty);
      });

      test('isLoading should be false by default', () {
        expect(authViewModel.isLoading, false);
      });
    });

    group('Email/Password Login', () {
      test('login with valid email and password should return true', () async {
        final result = await authViewModel.login('trainer@kanto.com', 'password123');

        expect(result, true);
        expect(authViewModel.isAuthenticated, true);
      });

      test('login with valid credentials should update displayName', () async {
        await authViewModel.login('ash@pallet.com', 'password123');

        expect(authViewModel.displayName, 'Ash');
        expect(authViewModel.email, 'ash@pallet.com');
      });

      test('login with invalid email format should return false', () async {
        final result = await authViewModel.login('notanemail', 'password123');

        expect(result, false);
        expect(authViewModel.isAuthenticated, false);
      });

      test('login with short password should return false', () async {
        final result = await authViewModel.login('trainer@kanto.com', '123');

        expect(result, false);
        expect(authViewModel.isAuthenticated, false);
      });

      test('login should extract name from email correctly', () async {
        await authViewModel.login('gary@oaklabs.com', 'password123');

        expect(authViewModel.displayName, 'Gary');
      });

      test('login should capitalize first letter of name', () async {
        await authViewModel.login('misty@cerulean.com', 'password123');

        final firstChar = authViewModel.displayName[0];
        expect(firstChar, firstChar.toUpperCase());
      });

      test('login should persist credentials to SharedPreferences', () async {
        await authViewModel.login('trainer@kanto.com', 'password123');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_authenticated'), true);
        expect(prefs.getString('email'), 'trainer@kanto.com');
      });

      test('isLoading should be false after login completes', () async {
        await authViewModel.login('trainer@kanto.com', 'password123');

        expect(authViewModel.isLoading, false);
      });
    });

    group('Social Login', () {
      test('loginSocial with Google should return true', () async {
        final result = await authViewModel.loginSocial('Google');

        expect(result, true);
        expect(authViewModel.isAuthenticated, true);
      });

      test('loginSocial with Google should set Gary Oak credentials', () async {
        await authViewModel.loginSocial('Google');

        expect(authViewModel.displayName, 'Gary Oak');
        expect(authViewModel.email, 'gary.oak@oaklabs.com');
      });

      test('loginSocial with other provider should set Ash Ketchum credentials', () async {
        await authViewModel.loginSocial('Facebook');

        expect(authViewModel.displayName, 'Ash Ketchum');
        expect(authViewModel.email, 'ash.ketchum@pallet.com');
      });

      test('loginSocial should persist credentials to SharedPreferences', () async {
        await authViewModel.loginSocial('Google');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_authenticated'), true);
        expect(prefs.getString('display_name'), 'Gary Oak');
      });

      test('isLoading should be false after social login completes', () async {
        await authViewModel.loginSocial('Google');

        expect(authViewModel.isLoading, false);
      });
    });

    group('Logout', () {
      test('logout should set isAuthenticated to false', () async {
        await authViewModel.login('trainer@kanto.com', 'password123');
        expect(authViewModel.isAuthenticated, true);

        await authViewModel.logout();

        expect(authViewModel.isAuthenticated, false);
      });

      test('logout should clear SharedPreferences', () async {
        await authViewModel.login('trainer@kanto.com', 'password123');
        await authViewModel.logout();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_authenticated'), null);
        expect(prefs.getString('display_name'), null);
        expect(prefs.getString('email'), null);
      });

      test('Can login again after logout', () async {
        await authViewModel.login('trainer@kanto.com', 'password123');
        await authViewModel.logout();

        final result = await authViewModel.login('newuser@kanto.com', 'password456');

        expect(result, true);
        expect(authViewModel.isAuthenticated, true);
        expect(authViewModel.email, 'newuser@kanto.com');
      });
    });

    group('Multiple Login Attempts', () {
      test('Failed login should not set isAuthenticated to true', () async {
        final result = await authViewModel.login('invalid', 'short');

        expect(result, false);
        expect(authViewModel.isAuthenticated, false);
      });

      test('Failed login followed by successful login should work', () async {
        await authViewModel.login('invalid', 'short');
        final result = await authViewModel.login('valid@email.com', 'password123');

        expect(result, true);
        expect(authViewModel.isAuthenticated, true);
      });
    });

    group('State Persistence', () {
      test('Credentials should persist across ViewModel instances', () async {
        // First instance login
        final firstViewModel = AuthViewModel();
        await firstViewModel.login('trainer@kanto.com', 'password123');

        // Create new instance
        await Future.delayed(const Duration(milliseconds: 150));
        final secondViewModel = AuthViewModel();
        await Future.delayed(const Duration(milliseconds: 150));

        // Check if persisted
        expect(secondViewModel.isAuthenticated, true);
        expect(secondViewModel.email, 'trainer@kanto.com');
      });
    });

    group('Email Validation Rules', () {
      test('Email must contain @ symbol', () async {
        final result = await authViewModel.login('invalidemailformat', 'password123');
        expect(result, false);
      });

      test('Password must be at least 6 characters', () async {
        final result = await authViewModel.login('trainer@kanto.com', '12345');
        expect(result, false);
      });

      test('Exactly 6 character password should be valid', () async {
        final result = await authViewModel.login('trainer@kanto.com', '123456');
        expect(result, true);
      });
    });
  });
}
