import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Admin-only Cloud Function calls (order status, etc.).
class AdminFunctionsService {
  AdminFunctionsService({FirebaseFunctions? functions})
      : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  /// Updates order status via CF so FCM + delivery sync run server-side.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateOrderStatus');
      await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'status': status,
        'note': note,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[AdminFunctionsService] updateOrderStatus: ${e.code} ${e.message}',
      );
      rethrow;
    }
  }
}
