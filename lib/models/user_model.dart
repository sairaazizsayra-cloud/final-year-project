import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keychain_shop/constants/app_constants.dart';

/// App user profile stored in Firestore `users` collection.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.role = AppConstants.roleCustomer,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.fcmToken,
  });

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isRider => role == AppConstants.roleRider;
  bool get isCustomer => role == AppConstants.roleCustomer;

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      profileImage: map['profileImage'] as String?,
      role: map['role'] as String? ?? AppConstants.roleCustomer,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? _parseTimestamp(map['updatedAt'])
          : null,
      isActive: map['isActive'] as bool? ?? true,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'fcmToken': fcmToken,
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
