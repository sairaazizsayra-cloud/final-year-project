import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

/// Visual timeline for home-to-home order tracking.
class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({
    super.key,
    required this.currentStatus,
    this.statusHistory = const [],
    this.isCancelled = false,
  });

  final String currentStatus;
  final List<Map<String, dynamic>> statusHistory;
  final bool isCancelled;

  int get _currentIndex {
    if (isCancelled) return -1;
    final idx = AppConstants.orderStatusFlow.indexOf(currentStatus);
    return idx < 0 ? 0 : idx;
  }

  DateTime? _timeFor(String status) {
    for (final entry in statusHistory.reversed) {
      if (entry['status'] == status) {
        final ts = entry['timestamp'];
        if (ts is Timestamp) return ts.toDate();
        if (ts is DateTime) return ts;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'This order was cancelled.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final current = _currentIndex;

    return Column(
      children: List.generate(AppConstants.orderStatusFlow.length, (index) {
        final status = AppConstants.orderStatusFlow[index];
        final done = index <= current;
        final isCurrent = index == current;
        final time = _timeFor(status);
        final isLast = index == AppConstants.orderStatusFlow.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : AppColors.surfaceMuted,
                    border: Border.all(
                      color: done ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: index < current
                        ? AppColors.primary
                        : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.orderStatusLabel(status),
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: done
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    if (time != null)
                      Text(
                        Formatters.dateTime(time),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
