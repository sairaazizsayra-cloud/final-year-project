import 'package:cloud_firestore/cloud_firestore.dart';

/// Delivery assignment stored in Firestore `deliveries` collection.
class DeliveryModel {
  final String id;
  final String orderId;
  final String userId;
  final String? riderId;
  final String? riderName;
  final Map<String, dynamic> deliveryAddress;
  final String status;
  final String? notes;
  final DateTime assignedAt;
  final DateTime? deliveredAt;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.userId,
    this.riderId,
    this.riderName,
    required this.deliveryAddress,
    required this.status,
    this.notes,
    required this.assignedAt,
    this.deliveredAt,
  });

  factory DeliveryModel.fromMap(Map<String, dynamic> map, String id) {
    return DeliveryModel(
      id: id,
      orderId: map['orderId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      riderId: map['riderId'] as String?,
      riderName: map['riderName'] as String?,
      deliveryAddress: Map<String, dynamic>.from(
        map['deliveryAddress'] as Map? ?? const {},
      ),
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      assignedAt: _parseTimestamp(map['assignedAt']),
      deliveredAt: map['deliveredAt'] != null
          ? _parseTimestamp(map['deliveredAt'])
          : null,
    );
  }

  factory DeliveryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DeliveryModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'riderId': riderId,
      'riderName': riderName,
      'deliveryAddress': deliveryAddress,
      'status': status,
      'notes': notes,
      'assignedAt': FieldValue.serverTimestamp(),
      'deliveredAt': null,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
