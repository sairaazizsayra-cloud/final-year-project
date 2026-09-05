import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/providers/cart_provider.dart';
import 'package:keychain_shop/screens/cart/cart_screen.dart';
import 'package:keychain_shop/screens/home/home_screen.dart';
import 'package:keychain_shop/screens/products/browse_screen.dart';
import 'package:keychain_shop/screens/profile/profile_screen.dart';
import 'package:keychain_shop/theme/app_theme.dart';

/// Bottom navigation shell for the customer app.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.35),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeBranch extends StatelessWidget {
  const HomeBranch({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class BrowseBranch extends StatelessWidget {
  const BrowseBranch({super.key});

  @override
  Widget build(BuildContext context) => const BrowseScreen();
}

class CartBranch extends StatelessWidget {
  const CartBranch({super.key});

  @override
  Widget build(BuildContext context) => const CartScreen();
}

class ProfileBranch extends StatelessWidget {
  const ProfileBranch({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
