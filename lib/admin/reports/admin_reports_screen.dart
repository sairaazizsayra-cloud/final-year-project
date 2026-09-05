import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  AdminReportStats? _stats;
  bool _loading = true;
  String? _error;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await context.read<FirestoreService>().getAdminReportStats(
            from: _from,
            to: _to,
          );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[AdminReports] $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load reports.';
      });
    }
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (range == null) return;
    setState(() {
      _from = range.start;
      _to = range.end;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reports',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _from == null || _to == null
                      ? 'Date range'
                      : '${Formatters.date(_from!)} – ${Formatters.date(_to!)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on the latest orders in Firestore (max 500), filtered by date.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null || _stats == null)
            Center(
              child: Column(
                children: [
                  Text(_error ?? 'No data'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ReportCard(
                  label: 'Orders',
                  value: '${_stats!.totalOrders}',
                  icon: Icons.shopping_bag_outlined,
                ),
                _ReportCard(
                  label: 'Revenue',
                  value: Formatters.currency(_stats!.totalRevenue),
                  icon: Icons.payments_outlined,
                  color: AppColors.primaryDark,
                ),
                _ReportCard(
                  label: 'Delivered',
                  value: '${_stats!.deliveredOrders}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                _ReportCard(
                  label: 'Cancelled',
                  value: '${_stats!.cancelledOrders}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                ),
                _ReportCard(
                  label: 'COD',
                  value: '${_stats!.codOrders}',
                  icon: Icons.money_outlined,
                ),
                _ReportCard(
                  label: 'Online',
                  value: '${_stats!.onlineOrders}',
                  icon: Icons.credit_card_outlined,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Orders by status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (_stats!.statusCounts.isEmpty)
              const Text('No orders in this range.')
            else
              ...(_stats!.statusCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.circle,
                    size: 12,
                    color: Formatters.orderStatusColor(e.key),
                  ),
                  title: Text(Formatters.orderStatusLabel(e.key)),
                  trailing: Text(
                    '${e.value}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Top products',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (_stats!.topProducts.isEmpty)
              const Text('No product sales in this range.')
            else
              ..._stats!.topProducts.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: Text('${p.quantitySold} sold'),
                  trailing: Text(
                    Formatters.currency(p.revenue),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Recent in range',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ..._stats!.ordersInRange.take(12).map((o) {
              final short =
                  o.id.length > 8 ? o.id.substring(0, 8) : o.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('#$short · ${o.userName ?? 'Customer'}'),
                subtitle: Text(
                  '${Formatters.orderStatusLabel(o.orderStatus)} · '
                  '${Formatters.dateTime(o.createdAt)}',
                ),
                trailing: Text(Formatters.currency(o.totalAmount)),
                onTap: () => context.go('/admin/orders/${o.id}'),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
