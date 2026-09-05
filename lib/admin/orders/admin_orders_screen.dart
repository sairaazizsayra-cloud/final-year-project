import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _query = '';
  String? _statusFilter;

  static const _filters = <String?>[
    null,
    AppConstants.orderPending,
    AppConstants.orderConfirmed,
    AppConstants.orderPreparing,
    AppConstants.orderShipped,
    AppConstants.orderOutForDelivery,
    AppConstants.orderDelivered,
    AppConstants.orderCancelled,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search order id, name, phone…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final status = _filters[index];
              final selected = _statusFilter == status;
              final label = status == null
                  ? 'All'
                  : Formatters.orderStatusLabel(status);
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _statusFilter = status),
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.45),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: context.read<FirestoreService>().watchAllOrders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              var orders = snapshot.data ?? [];
              if (_statusFilter != null) {
                orders = orders
                    .where((o) => o.orderStatus == _statusFilter)
                    .toList();
              }
              if (_query.isNotEmpty) {
                orders = orders.where((o) {
                  final addr = o.deliveryAddress;
                  final city = '${addr['city'] ?? ''}'.toLowerCase();
                  return o.id.toLowerCase().contains(_query) ||
                      (o.userName ?? '').toLowerCase().contains(_query) ||
                      (o.userEmail ?? '').toLowerCase().contains(_query) ||
                      (o.userPhone ?? '').contains(_query) ||
                      city.contains(_query);
                }).toList();
              }

              if (orders.isEmpty) {
                return const Center(child: Text('No orders found.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final shortId = order.id.length > 8
                      ? order.id.substring(0, 8)
                      : order.id;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    title: Text(
                      '#$shortId · ${order.userName ?? 'Customer'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${Formatters.orderStatusLabel(order.orderStatus)}\n'
                      '${Formatters.dateTime(order.createdAt)} · '
                      '${Formatters.paymentMethodLabel(order.paymentMethod)}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(order.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: Formatters.orderStatusColor(order.orderStatus),
                        ),
                      ],
                    ),
                    onTap: () => context.go('/admin/orders/${order.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
