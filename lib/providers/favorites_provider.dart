import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:keychain_shop/models/favorite_model.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';

/// Manages the signed-in user's favorite product IDs and resolved products.
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;

  String? _userId;
  final Set<String> _favoriteProductIds = {};
  List<ProductModel> _favoriteProducts = [];
  StreamSubscription<List<FavoriteModel>>? _subscription;
  bool _loading = false;
  String? _error;

  Set<String> get favoriteProductIds => Set.unmodifiable(_favoriteProductIds);
  List<ProductModel> get favoriteProducts =>
      List.unmodifiable(_favoriteProducts);
  bool get isLoading => _loading;
  String? get error => _error;
  int get count => _favoriteProductIds.length;

  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _favoriteProductIds.clear();
    _favoriteProducts = [];
    _error = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _subscription = _firestore.watchUserFavorites(userId).listen(
      (favorites) async {
        _favoriteProductIds
          ..clear()
          ..addAll(favorites.map((f) => f.productId));
        try {
          _favoriteProducts =
              await _firestore.getProductsByIds(_favoriteProductIds.toList());
          _favoriteProducts =
              _favoriteProducts.where((p) => p.isActive).toList();
        } catch (e) {
          debugPrint('[FavoritesProvider] resolve products: $e');
        }
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[FavoritesProvider] stream error: $e');
        _loading = false;
        _error = 'Could not load favorites.';
        notifyListeners();
      },
    );
  }

  Future<void> toggle(String productId) async {
    final uid = _userId;
    if (uid == null) {
      _error = 'Please sign in to save favorites.';
      notifyListeners();
      return;
    }

    final currentlyFavorite = isFavorite(productId);

    // Optimistic update
    if (currentlyFavorite) {
      _favoriteProductIds.remove(productId);
      _favoriteProducts.removeWhere((p) => p.id == productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    try {
      if (currentlyFavorite) {
        await _firestore.removeFavorite(userId: uid, productId: productId);
      } else {
        await _firestore.addFavorite(userId: uid, productId: productId);
        final product = await _firestore.getProduct(productId);
        if (product != null &&
            !_favoriteProducts.any((p) => p.id == productId)) {
          _favoriteProducts = [..._favoriteProducts, product];
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[FavoritesProvider] toggle failed: $e');
      // Revert
      if (currentlyFavorite) {
        _favoriteProductIds.add(productId);
      } else {
        _favoriteProductIds.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
      }
      _error = 'Could not update favorite. Try again.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
