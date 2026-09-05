import 'package:flutter_test/flutter_test.dart';
import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('currency formats with Rs prefix', () {
      expect(Formatters.currency(1500), contains('1,500'));
      expect(Formatters.currency(1500), startsWith('Rs'));
    });

    test('order status labels', () {
      expect(
        Formatters.orderStatusLabel(AppConstants.orderPending),
        'Order Placed',
      );
      expect(
        Formatters.orderStatusLabel(AppConstants.orderOutForDelivery),
        'Out for Delivery',
      );
      expect(
        Formatters.orderStatusLabel(AppConstants.orderDelivered),
        'Delivered',
      );
    });

    test('payment method labels', () {
      expect(
        Formatters.paymentMethodLabel(AppConstants.paymentCod),
        'Cash on Delivery',
      );
      expect(
        Formatters.paymentMethodLabel(AppConstants.paymentOnline),
        'Online Payment',
      );
    });
  });
}
