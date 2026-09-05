import 'package:cloud_firestore/cloud_firestore.dart';

/// Favorite entry in Firestore `favorites` collection.
class FavoriteModel {
  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory FavoriteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FavoriteModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static String docIdFor(String userId, String productId) =>
      '${userId}_$productId';

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
