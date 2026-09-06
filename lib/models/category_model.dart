import 'package:cloud_firestore/cloud_firestore.dart';

/// Product category stored in Firestore `categories` collection.
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
