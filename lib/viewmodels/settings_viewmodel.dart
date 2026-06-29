import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kNotifications = 'settings_notifications';
const _kSounds = 'settings_sounds';
const _kHaptics = 'settings_haptics';
const _kCurrency = 'settings_currency';
const _kLanguage = 'settings_language';

class SettingsViewModel extends ChangeNotifier {
  bool _notifications = true;
  bool _sounds = true;
  bool _haptics = true;
  String _currency = 'USD';
  String _language = 'English';
  bool _isLoaded = false;

  bool get notifications => _notifications;
  bool get sounds => _sounds;
  bool get haptics => _haptics;
  String get currency => _currency;
  String get language => _language;
  bool get isLoaded => _isLoaded;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notifications = prefs.getBool(_kNotifications) ?? true;
    _sounds = prefs.getBool(_kSounds) ?? true;
    _haptics = prefs.getBool(_kHaptics) ?? true;
    _currency = prefs.getString(_kCurrency) ?? 'USD';
    _language = prefs.getString(_kLanguage) ?? 'English';
    _isLoaded = true;
    notifyListeners();
  }

  void setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }

  void setSounds(bool value) async {
    _sounds = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSounds, value);
  }

  void setHaptics(bool value) async {
    _haptics = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptics, value);
  }

  void setCurrency(String value) async {
    _currency = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, value);
  }

  void setLanguage(String value) async {
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
  }

  void triggerHaptic() {
    if (_haptics) {
      HapticFeedback.lightImpact();
    }
  }

  String formatPrice(double priceInUsd, {bool isExact = false}) {
    switch (_currency) {
      case 'VND':
        final vnd = priceInUsd * 25000;
        // e.g. 250,000 đ
        final formatted = vnd.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
        return '$formatted ₫';
      case 'EUR':
        final eur = priceInUsd * 0.93;
        return '€${eur.toStringAsFixed(isExact ? 2 : 0)}';
      case 'USD':
      default:
        return '\$${priceInUsd.toStringAsFixed(isExact ? 2 : 0)}';
    }
  }
}
