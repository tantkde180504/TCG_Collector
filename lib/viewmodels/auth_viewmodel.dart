import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

enum LoginResult { success, verificationRequired, failed }

class AuthViewModel extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isDeviceVerified = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  bool get isAuthenticated => _auth != null ? (_user != null && _isDeviceVerified) : _mockAuthenticated;
  
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
    final prefs = await SharedPreferences.getInstance();
    
    if (auth != null) {
      auth.authStateChanges().listen((User? user) async {
        _user = user;
        if (user != null) {
          _isDeviceVerified = prefs.getBool('device_verified_${user.email}') ?? false;
          if (_isDeviceVerified) {
            await DatabaseService.instance.syncFromCloudOnLogin(user.uid);
          }
        }
        _isLoading = false;
        notifyListeners();
      });
    } else {
      // Mock khởi tạo từ SharedPreferences cho môi trường test
      _mockAuthenticated = prefs.getBool('is_authenticated') ?? false;
      _mockDisplayName = prefs.getString('display_name') ?? 'Trainer Red';
      _mockEmail = prefs.getString('email') ?? 'trainer.red@kanto.com';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    final auth = _auth;
    if (auth != null) {
      try {
        final userCred = await auth.createUserWithEmailAndPassword(email: email, password: password);
        await userCred.user?.updateDisplayName(name);
        
        final currentUser = auth.currentUser;
        if (currentUser != null) {
          // Sync data to Firestore on register
          await DatabaseService.instance.syncFromCloudOnLogin(currentUser.uid);
          
          // Trust device automatically upon registration
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('device_verified_$email', true);
          _isDeviceVerified = true;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Register error: $e');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } else {
      // Mock for testing
      await Future.delayed(const Duration(milliseconds: 500));
      _mockAuthenticated = true;
      _mockDisplayName = name;
      _mockEmail = email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('display_name', _mockDisplayName);
      await prefs.setString('email', _mockEmail);
      await prefs.setBool('device_verified_$email', true);
      _isDeviceVerified = true;

      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<LoginResult> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final auth = _auth;
    final prefs = await SharedPreferences.getInstance();

    if (auth != null) {
      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        
        // Cập nhật state local
        final isVerified = prefs.getBool('device_verified_$email') ?? false;
        
        if (isVerified) {
          _isDeviceVerified = true;
          final currentUser = auth.currentUser;
          if (currentUser != null) {
            await DatabaseService.instance.syncFromCloudOnLogin(currentUser.uid);
          }
          _isLoading = false;
          notifyListeners();
          return LoginResult.success;
        } else {
          // Device is not verified, require verification
          _isDeviceVerified = false;
          final code = (100000 + Random().nextInt(900000)).toString();
          
          await FirebaseFirestore.instance.collection('verification_codes').doc(email).set({
            'code': code,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          debugPrint('Generated Verification Code for $email: $code');
          
          _isLoading = false;
          notifyListeners();
          return LoginResult.verificationRequired;
        }
      } catch (e) {
        debugPrint('Login error: $e');
      }
    } else {
      // Logic giả lập khi chạy test
      await Future.delayed(const Duration(milliseconds: 500));
      if (email.contains('@') && password.length >= 6) {
        final isVerified = prefs.getBool('device_verified_$email') ?? false;
        
        if (isVerified) {
          _mockAuthenticated = true;
          _mockDisplayName = email.split('@')[0];
          _mockEmail = email;
          _isDeviceVerified = true;

          await prefs.setBool('is_authenticated', true);
          await prefs.setString('display_name', _mockDisplayName);
          await prefs.setString('email', _mockEmail);

          _isLoading = false;
          notifyListeners();
          return LoginResult.success;
        } else {
          _isDeviceVerified = false;
          final code = (100000 + Random().nextInt(900000)).toString();
          await prefs.setString('mock_verification_code_$email', code);
          debugPrint('Mock Verification Code for $email: $code');
          
          _isLoading = false;
          notifyListeners();
          return LoginResult.verificationRequired;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
    return LoginResult.failed;
  }
  
  Future<bool> verifyDeviceCode(String email, String password, String code) async {
    _isLoading = true;
    notifyListeners();
    
    final auth = _auth;
    final prefs = await SharedPreferences.getInstance();
    
    if (auth != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('verification_codes').doc(email).get();
        if (doc.exists && doc.data()!['code'] == code) {
          // Xóa code sau khi dùng
          await doc.reference.delete();
          
          await prefs.setBool('device_verified_$email', true);
          _isDeviceVerified = true;
          
          final currentUser = auth.currentUser;
          if (currentUser != null) {
            await DatabaseService.instance.syncFromCloudOnLogin(currentUser.uid);
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('Verification error: $e');
      }
    } else {
      final mockCode = prefs.getString('mock_verification_code_$email');
      if (mockCode == code) {
        await prefs.remove('mock_verification_code_$email');
        await prefs.setBool('device_verified_$email', true);
        
        _mockAuthenticated = true;
        _mockDisplayName = email.split('@')[0];
        _mockEmail = email;
        _isDeviceVerified = true;

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

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    final auth = _auth;
    if (auth != null) {
      try {
        await auth.sendPasswordResetEmail(email: email);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Send password reset email error: $e');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } else {
      // Giả lập thành công khi test offline
      await Future.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> loginSocial(String provider) async {
    _isLoading = true;
    notifyListeners();

    final auth = _auth;
    final prefs = await SharedPreferences.getInstance();

    if (auth != null) {
      if (provider == 'Google') {
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            _isLoading = false;
            notifyListeners();
            return false;
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCred = await auth.signInWithCredential(credential);
          final currentUser = userCred.user;
          
          // Google Login is considered automatically verified on new devices
          // due to Google's built-in 2SV (Choose correct number)
          if (currentUser != null) {
            await prefs.setBool('device_verified_${currentUser.email}', true);
            _isDeviceVerified = true;
            await DatabaseService.instance.syncFromCloudOnLogin(currentUser.uid);
          }
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          debugPrint('Lỗi đăng nhập Google thực tế: $e');
        }
      } else {
        // Mock Nintendo
        final mockEmail = 'ash.ketchum@pallet.com';
        final mockPassword = 'socialpassword123';
        final mockName = 'Ash Ketchum';

        try {
          UserCredential userCred;
          try {
            userCred = await auth.signInWithEmailAndPassword(email: mockEmail, password: mockPassword);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
              userCred = await auth.createUserWithEmailAndPassword(email: mockEmail, password: mockPassword);
              await userCred.user?.updateDisplayName(mockName);
            } else {
              rethrow;
            }
          }
          final currentUser = userCred.user;
          if (currentUser != null) {
            await prefs.setBool('device_verified_${currentUser.email}', true);
            _isDeviceVerified = true;
            await DatabaseService.instance.syncFromCloudOnLogin(currentUser.uid);
          }
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          debugPrint('Social login simulation error: $e');
        }
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
      _mockAuthenticated = true;
      if (provider == 'Google') {
        _mockDisplayName = 'Gary Oak';
        _mockEmail = 'gary.oak@oaklabs.com';
      } else {
        _mockDisplayName = 'Ash Ketchum';
        _mockEmail = 'ash.ketchum@pallet.com';
      }

      await prefs.setBool('is_authenticated', true);
      await prefs.setString('display_name', _mockDisplayName);
      await prefs.setString('email', _mockEmail);
      await prefs.setBool('device_verified_$_mockEmail', true);
      _isDeviceVerified = true;

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
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    } else {
      _mockAuthenticated = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_authenticated');
      await prefs.remove('display_name');
      await prefs.remove('email');
    }
    _isDeviceVerified = false;
    notifyListeners();
  }
}
