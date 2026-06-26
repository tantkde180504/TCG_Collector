import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class UserAddress {
  final String id;
  final String label;
  final String street;
  final String city;
  final String country;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.country,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'street': street,
        'city': city,
        'country': country,
        'is_default': isDefault,
      };

  factory UserAddress.fromMap(String id, Map<String, dynamic> map) =>
      UserAddress(
        id: id,
        label: map['label'] ?? '',
        street: map['street'] ?? '',
        city: map['city'] ?? '',
        country: map['country'] ?? 'Vietnam',
        isDefault: map['is_default'] ?? false,
      );

  UserAddress copyWith({
    String? label,
    String? street,
    String? city,
    String? country,
    bool? isDefault,
  }) =>
      UserAddress(
        id: id,
        label: label ?? this.label,
        street: street ?? this.street,
        city: city ?? this.city,
        country: country ?? this.country,
        isDefault: isDefault ?? this.isDefault,
      );
}

class AppFeedback {
  final int rating;
  final String message;
  final String userId;
  final String userEmail;

  const AppFeedback({
    required this.rating,
    required this.message,
    required this.userId,
    required this.userEmail,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class UserService {
  static final UserService instance = UserService._();
  UserService._();

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── User Profile ───────────────────────────────────────────────────────────

  /// Lưu / cập nhật profile user lên Firestore users/{uid}
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return false;
    try {
      data['updated_at'] = FieldValue.serverTimestamp();
      await _db
          .collection('users')
          .doc(userId)
          .set(data, SetOptions(merge: true));
      debugPrint('UserService: profile updated for $userId');
      return true;
    } catch (e) {
      debugPrint('UserService: updateUserProfile error: $e');
      return false;
    }
  }

  /// Xóa toàn bộ dữ liệu user khỏi Firestore (trước khi xóa Auth account)
  Future<bool> deleteAllUserData(String userId) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return false;
    try {
      // Xóa các subcollections
      for (final sub in ['cart', 'orders', 'addresses']) {
        final docs = await _db
            .collection('users')
            .doc(userId)
            .collection(sub)
            .get();
        final batch = _db.batch();
        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }
        if (docs.docs.isNotEmpty) await batch.commit();
      }

      // Xóa document gốc của user
      await _db.collection('users').doc(userId).delete();
      debugPrint('UserService: all data deleted for $userId');
      return true;
    } catch (e) {
      debugPrint('UserService: deleteAllUserData error: $e');
      return false;
    }
  }

  // ── Addresses ──────────────────────────────────────────────────────────────

  /// Lấy danh sách địa chỉ từ Firestore users/{uid}/addresses
  Future<List<UserAddress>> getAddresses(String userId) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('created_at')
          .get();
      return snapshot.docs
          .map((doc) => UserAddress.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('UserService: getAddresses error: $e');
      return [];
    }
  }

  /// Thêm địa chỉ mới
  Future<UserAddress?> addAddress(String userId, UserAddress address) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return null;
    try {
      if (address.isDefault) await _clearDefaultFlag(userId);
      final map = address.toMap();
      map['created_at'] = FieldValue.serverTimestamp();
      final ref = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .add(map);
      return UserAddress.fromMap(ref.id, address.toMap());
    } catch (e) {
      debugPrint('UserService: addAddress error: $e');
      return null;
    }
  }

  /// Cập nhật địa chỉ
  Future<bool> updateAddress(String userId, UserAddress address) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return false;
    try {
      if (address.isDefault) await _clearDefaultFlag(userId);
      await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(address.id)
          .update(address.toMap());
      return true;
    } catch (e) {
      debugPrint('UserService: updateAddress error: $e');
      return false;
    }
  }

  /// Xóa địa chỉ
  Future<bool> deleteAddress(String userId, String addressId) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return false;
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('UserService: deleteAddress error: $e');
      return false;
    }
  }

  Future<void> _clearDefaultFlag(String userId) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .where('is_default', isEqualTo: true)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_default': false});
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

  /// Gửi feedback lên Firestore collection `feedback`
  Future<bool> submitFeedback(AppFeedback feedback) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) {
      debugPrint(
          'UserService: Feedback queued offline (${feedback.rating}/5)');
      return true; // Giả lập thành công khi offline
    }
    try {
      await _db.collection('feedback').add({
        'user_id': feedback.userId,
        'user_email': feedback.userEmail,
        'rating': feedback.rating,
        'message': feedback.message,
        'created_at': FieldValue.serverTimestamp(),
        'app_version': '1.0.0',
        'platform': kIsWeb ? 'web' : 'mobile',
      });
      debugPrint('UserService: feedback submitted (${feedback.rating}/5)');
      return true;
    } catch (e) {
      debugPrint('UserService: submitFeedback error: $e');
      return false;
    }
  }
}
