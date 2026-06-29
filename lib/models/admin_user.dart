import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  customer,
  staff,
  trainer,
  moderator,
  admin,
  superAdmin;

  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.staff:
        return 'Staff';
      case UserRole.trainer:
        return 'Trainer';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  String get firestoreValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      default:
        return name;
    }
  }

  static UserRole fromString(String? value, {bool isAdmin = false}) {
    switch (value) {
      case 'staff':
        return UserRole.staff;
      case 'trainer':
        return UserRole.trainer;
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      case 'customer':
        return UserRole.customer;
      default:
        return isAdmin ? UserRole.admin : UserRole.customer;
    }
  }
}

class UserOrderStats {
  final int orderCount;
  final double totalSpent;
  final DateTime? lastPurchaseAt;

  const UserOrderStats({
    this.orderCount = 0,
    this.totalSpent = 0,
    this.lastPurchaseAt,
  });

  UserOrderStats mergeOrder(double amount, DateTime timestamp) {
    final newerLastPurchase = lastPurchaseAt == null || timestamp.isAfter(lastPurchaseAt!)
        ? timestamp
        : lastPurchaseAt;
    return UserOrderStats(
      orderCount: orderCount + 1,
      totalSpent: totalSpent + amount,
      lastPurchaseAt: newerLastPurchase,
    );
  }
}

class AdminUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? address;
  final UserRole role;
  final bool isDisabled;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? lastPurchaseAt;
  final DateTime? updatedAt;

  const AdminUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.phone,
    this.address,
    this.role = UserRole.customer,
    this.isDisabled = false,
    this.emailVerified = false,
    this.createdAt,
    this.lastLoginAt,
    this.lastPurchaseAt,
    this.updatedAt,
  });

  bool get isAdminRole =>
      role == UserRole.admin ||
      role == UserRole.superAdmin;

  bool get isStaffRole => role == UserRole.staff;

  bool get isCustomerRole =>
      role == UserRole.customer ||
      role == UserRole.trainer ||
      role == UserRole.moderator;

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    final isAdmin = map['isAdmin'] == true;
    return AdminUser(
      uid: map['uid'] ?? '',
      displayName: map['display_name'] ?? 'Trainer',
      email: map['email'] ?? '',
      photoUrl: map['photo_url'],
      phone: map['phone'],
      address: map['address'],
      role: UserRole.fromString(map['role'], isAdmin: isAdmin),
      isDisabled: map['is_disabled'] == true,
      emailVerified: map['email_verified'] == true,
      createdAt: _parseDate(map['created_at']),
      lastLoginAt: _parseDate(map['last_login_at']),
      lastPurchaseAt: _parseDate(map['last_purchase_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toUpdateMap() => {
        'display_name': displayName,
        'email': email,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        'role': role.firestoreValue,
        'isAdmin': isAdminRole,
        'is_disabled': isDisabled,
        'email_verified': emailVerified,
      };

  AdminUser copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? phone,
    String? address,
    UserRole? role,
    bool? isDisabled,
    bool? emailVerified,
  }) =>
      AdminUser(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        role: role ?? this.role,
        isDisabled: isDisabled ?? this.isDisabled,
        emailVerified: emailVerified ?? this.emailVerified,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt,
        lastPurchaseAt: lastPurchaseAt,
        updatedAt: updatedAt,
      );

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

enum UserSortOption {
  nameAsc,
  newest,
  oldest,
  lastLogin,
}

enum UserRoleFilter {
  all,
  admin,
  staff,
  customer,
}

enum UserStatusFilter {
  all,
  active,
  disabled,
}

enum UserEmailFilter {
  all,
  verified,
  unverified,
}
