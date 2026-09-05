import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';

/// Customer orders stream (ongoing / completed / cancelled).
class OrdersProvider extends ChangeNotifier {
  OrdersProvider({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;

  String? _userId;
  List<OrderModel> _orders = [];
  StreamSubscription<List<OrderModel>>? _subscription;
  bool _loading = false;
  bool _mutating = false;
  String? _error;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _loading;
  bool get isMutating => _mutating;
  String? get error => _error;

  List<OrderModel> get ongoing =>
      _orders.where((o) => o.isOngoing).toList();

  List<OrderModel> get completed =>
      _orders.where((o) => o.isCompleted).toList();

  List<OrderModel> get cancelled =>
      _orders.where((o) => o.isCancelled).toList();

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _orders = [];
    _error = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _subscription = _firestore.watchUserOrders(userId).listen(
      (orders) {
        _orders = orders;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[OrdersProvider] $e');
        _loading = false;
        _error = 'Could not load orders.';
        notifyListeners();
      },
    );
  }

  Future<bool> cancelOrder(String orderId) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.cancelOrder(orderId);
      _mutating = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[OrdersProvider] cancel failed: $e');
      _error = 'Could not cancel order. It may no longer be pending.';
      _mutating = false;
      notifyListeners();
      return false;
    }
  }

  OrderModel? findById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
