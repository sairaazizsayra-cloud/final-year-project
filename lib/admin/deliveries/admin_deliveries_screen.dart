import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/delivery_model.dart';
import 'package:keychain_shop/models/user_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  String? _statusFilter;
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
      debugPrint('[AdminDeliveries] riders: $e');
    }
  }

  Future<void> _assignRider(DeliveryModel delivery) async {
    if (_riders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No riders found. Create a Firestore user with role "rider".',
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
      await context.read<FirestoreService>().assignRiderToDelivery(
            deliveryId: delivery.id,
            orderId: delivery.orderId,
            rider: selected,
          );
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

  Future<void> _editNotes(DeliveryModel delivery) async {
    final controller = TextEditingController(text: delivery.notes ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery notes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Rider / route notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) {
      controller.dispose();
      return;
    }
    final notes = controller.text.trim();
    controller.dispose();
    try {
      await context.read<FirestoreService>().updateDelivery(
            deliveryId: delivery.id,
            notes: notes,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = <String?>[
      null,
      AppConstants.orderShipped,
      AppConstants.orderOutForDelivery,
      AppConstants.orderDelivered,
      AppConstants.orderPending,
    ];

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final status = filters[index];
              final label = status == null
                  ? 'All'
                  : Formatters.orderStatusLabel(status);
              return FilterChip(
                label: Text(label),
                selected: _statusFilter == status,
                onSelected: (_) => setState(() => _statusFilter = status),
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.45),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<DeliveryModel>>(
            stream: context.read<FirestoreService>().watchAllDeliveries(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load deliveries.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              var deliveries = snapshot.data ?? [];
              if (_statusFilter != null) {
                deliveries = deliveries
                    .where((d) => d.status == _statusFilter)
                    .toList();
              }

              if (deliveries.isEmpty) {
                return const Center(
                  child: Text(
                    'No deliveries yet.\nThey appear when orders are shipped.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: deliveries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final d = deliveries[index];
                  final addr = d.deliveryAddress;
                  final city = '${addr['city'] ?? addr['area'] ?? ''}';
                  final shortOrder = d.orderId.length > 8
                      ? d.orderId.substring(0, 8)
                      : d.orderId;

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    title: Text(
                      'Order #$shortOrder',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${Formatters.orderStatusLabel(d.status)}\n'
                      '${city.isEmpty ? 'Home delivery' : city} · '
                      'Rider: ${d.riderName ?? 'Unassigned'}\n'
                      'Assigned ${Formatters.dateTime(d.assignedAt)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'order':
                            context.go('/admin/orders/${d.orderId}');
                          case 'rider':
                            _assignRider(d);
                          case 'notes':
                            _editNotes(d);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'order',
                          child: Text('View order'),
                        ),
                        PopupMenuItem(
                          value: 'rider',
                          child: Text('Assign rider'),
                        ),
                        PopupMenuItem(
                          value: 'notes',
                          child: Text('Edit notes'),
                        ),
                      ],
                    ),
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
