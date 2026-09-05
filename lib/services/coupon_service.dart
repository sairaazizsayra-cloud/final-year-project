import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Client wrapper for coupon validation Cloud Function.
class CouponService {
  CouponService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<CouponValidationResult> validateCoupon({
    required String code,
    required double subtotal,
  }) async {
    try {
      final callable = _functions.httpsCallable('validateCoupon');
      final response = await callable.call<Map<String, dynamic>>({
        'code': code.trim().toUpperCase(),
        'subtotal': subtotal,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      return CouponValidationResult(
        valid: data['valid'] == true,
        couponId: data['couponId'] as String?,
        code: data['code'] as String? ?? code.trim().toUpperCase(),
        discountType: data['discountType'] as String? ?? 'percentage',
        discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0,
        discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
        message: 'Coupon applied.',
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[CouponService] ${e.code} ${e.message}');
      return CouponValidationResult(
        valid: false,
        message: e.message ?? 'Invalid coupon.',
      );
    } catch (e) {
      debugPrint('[CouponService] $e');
      return CouponValidationResult(
        valid: false,
        message: 'Could not validate coupon. Try again.',
      );
    }
  }
}

class CouponValidationResult {
  final bool valid;
  final String? couponId;
  final String? code;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final String message;

  const CouponValidationResult({
    required this.valid,
    this.couponId,
    this.code,
    this.discountType = 'percentage',
    this.discountValue = 0,
    this.discountAmount = 0,
    required this.message,
  });
}
