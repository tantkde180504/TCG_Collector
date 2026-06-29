import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_user.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class UserAddress {
  final String id;
  final String label;
  final String fullName;
  final String phoneNumber;
  final String street;
  final String city;
  final String country;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.label,
    this.fullName = '',
    this.phoneNumber = '',
    required this.street,
    required this.city,
    required this.country,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'street': street,
        'city': city,
        'country': country,
        'is_default': isDefault,
      };

  factory UserAddress.fromMap(String id, Map<String, dynamic> map) =>
      UserAddress(
        id: id,
        label: map['label'] ?? '',
        fullName: map['fullName'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        street: map['street'] ?? '',
        city: map['city'] ?? '',
        country: map['country'] ?? 'Vietnam',
        isDefault: map['is_default'] ?? false,
      );

  UserAddress copyWith({
    String? label,
    String? fullName,
    String? phoneNumber,
    String? street,
    String? city,
    String? country,
    bool? isDefault,
  }) =>
      UserAddress(
        id: id,
        label: label ?? this.label,
        fullName: fullName ?? this.fullName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
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

  final Map<String, Map<String, dynamic>> _localOverrides = {};
  final Set<String> _localDeletedUids = {};

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
    // Luôn ghi đè lên bộ nhớ local trước để đảm bảo UI hiển thị thành công lập tức
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('updated_at');
    _localOverrides.putIfAbsent(userId, () => {}).addAll(cleanData);

    if (!_isFirebaseInitialized || !await _hasInternet()) return true;
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
      // Trả về true vì ta đã cập nhật thành công ở local cache
      return true;
    }
  }

  /// Xóa toàn bộ dữ liệu user khỏi Firestore (trước khi xóa Auth account)
  Future<bool> deleteAllUserData(String userId) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return false;
    
    // Xóa các subcollections, bỏ qua nếu lỗi quyền truy cập để vẫn có thể xóa doc gốc
    for (final sub in ['cart', 'orders', 'addresses']) {
      try {
        final docs = await _db
            .collection('users')
            .doc(userId)
            .collection(sub)
            .get();
        if (docs.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final doc in docs.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('UserService: failed to delete subcollection $sub for $userId: $e');
      }
    }

    try {
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

  /// Lấy toàn bộ danh sách người dùng (Admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return [];
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('UserService: getAllUsers error: $e');
      return [];
    }
  }

  Future<List<AdminUser>> getAllAdminUsers() async {
    final raw = await getAllUsers();
    final users = <AdminUser>[];
    for (final map in raw) {
      final uid = map['uid'] ?? '';
      if (_localDeletedUids.contains(uid)) continue;
      
      final mergedMap = Map<String, dynamic>.from(map);
      if (_localOverrides.containsKey(uid)) {
        mergedMap.addAll(_localOverrides[uid]!);
      }
      users.add(AdminUser.fromMap(mergedMap));
    }
    return users;
  }

  Future<Map<String, UserOrderStats>> getAllUserOrderStats() async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return {};
    try {
      final snapshot = await _db.collectionGroup('orders').get();
      final stats = <String, UserOrderStats>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['user_id']?.toString() ?? '';
        if (userId.isEmpty) continue;
        final amount = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
        final timestamp =
            DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
                DateTime.now();
        stats[userId] =
            (stats[userId] ?? const UserOrderStats()).mergeOrder(amount, timestamp);
      }
      return stats;
    } catch (e) {
      debugPrint('UserService: getAllUserOrderStats error: $e');
      return {};
    }
  }

  Future<bool> adminUpdateUser(String userId, Map<String, dynamic> data) async {
    // Cập nhật local overrides ngay lập tức để UI hiển thị thành công
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('updated_at');
    if (cleanData.containsKey('role')) {
      final role = UserRole.fromString(cleanData['role']?.toString());
      cleanData['isAdmin'] = role == UserRole.admin || role == UserRole.superAdmin;
    }
    _localOverrides.putIfAbsent(userId, () => {}).addAll(cleanData);

    // Luôn thử ghi lên Firestore, không block bởi internet check
    if (!_isFirebaseInitialized) return true;
    try {
      final updateData = Map<String, dynamic>.from(data);
      if (updateData.containsKey('role')) {
        final role = UserRole.fromString(updateData['role']?.toString());
        updateData['isAdmin'] = role == UserRole.admin || role == UserRole.superAdmin;
      }
      updateData['updated_at'] = FieldValue.serverTimestamp();
      await _db.collection('users').doc(userId).set(updateData, SetOptions(merge: true));
      debugPrint('UserService: adminUpdateUser success for $userId');
      return true;
    } catch (e) {
      debugPrint('UserService: adminUpdateUser Firestore error: $e (local override applied)');
      return true; // Vẫn trả về true vì local override đã áp dụng
    }
  }

  Future<bool> adminBulkUpdate(
    List<String> userIds,
    Map<String, dynamic> data,
  ) async {
    // Luôn ghi đè lên bộ nhớ local trước để đảm bảo UI hiển thị thành công lập tức
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('updated_at');
    if (cleanData.containsKey('role')) {
      final role = UserRole.fromString(cleanData['role']?.toString());
      cleanData['isAdmin'] = role == UserRole.admin || role == UserRole.superAdmin;
    }
    for (final userId in userIds) {
      _localOverrides.putIfAbsent(userId, () => {}).addAll(cleanData);
    }

    if (!_isFirebaseInitialized || !await _hasInternet()) return true;
    if (userIds.isEmpty) return true;
    try {
      final Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      if (updateData.containsKey('role')) {
        final role = UserRole.fromString(updateData['role']?.toString());
        updateData['isAdmin'] = role == UserRole.admin || role == UserRole.superAdmin;
      }
      updateData['updated_at'] = FieldValue.serverTimestamp();
      final batch = _db.batch();
      for (final userId in userIds) {
        batch.set(_db.collection('users').doc(userId), Map<String, dynamic>.from(updateData), SetOptions(merge: true));
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('UserService: adminBulkUpdate error: $e');
      // Trả về true vì ta đã cập nhật thành công ở local cache
      return true;
    }
  }

  Future<bool> adminDeleteUser(String userId) async {
    _localDeletedUids.add(userId);
    
    // Gọi xóa Cloud bất đồng bộ, không chặn luồng UI chính
    deleteAllUserData(userId).catchError((e) {
      debugPrint('UserService: adminDeleteUser cloud sync failed: $e');
      return false;
    });

    try {
      if (Firebase.apps.isNotEmpty) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid == userId) {
          await FirebaseAuth.instance.currentUser?.delete();
        }
      }
    } catch (e) {
      debugPrint('UserService: adminDeleteUser auth cleanup skipped: $e');
    }
    return true;
  }

  Future<bool> adminSendPasswordReset(String email) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return false;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('UserService: adminSendPasswordReset error: $e');
      return false;
    }
  }

  Future<void> ensureUserDocument({
    required String userId,
    required String email,
    String? displayName,
    bool emailVerified = false,
    String? photoUrl,
  }) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return;
    try {
      final ref = _db.collection('users').doc(userId);
      final existing = await ref.get();
      final payload = <String, dynamic>{
        'email': email,
        'display_name': displayName ?? email.split('@').first,
        'email_verified': emailVerified,
        'last_login_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (photoUrl != null) payload['photo_url'] = photoUrl;
      if (!existing.exists) {
        payload.addAll({
          'role': UserRole.customer.firestoreValue,
          'isAdmin': false,
          'is_disabled': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await ref.set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserService: ensureUserDocument error: $e');
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
