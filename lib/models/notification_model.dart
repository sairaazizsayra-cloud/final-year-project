import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification stored in Firestore `notifications` collection.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? orderId;
  final String? productId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.productId,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      orderId: map['orderId'] as String?,
      productId: map['productId'] as String?,
      data: map['data'] != null
          ? Map<String, dynamic>.from(map['data'] as Map)
          : null,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'productId': productId,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
