import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _displayName = 'Trainer Red';
  String _email = 'trainer.red@kanto.com';
  String _photoUrl = 'https://images.pokemontcg.io/logo.png';
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String get displayName => _displayName;
  String get email => _email;
  String get photoUrl => _photoUrl;
  bool get isLoading => _isLoading;

  AuthViewModel() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('is_authenticated') ?? false;
    _displayName = prefs.getString('display_name') ?? 'Trainer Red';
    _email = prefs.getString('email') ?? 'trainer.red@kanto.com';
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Basic credentials validation mock
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate network latency

    if (email.contains('@') && password.length >= 6) {
      _isAuthenticated = true;
      // Extract name from email as a simple default
      _displayName = email.split('@')[0];
      _displayName = _displayName.substring(0, 1).toUpperCase() + _displayName.substring(1);
      _email = email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('display_name', _displayName);
      await prefs.setString('email', _email);

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginSocial(String provider) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate social login web-page delay

    _isAuthenticated = true;
    if (provider == 'Google') {
      _displayName = 'Gary Oak';
      _email = 'gary.oak@oaklabs.com';
    } else {
      _displayName = 'Ash Ketchum';
      _email = 'ash.ketchum@pallet.com';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_authenticated', true);
    await prefs.setString('display_name', _displayName);
    await prefs.setString('email', _email);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_authenticated');
    await prefs.remove('display_name');
    await prefs.remove('email');
    notifyListeners();
  }
}
