import 'package:cloud_firestore/cloud_firestore.dart';

/// Delivery address stored under `addresses/{addressId}` (user-owned).
class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String houseStreet;
  final String area;
  final String city;
  final String postalCode;
  final bool isDefault;
  final DateTime createdAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.houseStreet,
    required this.area,
    required this.city,
    required this.postalCode,
    this.isDefault = false,
    required this.createdAt,
  });

  String get formattedAddress => '$houseStreet, $area, $city, $postalCode';

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      houseStreet: map['houseStreet'] as String? ?? '',
      area: map['area'] as String? ?? '',
      city: map['city'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      isDefault: map['isDefault'] == true,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory AddressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AddressModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'houseStreet': houseStreet,
      'area': area,
      'city': city,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {...toMap(), 'createdAt': FieldValue.serverTimestamp()};
  }

  Map<String, dynamic> toOrderSnapshot() {
    return {
      'fullName': fullName,
      'phone': phone,
      'houseStreet': houseStreet,
      'area': area,
      'city': city,
      'postalCode': postalCode,
      'formattedAddress': formattedAddress,
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? houseStreet,
    String? area,
    String? city,
    String? postalCode,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      houseStreet: houseStreet ?? this.houseStreet,
      area: area ?? this.area,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
