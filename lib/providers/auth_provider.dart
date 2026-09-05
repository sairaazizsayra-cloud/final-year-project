import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:keychain_shop/models/user_model.dart';
import 'package:keychain_shop/services/auth_service.dart';

/// Auth state for Provider — session, login, signup, password reset.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _listenAuthChanges();
  }

  final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isRider => _user?.isRider ?? false;
  bool get initialized => _initialized;

  void _listenAuthChanges() {
    if (Firebase.apps.isEmpty) {
      debugPrint('[AuthProvider] Firebase not ready — skipping auth stream');
      _initialized = true;
      notifyListeners();
      return;
    }

    _authService.authStateChanges.listen(
      (firebaseUser) async {
        if (firebaseUser == null) {
          _user = null;
          _initialized = true;
          notifyListeners();
          return;
        }

        try {
          _user = await _authService.getUserProfile(firebaseUser.uid);
        } catch (e) {
          debugPrint('[AuthProvider] Profile load error: $e');
          _user = null;
        }
        _initialized = true;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[AuthProvider] Auth stream error: $e');
        _user = null;
        _initialized = true;
        notifyListeners();
      },
    );
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    return _runAuthAction(() async {
      _user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
    });
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      _user = await _authService.signIn(email: email, password: password);
    });
  }

  Future<bool> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      _user = await _authService.signInAsAdmin(
        email: email,
        password: password,
      );
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    return _runAuthAction(() async {
      await _authService.sendPasswordResetEmail(email);
    });
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    if (Firebase.apps.isEmpty) {
      _error =
          'Firebase is not connected. Run flutterfire configure and restart.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] Unexpected error: $e');
      _error = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
