import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/theme/app_theme.dart';

/// Formatting helpers for prices, dates, and order statuses.
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String currency(num amount) => _currency.format(amount);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String orderStatusLabel(String status) {
    switch (status) {
      case AppConstants.orderPending:
        return 'Order Placed';
      case AppConstants.orderConfirmed:
        return 'Order Confirmed';
      case AppConstants.orderPreparing:
        return 'Preparing';
      case AppConstants.orderShipped:
        return 'Shipped';
      case AppConstants.orderOutForDelivery:
        return 'Out for Delivery';
      case AppConstants.orderDelivered:
        return 'Delivered';
      case AppConstants.orderCancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color orderStatusColor(String status) {
    switch (status) {
      case AppConstants.orderPending:
        return AppColors.warning;
      case AppConstants.orderConfirmed:
      case AppConstants.orderPreparing:
        return AppColors.info;
      case AppConstants.orderShipped:
      case AppConstants.orderOutForDelivery:
        return AppColors.primaryDark;
      case AppConstants.orderDelivered:
        return AppColors.success;
      case AppConstants.orderCancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  static String paymentMethodLabel(String method) {
    switch (method) {
      case AppConstants.paymentCod:
        return 'Cash on Delivery';
      case AppConstants.paymentOnline:
        return 'Online Payment';
      default:
        return method;
    }
  }
}
