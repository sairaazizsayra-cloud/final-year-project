import 'package:cloud_firestore/cloud_firestore.dart';

/// Cart line item. Cart documents live under `cart/{userId}/items/{productId}`.
class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final double discount;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;
  final String? customText;
  final String? customImageUrl;
  final DateTime addedAt;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    this.discount = 0,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
    this.customText,
    this.customImageUrl,
    required this.addedAt,
  });

  double get unitPrice {
    if (discount <= 0) return price;
    return price - (price * discount / 100);
  }

  double get lineTotal => unitPrice * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map, String id) {
    return CartItemModel(
      id: id,
      productId: map['productId'] as String? ?? id,
      productName: map['productName'] as String? ?? '',
      productImage: map['productImage'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      selectedColor: map['selectedColor'] as String?,
      selectedSize: map['selectedSize'] as String?,
      customText: map['customText'] as String?,
      customImageUrl: map['customImageUrl'] as String?,
      addedAt: _parseTimestamp(map['addedAt']),
    );
  }

  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CartItemModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'discount': discount,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'customText': customText,
      'customImageUrl': customImageUrl,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {...toMap(), 'addedAt': FieldValue.serverTimestamp()};
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    double? discount,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
    String? customText,
    String? customImageUrl,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      customText: customText ?? this.customText,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Deterministic cart line id so same product+options merge quantity.
  static String lineDocId({
    required String productId,
    String? selectedColor,
    String? selectedSize,
    String? customText,
  }) {
    final raw = [
      productId,
      selectedColor ?? '',
      selectedSize ?? '',
      (customText ?? '').trim().toLowerCase(),
    ].join('__');
    return raw.replaceAll(RegExp(r'[\/\.\[\]#*$]'), '_');
  }

  Map<String, dynamic> toOrderItemMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'discount': discount,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'lineTotal': lineTotal,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'customText': customText,
      'customImageUrl': customImageUrl,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
