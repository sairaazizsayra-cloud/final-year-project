import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/user_model.dart';

/// Handles Firebase Authentication and user profile bootstrap in Firestore.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _authOverride = auth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Register a new customer with email/password and create Firestore profile.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('Registration failed. Please try again.');
      }

      await user.updateDisplayName(name.trim());
      await user.sendEmailVerification();

      final profile = UserModel(
        id: user.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone?.trim(),
        role: AppConstants.roleCustomer,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _usersRef.doc(user.uid).set(profile.toCreateMap());
      debugPrint('[AuthService] User registered: ${user.uid}');
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed. Please try again.');
    }
  }

  /// Sign in with email/password and return Firestore user profile.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('Login failed. Please try again.');
      }

      final profile = await getUserProfile(user.uid);
      if (profile == null) {
        throw AuthException('User profile not found.');
      }
      if (!profile.isActive) {
        await _auth.signOut();
        throw AuthException('Your account has been deactivated.');
      }

      debugPrint('[AuthService] User signed in: ${user.uid}');
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Login failed. Please try again.');
    }
  }

  /// Admin login — verifies role is admin after Firebase Auth success.
  Future<UserModel> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    final profile = await signIn(email: email, password: password);
    if (!profile.isAdmin) {
      await signOut();
      throw AuthException('Access denied. Admin credentials required.');
    }
    return profile;
  }

  /// Rider login — verifies role is rider after Firebase Auth success.
  Future<UserModel> signInAsRider({
    required String email,
    required String password,
  }) async {
    final profile = await signIn(email: email, password: password);
    if (!profile.isRider) {
      await signOut();
      throw AuthException('Access denied. Rider credentials required.');
    }
    return profile;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[AuthService] Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No user signed in.');
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('No user signed in.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      debugPrint('[AuthService] Password updated for ${user.uid}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name.trim();
    if (phone != null) updates['phone'] = phone.trim();
    if (profileImage != null) updates['profileImage'] = profileImage;

    await _usersRef.doc(uid).update(updates);

    if (name != null) {
      await _auth.currentUser?.updateDisplayName(name.trim());
    }
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _usersRef.doc(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('[AuthService] User signed out');
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
