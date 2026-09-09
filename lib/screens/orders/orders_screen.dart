import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/providers/orders_provider.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';
import 'package:keychain_shop/widgets/section_header.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: orders.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(
                children: [
                  _OrdersList(
                    orders: orders.ongoing,
                    emptyMessage: 'No ongoing orders.',
                  ),
                  _OrdersList(
                    orders: orders.completed,
                    emptyMessage: 'No completed orders yet.',
                  ),
                  _OrdersList(
                    orders: orders.cancelled,
                    emptyMessage: 'No cancelled orders.',
                    allowDelete: true,
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyMessage,
    this.allowDelete = false,
  });

  final List<OrderModel> orders;
  final String emptyMessage;
  final bool allowDelete;

  Future<void> _confirmDelete(BuildContext context, OrderModel order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cancelled order?'),
        content: const Text(
          'This removes the order from your history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final provider = context.read<OrdersProvider>();
    final success = await provider.deleteCancelledOrder(order.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Cancelled order removed.'
              : (provider.error ?? 'Could not delete order.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return AppEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: emptyMessage,
        message: 'Your keychain orders will show up here with tracking.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        final statusColor = Formatters.orderStatusColor(order.orderStatus);
        final itemCount = order.items.fold<int>(
          0,
          (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1),
        );

        return InkWell(
          onTap: () => context.pushOverlay('/orders/${order.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Formatters.orderStatusLabel(order.orderStatus),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (allowDelete) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () => _confirmDelete(context, order),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.dateTime(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('$itemCount item${itemCount == 1 ? '' : 's'}'),
                    const Spacer(),
                    Text(
                      Formatters.currency(order.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
