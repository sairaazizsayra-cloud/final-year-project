import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';

/// Admin navigation shell with a side rail on wide screens / drawer on narrow.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (path: '/admin', label: 'Dashboard', icon: Icons.dashboard_outlined),
    (path: '/admin/orders', label: 'Orders', icon: Icons.receipt_long_outlined),
    (
      path: '/admin/deliveries',
      label: 'Deliveries',
      icon: Icons.local_shipping_outlined,
    ),
    (path: '/admin/products', label: 'Products', icon: Icons.key_outlined),
    (
      path: '/admin/categories',
      label: 'Categories',
      icon: Icons.category_outlined,
    ),
    (path: '/admin/customers', label: 'Customers', icon: Icons.people_outline),
    (path: '/admin/reviews', label: 'Reviews', icon: Icons.star_outline),
    (path: '/admin/coupons', label: 'Coupons', icon: Icons.local_offer_outlined),
    (path: '/admin/reports', label: 'Reports', icon: Icons.bar_chart_outlined),
  ];

  int _selectedIndex(String location) {
    if (location.startsWith('/admin/orders')) return 1;
    if (location.startsWith('/admin/deliveries')) return 2;
    if (location.startsWith('/admin/products')) return 3;
    if (location.startsWith('/admin/categories')) return 4;
    if (location.startsWith('/admin/customers')) return 5;
    if (location.startsWith('/admin/reviews')) return 6;
    if (location.startsWith('/admin/coupons')) return 7;
    if (location.startsWith('/admin/reports')) return 8;
    return 0;
  }

  Widget _navList(BuildContext context, int index, {VoidCallback? onTapItem}) {
    return ListView(
      children: [
        for (var i = 0; i < _destinations.length; i++)
          ListTile(
            leading: Icon(_destinations[i].icon),
            title: Text(_destinations[i].label),
            selected: i == index,
            selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.25),
            onTap: () {
              onTapItem?.call();
              context.go(_destinations[i].path);
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _selectedIndex(location);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keychain Shop Admin'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Customer app'),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) context.go('/admin/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DrawerHeader(
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _navList(
                        context,
                        index,
                        onTapItem: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 220,
              child: Material(
                color: AppColors.surface,
                child: _navList(context, index),
              ),
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
