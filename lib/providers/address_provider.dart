import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:keychain_shop/models/address_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';

/// Home-to-home delivery addresses for the signed-in user.
class AddressProvider extends ChangeNotifier {
  AddressProvider({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;

  String? _userId;
  List<AddressModel> _addresses = [];
  StreamSubscription<List<AddressModel>>? _subscription;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<AddressModel> get addresses => List.unmodifiable(_addresses);
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get error => _error;

  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _addresses = [];
    _error = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _subscription = _firestore.watchUserAddresses(userId).listen(
      (list) {
        _addresses = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[AddressProvider] stream error: $e');
        _loading = false;
        _error = 'Could not load addresses.';
        notifyListeners();
        // One-shot fallback if the live query fails (e.g. transient rules/index).
        unawaited(_reloadOnce(userId));
      },
    );
  }

  Future<void> _reloadOnce(String userId) async {
    try {
      final list = await _firestore.getUserAddresses(userId);
      if (_userId != userId) return;
      _addresses = list;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[AddressProvider] fallback load failed: $e');
    }
  }

  /// Forces a refresh — useful before checkout place-order.
  Future<void> refresh() async {
    final uid = _userId;
    if (uid == null) return;
    _loading = true;
    notifyListeners();
    try {
      _addresses = await _firestore.getUserAddresses(uid);
      _error = null;
    } catch (e) {
      debugPrint('[AddressProvider] refresh failed: $e');
      _error = 'Could not load addresses.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(AddressModel address) async {
    final uid = _userId;
    if (uid == null) {
      _error = 'Please sign in.';
      notifyListeners();
      return false;
    }

    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final toSave = address.copyWith(userId: uid);
      // If this is the first address, force default.
      final makeDefault = toSave.isDefault || _addresses.isEmpty;
      await _firestore.saveAddress(toSave.copyWith(isDefault: makeDefault));
      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AddressProvider] save failed: $e');
      _error = 'Could not save address.';
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String addressId) async {
    _saving = true;
    notifyListeners();
    try {
      await _firestore.deleteAddress(addressId);
      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AddressProvider] delete failed: $e');
      _error = 'Could not delete address.';
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefault(String addressId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _firestore.setDefaultAddress(userId: uid, addressId: addressId);
      return true;
    } catch (e) {
      debugPrint('[AddressProvider] setDefault failed: $e');
      _error = 'Could not update default address.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
