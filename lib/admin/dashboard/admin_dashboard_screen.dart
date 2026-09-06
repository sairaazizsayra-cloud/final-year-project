import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminDashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats =
          await context.read<FirestoreService>().getAdminDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[AdminDashboard] $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load dashboard. Check admin Firestore rules.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null || _stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error ?? 'No data'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final s = _stats!;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Store overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders, catalog, and revenue at a glance.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                label: 'Products',
                value: '${s.totalProducts}',
                icon: Icons.key_outlined,
                onTap: () => context.go('/admin/products'),
              ),
              _StatCard(
                label: 'Customers',
                value: '${s.totalCustomers}',
                icon: Icons.people_outline,
                onTap: () => context.go('/admin/customers'),
              ),
              _StatCard(
                label: 'Orders',
                value: '${s.totalOrders}',
                icon: Icons.shopping_bag_outlined,
                onTap: () => context.go('/admin/orders'),
              ),
              _StatCard(
                label: 'Pending',
                value: '${s.pendingOrders}',
                icon: Icons.hourglass_empty,
                color: AppColors.warning,
                onTap: () => context.go('/admin/orders'),
              ),
              _StatCard(
                label: 'Completed',
                value: '${s.completedOrders}',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                onTap: () => context.go('/admin/orders'),
              ),
              _StatCard(
                label: 'Cancelled',
                value: '${s.cancelledOrders}',
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                onTap: () => context.go('/admin/orders'),
              ),
              _StatCard(
                label: 'Revenue',
                value: Formatters.currency(s.totalRevenue),
                icon: Icons.payments_outlined,
                color: AppColors.primaryDark,
                onTap: () => context.go('/admin/reports'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Recent orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (s.recentOrders.isEmpty)
            const Text('No orders yet.')
          else
            ...s.recentOrders.map((o) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '#${o.id.length > 8 ? o.id.substring(0, 8) : o.id}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${Formatters.orderStatusLabel(o.orderStatus)} · ${Formatters.dateTime(o.createdAt)}',
                ),
                trailing: Text(
                  Formatters.currency(o.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => context.go('/admin/orders/${o.id}'),
              );
            }),
          const SizedBox(height: 24),
          Text(
            'Best selling products',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (s.bestSellingProducts.isEmpty)
            const Text('Mark products as best sellers to show them here.')
          else
            ...s.bestSellingProducts.map((p) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p.name),
                subtitle: Text('Stock: ${p.stock}'),
                trailing: Text(Formatters.currency(p.discountedPrice)),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
