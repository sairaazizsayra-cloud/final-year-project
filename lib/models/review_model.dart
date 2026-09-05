import 'package:cloud_firestore/cloud_firestore.dart';

/// Product review stored in Firestore `reviews` collection.
class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String? userName;
  final String? userImage;
  final String? orderId;
  final double rating;
  final String comment;
  final List<String> images;
  final bool isApproved;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    this.userName,
    this.userImage,
    this.orderId,
    required this.rating,
    required this.comment,
    this.images = const [],
    this.isApproved = false,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      productId: map['productId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String?,
      userImage: map['userImage'] as String?,
      orderId: map['orderId'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      comment: map['comment'] as String? ?? '',
      images: List<String>.from(map['images'] as List? ?? const []),
      isApproved: map['isApproved'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReviewModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'images': images,
      'isApproved': isApproved,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
