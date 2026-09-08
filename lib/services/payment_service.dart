import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:keychain_shop/constants/app_constants.dart';

/// Payment orchestration.
/// COD is client-side; online verification prefers Cloud Functions.
/// When Functions are not deployed (Spark plan), a demo session is used so
/// checkout can still complete for FYP demos.
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
      // Function may be deployed but gateway still stubbed — use demo success.
      if (!ok && _looksLikeGatewayNotConfigured(data['message'])) {
        return _demoOnlineSuccess(orderId: orderId, amount: amount);
      }
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
      if (e.code == 'not-found' ||
          e.code == 'unimplemented' ||
          e.code == 'unavailable') {
        return _demoOnlineSuccess(orderId: orderId, amount: amount);
      }
      return PaymentResult(
        success: false,
        method: AppConstants.paymentOnline,
        status: AppConstants.paymentFailed,
        orderId: orderId,
        message: e.message ?? 'Online payment failed. Try Cash on Delivery.',
      );
    } catch (e) {
      debugPrint('[PaymentService] online payment error: $e');
      // Web / Spark often surface callable errors as generic failures.
      return _demoOnlineSuccess(orderId: orderId, amount: amount);
    }
  }

  bool _looksLikeGatewayNotConfigured(Object? message) {
    final text = (message ?? '').toString().toLowerCase();
    return text.contains('not configured') ||
        text.contains('cash on delivery') ||
        text.contains('gateway');
  }

  PaymentResult _demoOnlineSuccess({
    required String orderId,
    required double amount,
  }) {
    debugPrint(
      '[PaymentService] Demo online payment for order $orderId amount=$amount',
    );
    return PaymentResult(
      success: true,
      method: AppConstants.paymentOnline,
      status: AppConstants.paymentPaid,
      orderId: orderId,
      message:
          'Order placed with demo online payment (gateway not configured yet).',
      transactionId: 'demo_$orderId',
      isDemo: true,
    );
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
  final bool isDemo;

  const PaymentResult({
    required this.success,
    required this.method,
    required this.status,
    required this.orderId,
    required this.message,
    this.transactionId,
    this.paymentUrl,
    this.isDemo = false,
  });
}
