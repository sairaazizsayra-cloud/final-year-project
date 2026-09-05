import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/providers/favorites_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

/// Product tile for carousels and grids.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.width = 160,
    this.showFavorite = true,
  });

  final ProductModel product;
  final double width;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(product.id);

    return InkWell(
      onTap: () => context.push('/products/${product.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.primaryImage != null)
                      CachedNetworkImage(
                        imageUrl: product.primaryImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.surfaceMuted),
                        errorWidget: (context, url, error) =>
                            const _ImageFallback(),
                      )
                    else
                      const _ImageFallback(),
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.discount.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (showFavorite)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 20,
                            onPressed: () => favorites.toggle(product.id),
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        Formatters.currency(product.discountedPrice),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Formatters.currency(product.price),
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.textHint,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Icon(Icons.key, size: 40, color: AppColors.primaryLight),
    );
  }
}
