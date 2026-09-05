import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keychain_shop/constants/app_constants.dart';

/// Order stored in Firestore `orders` collection.
class OrderModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double deliveryCharges;
  final double discount;
  final double totalAmount;
  final String? couponCode;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final Map<String, dynamic> deliveryAddress;
  final String? deliveryId;
  final String? riderId;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDeliveryDate;
  final DateTime? deliveredAt;
  final List<Map<String, dynamic>> statusHistory;

  const OrderModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    required this.items,
    required this.subtotal,
    this.deliveryCharges = 0,
    this.discount = 0,
    required this.totalAmount,
    this.couponCode,
    this.paymentMethod = AppConstants.paymentCod,
    this.paymentStatus = AppConstants.paymentPending,
    this.orderStatus = AppConstants.orderPending,
    required this.deliveryAddress,
    this.deliveryId,
    this.riderId,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDeliveryDate,
    this.deliveredAt,
    this.statusHistory = const [],
  });

  bool get isOngoing =>
      orderStatus != AppConstants.orderDelivered &&
      orderStatus != AppConstants.orderCancelled;

  bool get isCompleted => orderStatus == AppConstants.orderDelivered;
  bool get isCancelled => orderStatus == AppConstants.orderCancelled;

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String?,
      userEmail: map['userEmail'] as String?,
      userPhone: map['userPhone'] as String?,
      items: List<Map<String, dynamic>>.from(
        (map['items'] as List? ?? const []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      ),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryCharges: (map['deliveryCharges'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      couponCode: map['couponCode'] as String?,
      paymentMethod:
          map['paymentMethod'] as String? ?? AppConstants.paymentCod,
      paymentStatus:
          map['paymentStatus'] as String? ?? AppConstants.paymentPending,
      orderStatus: map['orderStatus'] as String? ?? AppConstants.orderPending,
      deliveryAddress: Map<String, dynamic>.from(
        map['deliveryAddress'] as Map? ?? const {},
      ),
      deliveryId: map['deliveryId'] as String?,
      riderId: map['riderId'] as String?,
      notes: map['notes'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? _parseTimestamp(map['updatedAt'])
          : null,
      estimatedDeliveryDate: map['estimatedDeliveryDate'] != null
          ? _parseTimestamp(map['estimatedDeliveryDate'])
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? _parseTimestamp(map['deliveredAt'])
          : null,
      statusHistory: List<Map<String, dynamic>>.from(
        (map['statusHistory'] as List? ?? const []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      ),
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'items': items,
      'subtotal': subtotal,
      'deliveryCharges': deliveryCharges,
      'discount': discount,
      'totalAmount': totalAmount,
      'couponCode': couponCode,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'deliveryAddress': deliveryAddress,
      'deliveryId': deliveryId,
      'riderId': riderId,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'estimatedDeliveryDate': estimatedDeliveryDate != null
          ? Timestamp.fromDate(estimatedDeliveryDate!)
          : null,
      'deliveredAt': null,
      'statusHistory': [
        {
          'status': orderStatus,
          'timestamp': Timestamp.now(),
          'note': 'Order placed',
        },
      ],
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
