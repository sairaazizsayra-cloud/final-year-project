import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/address_model.dart';
import 'package:keychain_shop/models/cart_item_model.dart';
import 'package:keychain_shop/models/category_model.dart';
import 'package:keychain_shop/models/coupon_model.dart';
import 'package:keychain_shop/models/delivery_model.dart';
import 'package:keychain_shop/models/favorite_model.dart';
import 'package:keychain_shop/models/notification_model.dart';
import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/models/review_model.dart';
import 'package:keychain_shop/models/user_model.dart';

/// Central Firestore data access for Phase 1 foundations.
/// Product/cart/order CRUD will expand in later phases.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _dbOverride = firestore;

  final FirebaseFirestore? _dbOverride;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _db.collection(name);

  // ── Users ──────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Categories ─────────────────────────────────────────

  Stream<List<CategoryModel>> watchActiveCategories() {
    return _db
        .collection(AppConstants.categoriesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(CategoryModel.fromFirestore).toList(),
        );
  }

  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final snap = await _db
          .collection(AppConstants.categoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      return snap.docs.map(CategoryModel.fromFirestore).toList();
    } catch (e) {
      // Index may still be building — fall back without orderBy.
      logError('getActiveCategories ordered', e);
      final snap = await _db
          .collection(AppConstants.categoriesCollection)
          .where('isActive', isEqualTo: true)
          .get();
      final list = snap.docs.map(CategoryModel.fromFirestore).toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    }
  }

  // ── Products ───────────────────────────────────────────

  Stream<List<ProductModel>> watchActiveProducts({int limit = 20}) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ProductModel.fromFirestore).toList());
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    } catch (e) {
      logError('getFeaturedProducts', e);
      return [];
    }
  }

  Future<List<ProductModel>> getNewArrivals({int limit = 10}) async {
    try {
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('isNewArrival', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    } catch (e) {
      logError('getNewArrivals ordered', e);
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('isNewArrival', isEqualTo: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    }
  }

  Future<List<ProductModel>> getBestSellers({int limit = 10}) async {
    try {
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('isBestSeller', isEqualTo: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    } catch (e) {
      logError('getBestSellers', e);
      return [];
    }
  }

  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .limit(limit)
        .get();
    return snap.docs.map(ProductModel.fromFirestore).toList();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    // Prefer nameLower prefix query; fall back to client filter if field missing.
    try {
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('nameLower', isGreaterThanOrEqualTo: normalized)
          .where('nameLower', isLessThanOrEqualTo: '$normalized\uf8ff')
          .limit(30)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map(ProductModel.fromFirestore).toList();
      }
    } catch (e) {
      logError('searchProducts prefix', e);
    }

    final all = await getActiveProducts(limit: 100);
    return all
        .where(
          (p) =>
              p.name.toLowerCase().contains(normalized) ||
              p.description.toLowerCase().contains(normalized),
        )
        .take(30)
        .toList();
  }

  Future<List<ProductModel>> getActiveProducts({int limit = 100}) async {
    try {
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    } catch (e) {
      logError('getActiveProducts ordered', e);
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    }
  }

  Future<List<ProductModel>> getDiscountedProducts({int limit = 30}) async {
    final products = await getActiveProducts(limit: 80);
    final discounted = products.where((p) => p.hasDiscount).toList()
      ..sort((a, b) => b.discount.compareTo(a.discount));
    return discounted.take(limit).toList();
  }

  // ── Favorites ──────────────────────────────────────────

  Future<List<FavoriteModel>> getUserFavorites(String userId) async {
    final snap = await _db
        .collection(AppConstants.favoritesCollection)
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.map(FavoriteModel.fromFirestore).toList();
  }

  Stream<List<FavoriteModel>> watchUserFavorites(String userId) {
    return _db
        .collection(AppConstants.favoritesCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(FavoriteModel.fromFirestore).toList());
  }

  Future<bool> isFavorite({
    required String userId,
    required String productId,
  }) async {
    final doc = await _db
        .collection(AppConstants.favoritesCollection)
        .doc(FavoriteModel.docIdFor(userId, productId))
        .get();
    return doc.exists;
  }

  Future<void> addFavorite({
    required String userId,
    required String productId,
  }) async {
    final id = FavoriteModel.docIdFor(userId, productId);
    await _db.collection(AppConstants.favoritesCollection).doc(id).set(
          FavoriteModel(
            id: id,
            userId: userId,
            productId: productId,
            createdAt: DateTime.now(),
          ).toCreateMap(),
        );
  }

  Future<void> removeFavorite({
    required String userId,
    required String productId,
  }) async {
    await _db
        .collection(AppConstants.favoritesCollection)
        .doc(FavoriteModel.docIdFor(userId, productId))
        .delete();
  }

  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final unique = ids.toSet().toList();
    final products = <ProductModel>[];

    // Firestore whereIn supports up to 30 values per query.
    for (var i = 0; i < unique.length; i += 30) {
      final chunk = unique.sublist(
        i,
        i + 30 > unique.length ? unique.length : i + 30,
      );
      final snap = await _db
          .collection(AppConstants.productsCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      products.addAll(snap.docs.map(ProductModel.fromFirestore));
    }
    return products;
  }

  // ── Reviews (read for product details) ─────────────────

  Future<List<ReviewModel>> getProductReviews(
    String productId, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection(AppConstants.reviewsCollection)
        .where('productId', isEqualTo: productId)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(ReviewModel.fromFirestore).toList();
  }

  Future<String> createReview({
    required String productId,
    required String userId,
    required String userName,
    required String? orderId,
    required double rating,
    required String comment,
  }) async {
    final review = ReviewModel(
      id: '',
      productId: productId,
      userId: userId,
      userName: userName,
      orderId: orderId,
      rating: rating,
      comment: comment.trim(),
      isApproved: false,
      createdAt: DateTime.now(),
    );
    final doc = await _db
        .collection(AppConstants.reviewsCollection)
        .add(review.toCreateMap());
    debugPrint('[FirestoreService] Review created: ${doc.id}');
    return doc.id;
  }

  Future<bool> hasUserReviewedProduct({
    required String userId,
    required String productId,
    String? orderId,
  }) async {
    final snap = await _db
        .collection(AppConstants.reviewsCollection)
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .limit(20)
        .get();
    if (snap.docs.isEmpty) return false;
    if (orderId == null) return true;
    return snap.docs.any((doc) => doc.data()['orderId'] == orderId);
  }

  // ── Cart ───────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _cartItems(String userId) => _db
      .collection(AppConstants.cartCollection)
      .doc(userId)
      .collection('items');

  Stream<List<CartItemModel>> watchCart(String userId) {
    return _cartItems(userId).snapshots().map(
          (snap) => snap.docs.map(CartItemModel.fromFirestore).toList(),
        );
  }

  Future<List<CartItemModel>> getCartItems(String userId) async {
    final snap = await _cartItems(userId).get();
    return snap.docs.map(CartItemModel.fromFirestore).toList();
  }

  Future<void> addToCart({
    required String userId,
    required CartItemModel item,
  }) async {
    final ref = _cartItems(userId).doc(item.id);
    final existing = await ref.get();
    if (existing.exists) {
      final current = CartItemModel.fromFirestore(existing);
      final nextQty = (current.quantity + item.quantity)
          .clamp(1, AppConstants.maxCartQuantity);
      await ref.update({
        'quantity': nextQty,
        'price': item.price,
        'discount': item.discount,
        'productName': item.productName,
        'productImage': item.productImage,
      });
    } else {
      await ref.set(item.toCreateMap());
    }
  }

  Future<void> updateCartQuantity({
    required String userId,
    required String itemId,
    required int quantity,
  }) async {
    if (quantity < 1) {
      await removeFromCart(userId: userId, itemId: itemId);
      return;
    }
    final qty = quantity.clamp(1, AppConstants.maxCartQuantity);
    await _cartItems(userId).doc(itemId).update({'quantity': qty});
  }

  Future<void> removeFromCart({
    required String userId,
    required String itemId,
  }) async {
    await _cartItems(userId).doc(itemId).delete();
  }

  Future<void> clearCart(String userId) async {
    final snap = await _cartItems(userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Addresses ──────────────────────────────────────────

  Future<List<AddressModel>> getUserAddresses(String userId) async {
    final snap = await _db
        .collection(AppConstants.addressesCollection)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snap.docs.map(AddressModel.fromFirestore).toList();
    list.sort((a, b) {
      if (a.isDefault == b.isDefault) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return a.isDefault ? -1 : 1;
    });
    return list;
  }

  Stream<List<AddressModel>> watchUserAddresses(String userId) {
    return _db
        .collection(AppConstants.addressesCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AddressModel.fromFirestore).toList();
      list.sort((a, b) {
        if (a.isDefault == b.isDefault) {
          return b.createdAt.compareTo(a.createdAt);
        }
        return a.isDefault ? -1 : 1;
      });
      return list;
    });
  }

  Future<String> saveAddress(AddressModel address) async {
    final col = _db.collection(AppConstants.addressesCollection);

    if (address.isDefault) {
      await _clearDefaultAddresses(address.userId);
    }

    if (address.id.isEmpty) {
      final doc = await col.add(address.toCreateMap());
      return doc.id;
    }

    final data = address.toMap()..remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await col.doc(address.id).update(data);
    return address.id;
  }

  Future<void> deleteAddress(String addressId) async {
    await _db
        .collection(AppConstants.addressesCollection)
        .doc(addressId)
        .delete();
  }

  Future<void> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    await _clearDefaultAddresses(userId);
    await _db
        .collection(AppConstants.addressesCollection)
        .doc(addressId)
        .update({'isDefault': true});
  }

  Future<void> _clearDefaultAddresses(String userId) async {
    final snap = await _db
        .collection(AppConstants.addressesCollection)
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }

  // ── Orders ─────────────────────────────────────────────

  Future<String> createOrder(OrderModel order) async {
    final doc = _db.collection(AppConstants.ordersCollection).doc();
    await doc.set(order.toCreateMap());
    debugPrint('[FirestoreService] Order created: ${doc.id}');
    return doc.id;
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc =
        await _db.collection(AppConstants.ordersCollection).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }

  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    final snap = await _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(OrderModel.fromFirestore).toList();
  }

  /// Customer may cancel only while pending (enforced by security rules).
  Future<void> cancelOrder(String orderId) async {
    await _db.collection(AppConstants.ordersCollection).doc(orderId).update({
      'orderStatus': AppConstants.orderCancelled,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': AppConstants.orderCancelled,
          'timestamp': Timestamp.now(),
          'note': 'Cancelled by customer',
        },
      ]),
    });
  }

  // ── Deliveries ─────────────────────────────────────────

  Future<DeliveryModel?> getDeliveryByOrderId(String orderId) async {
    final snap = await _db
        .collection(AppConstants.deliveriesCollection)
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DeliveryModel.fromFirestore(snap.docs.first);
  }

  Stream<DeliveryModel?> watchDeliveryByOrderId(String orderId) {
    return _db
        .collection(AppConstants.deliveriesCollection)
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return DeliveryModel.fromFirestore(snap.docs.first);
    });
  }

  // ── Notifications ──────────────────────────────────────

  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .delete();
  }

  // ── Admin: Products ────────────────────────────────────

  Stream<List<ProductModel>> watchAllProducts() {
    return _db
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProductModel.fromFirestore).toList());
  }

  Future<List<ProductModel>> getAllProducts({int limit = 200}) async {
    final snap = await _db
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(ProductModel.fromFirestore).toList();
  }

  Future<String> saveProduct(ProductModel product) async {
    final col = _db.collection(AppConstants.productsCollection);
    final data = product.toMap()
      ..['nameLower'] = product.name.trim().toLowerCase()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (product.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['rating'] = product.rating;
      data['totalReviews'] = product.totalReviews;
      final doc = await col.add(data);
      return doc.id;
    }

    data.remove('createdAt');
    await col.doc(product.id).set(data, SetOptions(merge: true));
    return product.id;
  }

  Future<void> deleteProduct(String productId) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .delete();
  }

  Future<void> updateProductStock(String productId, int stock) async {
    await _db.collection(AppConstants.productsCollection).doc(productId).update({
      'stock': stock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin: Categories ──────────────────────────────────

  Stream<List<CategoryModel>> watchAllCategories() {
    return _db
        .collection(AppConstants.categoriesCollection)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromFirestore).toList());
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final snap = await _db
        .collection(AppConstants.categoriesCollection)
        .orderBy('sortOrder')
        .get();
    return snap.docs.map(CategoryModel.fromFirestore).toList();
  }

  Future<String> saveCategory(CategoryModel category) async {
    final col = _db.collection(AppConstants.categoriesCollection);
    if (category.id.isEmpty) {
      final doc = await col.add(category.toCreateMap());
      return doc.id;
    }
    final data = category.toMap()..remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await col.doc(category.id).set(data, SetOptions(merge: true));
    return category.id;
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db
        .collection(AppConstants.categoriesCollection)
        .doc(categoryId)
        .delete();
  }

  // ── Admin: Customers ───────────────────────────────────

  Stream<List<UserModel>> watchCustomers() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleCustomer)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(UserModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<UserModel>> getCustomers() async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleCustomer)
        .get();
    final list = snap.docs.map(UserModel.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin: Dashboard ───────────────────────────────────

  Future<AdminDashboardStats> getAdminDashboardStats() async {
    final productsSnap =
        await _db.collection(AppConstants.productsCollection).get();
    final customersSnap = await _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleCustomer)
        .get();
    final ordersSnap = await _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    final orders = ordersSnap.docs.map(OrderModel.fromFirestore).toList();
    var pending = 0;
    var completed = 0;
    var cancelled = 0;
    var revenue = 0.0;

    for (final o in orders) {
      if (o.orderStatus == AppConstants.orderPending ||
          o.orderStatus == AppConstants.orderConfirmed ||
          o.orderStatus == AppConstants.orderPreparing ||
          o.orderStatus == AppConstants.orderShipped ||
          o.orderStatus == AppConstants.orderOutForDelivery) {
        pending++;
      }
      if (o.isCompleted) {
        completed++;
        revenue += o.totalAmount;
      }
      if (o.isCancelled) cancelled++;
    }

    final recent = orders.take(8).toList();
    final bestSellers = productsSnap.docs
        .map(ProductModel.fromFirestore)
        .where((p) => p.isBestSeller && p.isActive)
        .take(5)
        .toList();

    return AdminDashboardStats(
      totalProducts: productsSnap.size,
      totalCustomers: customersSnap.size,
      totalOrders: orders.length,
      pendingOrders: pending,
      completedOrders: completed,
      cancelledOrders: cancelled,
      totalRevenue: revenue,
      recentOrders: recent,
      bestSellingProducts: bestSellers,
    );
  }

  Stream<List<OrderModel>> watchRecentOrders({int limit = 10}) {
    return _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  // ── Admin: Orders ──────────────────────────────────────

  Stream<List<OrderModel>> watchAllOrders({int limit = 100}) {
    return _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  Future<void> setOrderRider({
    required String orderId,
    required String? riderId,
  }) async {
    await _db.collection(AppConstants.ordersCollection).doc(orderId).update({
      'riderId': riderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin fallback when Cloud Functions are not deployed.
  Future<void> updateOrderStatusDirect({
    required String orderId,
    required String status,
    String? note,
  }) async {
    await _db.collection(AppConstants.ordersCollection).doc(orderId).update({
      'orderStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': status,
          'timestamp': Timestamp.now(),
          'note': note ?? 'Updated by admin to $status',
        },
      ]),
      if (status == AppConstants.orderDelivered)
        'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin: Deliveries ──────────────────────────────────

  Stream<List<DeliveryModel>> watchAllDeliveries({int limit = 100}) {
    return _db
        .collection(AppConstants.deliveriesCollection)
        .orderBy('assignedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(DeliveryModel.fromFirestore).toList());
  }

  Future<void> updateDelivery({
    required String deliveryId,
    String? riderId,
    String? riderName,
    String? status,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (riderId != null) data['riderId'] = riderId;
    if (riderName != null) data['riderName'] = riderName;
    if (status != null) data['status'] = status;
    if (notes != null) data['notes'] = notes;
    if (status == AppConstants.orderDelivered) {
      data['deliveredAt'] = FieldValue.serverTimestamp();
    }
    await _db
        .collection(AppConstants.deliveriesCollection)
        .doc(deliveryId)
        .update(data);
  }

  Future<void> assignRiderToDelivery({
    required String deliveryId,
    required String orderId,
    required UserModel rider,
  }) async {
    final batch = _db.batch();
    batch.update(
      _db.collection(AppConstants.deliveriesCollection).doc(deliveryId),
      {
        'riderId': rider.id,
        'riderName': rider.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(
      _db.collection(AppConstants.ordersCollection).doc(orderId),
      {
        'riderId': rider.id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  Future<List<UserModel>> getRiders() async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleRider)
        .get();
    final list = snap.docs.map(UserModel.fromFirestore).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // ── Admin: Reviews ─────────────────────────────────────

  Stream<List<ReviewModel>> watchAllReviews({int limit = 100}) {
    return _db
        .collection(AppConstants.reviewsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ReviewModel.fromFirestore).toList());
  }

  Future<void> setReviewApproved(String reviewId, bool isApproved) async {
    await _db.collection(AppConstants.reviewsCollection).doc(reviewId).update({
      'isApproved': isApproved,
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await _db.collection(AppConstants.reviewsCollection).doc(reviewId).delete();
  }

  // ── Admin: Coupons ─────────────────────────────────────

  Stream<List<CouponModel>> watchAllCoupons() {
    return _db
        .collection(AppConstants.couponsCollection)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(CouponModel.fromFirestore).toList();
      list.sort((a, b) => a.code.compareTo(b.code));
      return list;
    });
  }

  Future<String> saveCoupon(CouponModel coupon) async {
    final col = _db.collection(AppConstants.couponsCollection);
    final data = coupon.toMap();
    if (coupon.id.isEmpty) {
      data['usedCount'] = 0;
      final doc = await col.add(data);
      return doc.id;
    }
    data.remove('usedCount');
    await col.doc(coupon.id).set(data, SetOptions(merge: true));
    return coupon.id;
  }

  Future<void> setCouponActive(String couponId, bool isActive) async {
    await _db.collection(AppConstants.couponsCollection).doc(couponId).update({
      'isActive': isActive,
    });
  }

  Future<void> deleteCoupon(String couponId) async {
    await _db.collection(AppConstants.couponsCollection).doc(couponId).delete();
  }

  // ── Admin: Reports ─────────────────────────────────────

  Future<AdminReportStats> getAdminReportStats({
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) async {
    final snap = await _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    var orders = snap.docs.map(OrderModel.fromFirestore).toList();
    if (from != null) {
      orders = orders.where((o) => !o.createdAt.isBefore(from)).toList();
    }
    if (to != null) {
      final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
      orders = orders.where((o) => !o.createdAt.isAfter(end)).toList();
    }

    var revenue = 0.0;
    var delivered = 0;
    var cancelled = 0;
    var codCount = 0;
    var onlineCount = 0;
    final statusCounts = <String, int>{};
    final productQty = <String, int>{};
    final productRevenue = <String, double>{};
    final productName = <String, String>{};

    for (final order in orders) {
      statusCounts[order.orderStatus] =
          (statusCounts[order.orderStatus] ?? 0) + 1;

      if (order.isCompleted) {
        delivered++;
        revenue += order.totalAmount;
      }
      if (order.isCancelled) cancelled++;
      if (order.paymentMethod == AppConstants.paymentCod) {
        codCount++;
      } else if (order.paymentMethod == AppConstants.paymentOnline) {
        onlineCount++;
      }

      for (final item in order.items) {
        final id = item['productId'] as String? ?? item['id'] as String? ?? '';
        final name = item['productName'] as String? ??
            item['name'] as String? ??
            'Item';
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        final lineTotal = (item['lineTotal'] as num?)?.toDouble() ??
            ((item['unitPrice'] as num?)?.toDouble() ??
                    (item['price'] as num?)?.toDouble() ??
                    0) *
                qty;
        if (id.isEmpty) continue;
        productQty[id] = (productQty[id] ?? 0) + qty;
        productRevenue[id] = (productRevenue[id] ?? 0) + lineTotal;
        productName[id] = name;
      }
    }

    final topProducts = productQty.entries
        .map(
          (e) => AdminTopProductStat(
            productId: e.key,
            name: productName[e.key] ?? e.key,
            quantitySold: e.value,
            revenue: productRevenue[e.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return AdminReportStats(
      totalOrders: orders.length,
      deliveredOrders: delivered,
      cancelledOrders: cancelled,
      totalRevenue: revenue,
      codOrders: codCount,
      onlineOrders: onlineCount,
      statusCounts: statusCounts,
      topProducts: topProducts.take(10).toList(),
      ordersInRange: orders,
    );
  }

  /// Logs structured Firestore errors for debugging.
  void logError(String operation, Object error) {
    debugPrint('[FirestoreService] $operation failed: $error');
  }
}

/// Aggregated admin dashboard metrics.
class AdminDashboardStats {
  final int totalProducts;
  final int totalCustomers;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final List<OrderModel> recentOrders;
  final List<ProductModel> bestSellingProducts;

  const AdminDashboardStats({
    required this.totalProducts,
    required this.totalCustomers,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.recentOrders,
    required this.bestSellingProducts,
  });
}

/// Aggregated admin report metrics for a date range.
class AdminReportStats {
  final int totalOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final int codOrders;
  final int onlineOrders;
  final Map<String, int> statusCounts;
  final List<AdminTopProductStat> topProducts;
  final List<OrderModel> ordersInRange;

  const AdminReportStats({
    required this.totalOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.codOrders,
    required this.onlineOrders,
    required this.statusCounts,
    required this.topProducts,
    required this.ordersInRange,
  });
}

class AdminTopProductStat {
  final String productId;
  final String name;
  final int quantitySold;
  final double revenue;

  const AdminTopProductStat({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });
}
