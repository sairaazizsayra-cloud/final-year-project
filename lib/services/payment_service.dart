import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:keychain_shop/constants/app_constants.dart';

/// Payment orchestration.
/// COD is client-side; online verification must go through Cloud Functions.
class PaymentService {
  PaymentService({FirebaseFunctions? functions})
      : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  /// Cash on Delivery — no gateway call; payment collected at delivery.
  Future<PaymentResult> processCashOnDelivery({
    required String orderId,
    required double amount,
  }) async {
    debugPrint(
      '[PaymentService] COD registered for order $orderId amount=$amount',
    );
    return PaymentResult(
      success: true,
      method: AppConstants.paymentCod,
      status: AppConstants.paymentPending,
      orderId: orderId,
      message: 'Order placed. Pay cash on delivery.',
    );
  }

  /// Starts an online payment session via Cloud Function.
  /// Never put payment secret keys in Flutter — verification is server-side.
  Future<PaymentResult> initiateOnlinePayment({
    required String orderId,
    required double amount,
    required String userId,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymentSession');
      final response = await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'amount': amount,
        'userId': userId,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final ok = data['success'] == true;
      return PaymentResult(
        success: ok,
        method: AppConstants.paymentOnline,
        status: ok
            ? (data['status'] as String? ?? AppConstants.paymentPending)
            : AppConstants.paymentFailed,
        orderId: orderId,
        message: data['message'] as String? ??
            (ok
                ? 'Payment session created.'
                : 'Online payment could not be started.'),
        transactionId: data['transactionId'] as String?,
        paymentUrl: data['paymentUrl'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[PaymentService] createPaymentSession: ${e.code} ${e.message}');
      // Function not deployed / not found — architecture ready, gateway pending.
      return PaymentResult(
        success: false,
        method: AppConstants.paymentOnline,
        status: AppConstants.paymentFailed,
        orderId: orderId,
        message: e.code == 'not-found' || e.code == 'unimplemented'
            ? 'Online payment gateway is not configured yet. Please use Cash on Delivery.'
            : (e.message ?? 'Online payment failed. Try Cash on Delivery.'),
      );
    } catch (e) {
      debugPrint('[PaymentService] online payment error: $e');
      return PaymentResult(
        success: false,
        method: AppConstants.paymentOnline,
        status: AppConstants.paymentFailed,
        orderId: orderId,
        message:
            'Online payment is unavailable right now. Please use Cash on Delivery.',
      );
    }
  }
}

class PaymentResult {
  final bool success;
  final String method;
  final String status;
  final String orderId;
  final String message;
  final String? transactionId;
  final String? paymentUrl;

  const PaymentResult({
    required this.success,
    required this.method,
    required this.status,
    required this.orderId,
    required this.message,
    this.transactionId,
    this.paymentUrl,
  });
}
