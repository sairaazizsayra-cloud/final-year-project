import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/delivery_model.dart';
import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/models/user_model.dart';
import 'package:keychain_shop/services/admin_functions_service.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  bool _updating = false;
  List<UserModel> _riders = [];

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  Future<void> _loadRiders() async {
    try {
      final riders = await context.read<FirestoreService>().getRiders();
      if (!mounted) return;
      setState(() => _riders = riders);
    } catch (e) {
      debugPrint('[AdminOrderDetail] riders: $e');
    }
  }

  Future<void> _updateStatus(OrderModel order, String status) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set status: ${Formatters.orderStatusLabel(status)}'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'Visible in status history',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      noteController.dispose();
      return;
    }

    final note = noteController.text.trim();
    noteController.dispose();

    setState(() => _updating = true);
    try {
      await context.read<AdminFunctionsService>().updateOrderStatus(
            orderId: order.id,
            status: status,
            note: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status → ${Formatters.orderStatusLabel(status)}',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[AdminOrderDetail] CF status: ${e.code} ${e.message}');
      if (!mounted) return;
      final useDirect = e.code == 'not-found' ||
          e.code == 'unimplemented' ||
          e.code == 'unavailable';
      if (useDirect) {
        try {
          await context.read<FirestoreService>().updateOrderStatusDirect(
                orderId: order.id,
                status: status,
                note: note.isEmpty ? null : note,
              );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status updated locally '
                '(deploy Cloud Functions for push notifications).',
              ),
            ),
          );
        } catch (directError) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status update failed: $directError')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Status update failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _assignRider(OrderModel order, DeliveryModel? delivery) async {
    if (_riders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No riders found. Create a user with role "rider" in Firestore.',
          ),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<UserModel>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Assign rider',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final rider in _riders)
              ListTile(
                leading: const Icon(Icons.delivery_dining_outlined),
                title: Text(rider.name),
                subtitle: Text(rider.email),
                onTap: () => Navigator.pop(context, rider),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

    try {
      final firestore = context.read<FirestoreService>();
      if (delivery != null) {
        await firestore.assignRiderToDelivery(
          deliveryId: delivery.id,
          orderId: order.id,
          rider: selected,
        );
      } else {
        await firestore.setOrderRider(
          orderId: order.id,
          riderId: selected.id,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned ${selected.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assign failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<OrderModel?>(
      stream: firestore.watchOrder(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return const Center(child: Text('Order not found.'));
        }

        final addr = order.deliveryAddress;
        final addressLine = [
          addr['fullAddress'] ?? addr['street'],
          addr['area'],
          addr['city'],
        ].where((e) => e != null && '$e'.isNotEmpty).join(', ');

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/admin/orders'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('All orders'),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order.id.length > 10 ? order.id.substring(0, 10) : order.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        Formatters.orderStatusLabel(order.orderStatus),
                      ),
                      backgroundColor: Formatters.orderStatusColor(
                        order.orderStatus,
                      ).withValues(alpha: 0.15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(Formatters.dateTime(order.createdAt)),
                const SizedBox(height: 20),
                _SectionTitle('Customer'),
                Text(order.userName ?? '—'),
                Text(order.userEmail ?? ''),
                Text(order.userPhone ?? ''),
                const SizedBox(height: 16),
                _SectionTitle('Delivery address'),
                Text(addressLine.isEmpty ? '—' : addressLine),
                const SizedBox(height: 16),
                _SectionTitle('Payment'),
                Text(
                  '${Formatters.paymentMethodLabel(order.paymentMethod)} · '
                  '${order.paymentStatus}',
                ),
                Text('Total: ${Formatters.currency(order.totalAmount)}'),
                if (order.couponCode != null)
                  Text('Coupon: ${order.couponCode}'),
                const SizedBox(height: 16),
                _SectionTitle('Items'),
                ...order.items.map((item) {
                  final name = item['productName'] as String? ??
                      item['name'] as String? ??
                      'Item';
                  final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                  final price = (item['unitPrice'] as num?)?.toDouble() ??
                      (item['price'] as num?)?.toDouble() ??
                      0;
                  final line = (item['lineTotal'] as num?)?.toDouble() ??
                      price * qty;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    subtitle: Text('Qty $qty'),
                    trailing: Text(Formatters.currency(line)),
                  );
                }),
                const SizedBox(height: 8),
                StreamBuilder<DeliveryModel?>(
                  stream: firestore.watchDeliveryByOrderId(order.id),
                  builder: (context, deliverySnap) {
                    final delivery = deliverySnap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Delivery'),
                        if (delivery == null)
                          const Text(
                            'No delivery record yet (created when shipped).',
                          )
                        else ...[
                          Text('Status: ${delivery.status}'),
                          Text(
                            'Rider: ${delivery.riderName ?? delivery.riderId ?? 'Unassigned'}',
                          ),
                          if (delivery.notes != null &&
                              delivery.notes!.isNotEmpty)
                            Text('Notes: ${delivery.notes}'),
                        ],
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _updating
                              ? null
                              : () => _assignRider(order, delivery),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Assign rider'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _SectionTitle('Update status'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in [
                      ...AppConstants.orderStatusFlow,
                      AppConstants.orderCancelled,
                    ])
                      if (status != order.orderStatus)
                        ActionChip(
                          label: Text(Formatters.orderStatusLabel(status)),
                          onPressed: _updating
                              ? null
                              : () => _updateStatus(order, status),
                        ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTitle('Status history'),
                if (order.statusHistory.isEmpty)
                  const Text('No history yet.')
                else
                  ...order.statusHistory.reversed.map((h) {
                    final status = h['status'] as String? ?? '';
                    final note = h['note'] as String? ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.circle,
                        size: 12,
                        color: Formatters.orderStatusColor(status),
                      ),
                      title: Text(Formatters.orderStatusLabel(status)),
                      subtitle: Text(note),
                    );
                  }),
              ],
            ),
            if (_updating)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
