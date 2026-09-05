import 'package:cloud_firestore/cloud_firestore.dart';

/// Coupon stored in Firestore `coupons` collection.
class CouponModel {
  final String id;
  final String code;
  final String description;
  final String discountType; // percentage | fixed
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final int usageLimit;
  final int usedCount;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.usageLimit = 0,
    this.usedCount = 0,
    required this.validFrom,
    required this.validUntil,
    this.isActive = true,
  });

  bool get isPercentage => discountType == 'percentage';

  bool get isValidNow {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil) &&
        (usageLimit == 0 || usedCount < usageLimit);
  }

  factory CouponModel.fromMap(Map<String, dynamic> map, String id) {
    return CouponModel(
      id: id,
      code: map['code'] as String? ?? '',
      description: map['description'] as String? ?? '',
      discountType: map['discountType'] as String? ?? 'percentage',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
      usageLimit: (map['usageLimit'] as num?)?.toInt() ?? 0,
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
      validFrom: _parseTimestamp(map['validFrom']),
      validUntil: _parseTimestamp(map['validUntil']),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CouponModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'isActive': isActive,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
