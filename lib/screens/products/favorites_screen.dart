import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/providers/favorites_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/widgets/product_grid.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: favorites.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : favorites.favoriteProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorites yet',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart on any keychain to save it here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        '${favorites.count} saved',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ProductGrid(products: favorites.favoriteProducts),
                  ],
                ),
    );
  }
}
