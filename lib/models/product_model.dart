import 'package:cloud_firestore/cloud_firestore.dart';

/// Product stored in Firestore `products` collection.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String? categoryName;
  final double price;
  final double discount;
  final int stock;
  final List<String> images;
  final String? material;
  final String? size;
  final List<String> colors;
  final bool isCustomizable;
  final double rating;
  final int totalReviews;
  final bool isFeatured;
  final bool isBestSeller;
  final bool isNewArrival;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    this.categoryName,
    required this.price,
    this.discount = 0,
    required this.stock,
    this.images = const [],
    this.material,
    this.size,
    this.colors = const [],
    this.isCustomizable = false,
    this.rating = 0,
    this.totalReviews = 0,
    this.isFeatured = false,
    this.isBestSeller = false,
    this.isNewArrival = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  double get discountedPrice {
    if (discount <= 0) return price;
    return price - (price * discount / 100);
  }

  bool get hasDiscount => discount > 0;
  bool get inStock => stock > 0;
  String? get primaryImage => images.isNotEmpty ? images.first : null;

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      images: List<String>.from(map['images'] as List? ?? const []),
      material: map['material'] as String?,
      size: map['size'] as String?,
      colors: List<String>.from(map['colors'] as List? ?? const []),
      isCustomizable: map['isCustomizable'] == true,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      isFeatured: map['isFeatured'] == true,
      isBestSeller: map['isBestSeller'] == true,
      isNewArrival: map['isNewArrival'] == true,
      isActive: map['isActive'] != false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? _parseTimestamp(map['updatedAt'])
          : null,
    );
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'price': price,
      'discount': discount,
      'stock': stock,
      'images': images,
      'material': material,
      'size': size,
      'colors': colors,
      'isCustomizable': isCustomizable,
      'rating': rating,
      'totalReviews': totalReviews,
      'isFeatured': isFeatured,
      'isBestSeller': isBestSeller,
      'isNewArrival': isNewArrival,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      ...toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
