import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:keychain_shop/constants/app_constants.dart';

/// Uploads files to Firebase Storage and returns download URLs for Firestore.
class StorageService {
  StorageService({FirebaseStorage? storage}) : _storageOverride = storage;

  final FirebaseStorage? _storageOverride;

  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  Future<String> uploadProductImage({
    required String productId,
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    final name = fileName ?? 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.productImagesPath}/$productId/$name';
    return _upload(path: path, file: file, bytes: bytes);
  }

  Future<String> uploadCategoryImage({
    required String categoryId,
    File? file,
    Uint8List? bytes,
  }) async {
    final path = '${AppConstants.categoryImagesPath}/$categoryId.jpg';
    return _upload(path: path, file: file, bytes: bytes);
  }

  Future<String> uploadProfileImage({
    required String userId,
    File? file,
    Uint8List? bytes,
  }) async {
    final path = '${AppConstants.profileImagesPath}/$userId.jpg';
    return _upload(path: path, file: file, bytes: bytes);
  }

  Future<String> uploadCustomKeychainImage({
    required String userId,
    File? file,
    Uint8List? bytes,
  }) async {
    final name = 'custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.customKeychainImagesPath}/$userId/$name';
    return _upload(path: path, file: file, bytes: bytes);
  }

  Future<String> uploadBannerImage({
    required String bannerId,
    File? file,
    Uint8List? bytes,
  }) async {
    final path = '${AppConstants.bannerImagesPath}/$bannerId.jpg';
    return _upload(path: path, file: file, bytes: bytes);
  }

  Future<void> deleteByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('[StorageService] Deleted: $downloadUrl');
    } catch (e) {
      debugPrint('[StorageService] Delete failed: $e');
      rethrow;
    }
  }

  Future<String> _upload({
    required String path,
    File? file,
    Uint8List? bytes,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      if (bytes != null) {
        await ref.putData(bytes, metadata);
      } else if (file != null) {
        await ref.putFile(file, metadata);
      } else {
        throw StorageException('No image data provided.');
      }
      final url = await ref.getDownloadURL();
      debugPrint('[StorageService] Uploaded: $path');
      return url;
    } catch (e) {
      debugPrint('[StorageService] Upload failed ($path): $e');
      if (e is StorageException) rethrow;
      throw StorageException('Image upload failed. Please try again.');
    }
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => message;
}
