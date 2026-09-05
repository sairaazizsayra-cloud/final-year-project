import 'package:flutter_test/flutter_test.dart';
import 'package:keychain_shop/models/coupon_model.dart';
import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/constants/app_constants.dart';

void main() {
  group('ProductModel', () {
    test('discountedPrice applies percent discount', () {
      final product = ProductModel(
        id: 'p1',
        name: 'Brass Keychain',
        description: 'Test',
        categoryId: 'c1',
        price: 1000,
        discount: 10,
        stock: 5,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(product.discountedPrice, 900);
      expect(product.hasDiscount, isTrue);
      expect(product.inStock, isTrue);
    });
  });

  group('CouponModel', () {
    test('isValidNow respects active window and usage', () {
      final now = DateTime.now();
      final coupon = CouponModel(
        id: 'c1',
        code: 'SAVE10',
        description: '10% off',
        discountType: 'percentage',
        discountValue: 10,
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 7)),
        usageLimit: 100,
        usedCount: 5,
        isActive: true,
      );
      expect(coupon.isValidNow, isTrue);
      expect(coupon.isPercentage, isTrue);
    });

    test('isValidNow false when expired', () {
      final now = DateTime.now();
      final coupon = CouponModel(
        id: 'c2',
        code: 'OLD',
        description: 'Expired',
        discountType: 'fixed',
        discountValue: 100,
        validFrom: now.subtract(const Duration(days: 30)),
        validUntil: now.subtract(const Duration(days: 1)),
        isActive: true,
      );
      expect(coupon.isValidNow, isFalse);
    });
  });

  group('OrderModel', () {
    test('status helpers', () {
      final ongoing = OrderModel(
        id: 'o1',
        userId: 'u1',
        items: const [],
        subtotal: 500,
        totalAmount: 650,
        deliveryAddress: const {},
        orderStatus: AppConstants.orderShipped,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(ongoing.isOngoing, isTrue);
      expect(ongoing.isCompleted, isFalse);

      final done = OrderModel(
        id: 'o2',
        userId: 'u1',
        items: const [],
        subtotal: 500,
        totalAmount: 650,
        deliveryAddress: const {},
        orderStatus: AppConstants.orderDelivered,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(done.isCompleted, isTrue);
      expect(done.isOngoing, isFalse);
    });
  });

  group('delivery charge constants', () {
    test('free delivery threshold', () {
      expect(AppConstants.defaultDeliveryCharges, 150);
      expect(AppConstants.freeDeliveryThreshold, 2000);
    });
  });
}
