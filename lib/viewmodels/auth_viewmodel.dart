import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  // Mock fallbacks cho môi trường kiểm thử (Testing) khi chưa khởi tạo Firebase
  bool _mockAuthenticated = false;
  String _mockDisplayName = 'Trainer Red';
  String _mockEmail = 'trainer.red@kanto.com';

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  bool get isAuthenticated => _auth != null ? _user != null : _mockAuthenticated;
  
  String get displayName {
    if (_auth != null) {
      return _user?.displayName ?? _user?.email?.split('@')[0] ?? 'Trainer Red';
    }
    return _mockDisplayName;
  }
  
  String get email {
    if (_auth != null) {
      return _user?.email ?? 'trainer.red@kanto.com';
    }
    return _mockEmail;
  }
  
  String get photoUrl => _auth != null ? (_user?.photoURL ?? 'https://images.pokemontcg.io/logo.png') : 'https://images.pokemontcg.io/logo.png';
  bool get isLoading => _isLoading;
  String get userId => _auth != null ? (_user?.uid ?? '') : 'mock_user_id';

  AuthViewModel() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();
    
    final auth = _auth;
    if (auth != null) {
      auth.authStateChanges().listen((User? user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      });
    } else {
      // Mock khởi tạo từ SharedPreferences cho môi trường test
      final prefs = await SharedPreferences.getInstance();
      _mockAuthenticated = prefs.getBool('is_authenticated') ?? false;
      _mockDisplayName = prefs.getString('display_name') ?? 'Trainer Red';
      _mockEmail = prefs.getString('email') ?? 'trainer.red@kanto.com';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final auth = _auth;
    if (auth != null) {
      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        _isLoading = false;
        notifyListeners();
        return true;
      } on FirebaseAuthException catch (e) {
        // Tự động tạo tài khoản nếu chưa tồn tại
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          try {
            await auth.createUserWithEmailAndPassword(email: email, password: password);
            _isLoading = false;
            notifyListeners();
            return true;
          } catch (signUpError) {
            debugPrint('Automatic sign up error: $signUpError');
          }
        }
        debugPrint('Firebase Auth error: ${e.message}');
      } catch (e) {
        debugPrint('Login error: $e');
      }
    } else {
      // Logic giả lập khi chạy test
      await Future.delayed(const Duration(milliseconds: 50));
      if (email.contains('@') && password.length >= 6) {
        _mockAuthenticated = true;
        _mockDisplayName = email.split('@')[0];
        _mockDisplayName = _mockDisplayName.substring(0, 1).toUpperCase() + _mockDisplayName.substring(1);
        _mockEmail = email;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        await prefs.setString('display_name', _mockDisplayName);
        await prefs.setString('email', _mockEmail);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginSocial(String provider) async {
    _isLoading = true;
    notifyListeners();

    final auth = _auth;
    if (auth != null) {
      final mockEmail = provider == 'Google' ? 'gary.oak@oaklabs.com' : 'ash.ketchum@pallet.com';
      final mockPassword = 'socialpassword123';
      final mockName = provider == 'Google' ? 'Gary Oak' : 'Ash Ketchum';

      try {
        try {
          await auth.signInWithEmailAndPassword(email: mockEmail, password: mockPassword);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            UserCredential userCred = await auth.createUserWithEmailAndPassword(email: mockEmail, password: mockPassword);
            await userCred.user?.updateDisplayName(mockName);
          } else {
            rethrow;
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Social login simulation error: $e');
      }
    } else {
      // Giả lập social login khi chạy test
      await Future.delayed(const Duration(milliseconds: 50));
      _mockAuthenticated = true;
      if (provider == 'Google') {
        _mockDisplayName = 'Gary Oak';
        _mockEmail = 'gary.oak@oaklabs.com';
      } else {
        _mockDisplayName = 'Ash Ketchum';
        _mockEmail = 'ash.ketchum@pallet.com';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('display_name', _mockDisplayName);
      await prefs.setString('email', _mockEmail);

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    } else {
      _mockAuthenticated = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_authenticated');
      await prefs.remove('display_name');
      await prefs.remove('email');
    }
    notifyListeners();
  }
}
