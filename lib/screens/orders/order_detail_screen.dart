import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/delivery_model.dart';
import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/providers/orders_provider.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/order_tracking_timeline.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final ordersProvider = context.watch<OrdersProvider>();

    return StreamBuilder<OrderModel?>(
      stream: firestore.watchOrder(widget.orderId),
      builder: (context, snapshot) {
        final order = snapshot.data ??
            ordersProvider.findById(widget.orderId);

        if (snapshot.connectionState == ConnectionState.waiting &&
            order == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order')),
            body: const Center(child: Text('Order not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _StatusBanner(order: order),
              const SizedBox(height: 20),
              Text(
                'Tracking',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              OrderTrackingTimeline(
                currentStatus: order.orderStatus,
                statusHistory: order.statusHistory,
                isCancelled: order.isCancelled,
              ),
              const SizedBox(height: 24),
              Text(
                'Home-to-home delivery',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              _AddressCard(address: order.deliveryAddress),
              const SizedBox(height: 12),
              StreamBuilder<DeliveryModel?>(
                stream: firestore.watchDeliveryByOrderId(order.id),
                builder: (context, deliverySnap) {
                  final delivery = deliverySnap.data;
                  if (delivery == null) {
                    return Text(
                      'Delivery assignment will appear when the order is shipped.',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return _DeliveryCard(delivery: delivery);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) {
                final name = item['productName'] as String? ?? 'Item';
                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                final total = (item['lineTotal'] as num?)?.toDouble() ?? 0;
                final color = item['selectedColor'] as String?;
                final custom = item['customText'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$name × $qty'),
                            if (color != null || custom != null)
                              Text(
                                [
                                  ?color,
                                  if (custom != null && custom.isNotEmpty)
                                    '"$custom"',
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Text(Formatters.currency(total)),
                    ],
                  ),
                );
              }),
              const Divider(height: 28),
              _row('Subtotal', Formatters.currency(order.subtotal)),
              _row(
                'Delivery',
                order.deliveryCharges == 0
                    ? 'Free'
                    : Formatters.currency(order.deliveryCharges),
              ),
              if (order.discount > 0)
                _row('Discount', '- ${Formatters.currency(order.discount)}'),
              _row(
                'Payment',
                Formatters.paymentMethodLabel(order.paymentMethod),
              ),
              const SizedBox(height: 6),
              _row(
                'Total',
                Formatters.currency(order.totalAmount),
                bold: true,
              ),
              if (order.estimatedDeliveryDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Estimated delivery: ${Formatters.date(order.estimatedDeliveryDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(order.notes!),
              ],
              if (order.isCompleted) ...[
                const SizedBox(height: 24),
                Text(
                  'Write a review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reviews are moderated before they appear on product pages.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  final productId = item['productId'] as String? ?? '';
                  final name = item['productName'] as String? ??
                      item['name'] as String? ??
                      'Item';
                  if (productId.isEmpty) return const SizedBox.shrink();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    trailing: TextButton(
                      onPressed: () => _openReviewSheet(
                        context,
                        order: order,
                        productId: productId,
                        productName: name,
                      ),
                      child: const Text('Review'),
                    ),
                  );
                }),
              ],
              if (order.orderStatus == AppConstants.orderPending) ...[
                const SizedBox(height: 24),
                AppButton(
                  label: 'Cancel order',
                  isOutlined: true,
                  isLoading: ordersProvider.isMutating,
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel order?'),
                        content: const Text(
                          'You can only cancel while the order is still pending.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Keep'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Cancel order'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    final success =
                        await ordersProvider.cancelOrder(order.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Order cancelled.'
                              : (ordersProvider.error ??
                                  'Could not cancel order.'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }

  Future<void> _openReviewSheet(
    BuildContext context, {
    required OrderModel order,
    required String productId,
    required String productName,
  }) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final firestore = context.read<FirestoreService>();
    final already = await firestore.hasUserReviewedProduct(
      userId: user.id,
      productId: productId,
      orderId: order.id,
    );
    if (!context.mounted) return;
    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already reviewed this item.')),
      );
      return;
    }

    final commentController = TextEditingController();
    var rating = 5.0;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Review $productName',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          onPressed: () =>
                              setModalState(() => rating = i.toDouble()),
                          icon: Icon(
                            i <= rating ? Icons.star : Icons.star_border,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (commentController.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Submit review'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final comment = commentController.text.trim();
    commentController.dispose();
    if (submitted != true || comment.isEmpty || !context.mounted) return;

    try {
      await firestore.createReview(
        productId: productId,
        userId: user.id,
        userName: user.name,
        orderId: order.id,
        rating: rating,
        comment: comment,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks! Your review is pending approval.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit review: $e')),
      );
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final color = Formatters.orderStatusColor(order.orderStatus);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.orderStatusLabel(order.orderStatus),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Placed ${Formatters.dateTime(order.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final Map<String, dynamic> address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address['fullName'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(address['phone'] as String? ?? ''),
          const SizedBox(height: 4),
          Text(
            address['formattedAddress'] as String? ??
                [
                  address['houseStreet'],
                  address['area'],
                  address['city'],
                  address['postalCode'],
                ].whereType<String>().join(', '),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery assignment',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('Status: ${Formatters.orderStatusLabel(delivery.status)}'),
          if (delivery.riderName != null)
            Text('Rider: ${delivery.riderName}'),
          if (delivery.notes != null && delivery.notes!.isNotEmpty)
            Text('Note: ${delivery.notes}'),
        ],
      ),
    );
  }
}
