import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/cart_item_model.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';

/// Cart state synced to Firestore `cart/{userId}/items`.
class CartProvider extends ChangeNotifier {
  CartProvider({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;

  String? _userId;
  List<CartItemModel> _items = [];
  StreamSubscription<List<CartItemModel>>? _subscription;
  bool _loading = false;
  bool _mutating = false;
  String? _error;

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isMutating => _mutating;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold<int>(0, (sum, i) => sum + i.quantity);

  double get subtotal =>
      _items.fold<double>(0, (sum, i) => sum + i.lineTotal);

  double get deliveryCharges {
    if (_items.isEmpty) return 0;
    if (subtotal >= AppConstants.freeDeliveryThreshold) return 0;
    return AppConstants.defaultDeliveryCharges;
  }

  double _discount = 0;
  String? _couponCode;
  String? _couponId;

  double get discount => _discount.clamp(0.0, subtotal);

  String? get couponCode => _couponCode;
  String? get couponId => _couponId;

  double get total => (subtotal - discount) + deliveryCharges;

  void applyCoupon({
    required String code,
    required String couponId,
    required double discountAmount,
  }) {
    _couponCode = code.toUpperCase();
    _couponId = couponId;
    _discount = discountAmount.clamp(0, subtotal);
    notifyListeners();
  }

  void clearCoupon() {
    _couponCode = null;
    _couponId = null;
    _discount = 0;
    notifyListeners();
  }

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _items = [];
    _error = null;
    clearCoupon();

    if (userId == null) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _subscription = _firestore.watchCart(userId).listen(
      (items) {
        _items = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[CartProvider] stream error: $e');
        _loading = false;
        _error = 'Could not load cart.';
        notifyListeners();
      },
    );
  }

  Future<bool> addProduct({
    required ProductModel product,
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
    String? customText,
    String? customImageUrl,
  }) async {
    final uid = _userId;
    if (uid == null) {
      _error = 'Please sign in to add items to cart.';
      notifyListeners();
      return false;
    }

    final id = CartItemModel.lineDocId(
      productId: product.id,
      selectedColor: selectedColor,
      selectedSize: selectedSize,
      customText: customText,
    );

    final item = CartItemModel(
      id: id,
      productId: product.id,
      productName: product.name,
      productImage: product.primaryImage,
      price: product.price,
      discount: product.discount,
      quantity: quantity.clamp(1, AppConstants.maxCartQuantity),
      selectedColor: selectedColor,
      selectedSize: selectedSize,
      customText: customText?.trim().isEmpty == true ? null : customText?.trim(),
      customImageUrl: customImageUrl,
      addedAt: DateTime.now(),
    );

    return _runMutation(() async {
      await _firestore.addToCart(userId: uid, item: item);
    });
  }

  Future<bool> updateQuantity(String itemId, int quantity) async {
    final uid = _userId;
    if (uid == null) return false;
    return _runMutation(() async {
      await _firestore.updateCartQuantity(
        userId: uid,
        itemId: itemId,
        quantity: quantity,
      );
    });
  }

  Future<bool> removeItem(String itemId) async {
    final uid = _userId;
    if (uid == null) return false;
    return _runMutation(() async {
      await _firestore.removeFromCart(userId: uid, itemId: itemId);
    });
  }

  Future<bool> clear() async {
    final uid = _userId;
    if (uid == null) return false;
    final ok = await _runMutation(() async {
      await _firestore.clearCart(uid);
    });
    if (ok) clearCoupon();
    return ok;
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _mutating = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[CartProvider] mutation failed: $e');
      _error = 'Cart update failed. Please try again.';
      _mutating = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
