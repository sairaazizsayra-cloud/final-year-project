import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/providers/cart_provider.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/section_header.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: cart.isMutating
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear cart?'),
                          content: const Text(
                            'Remove all items from your cart?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) await cart.clear();
                    },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : cart.isEmpty
              ? AppEmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty',
                  message:
                      'Add keychains to continue to home-to-home delivery checkout.',
                  actionLabel: 'Browse products',
                  onAction: () => context.go('/browse'),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartLine(
                            name: item.productName,
                            imageUrl: item.productImage,
                            unitPrice: item.unitPrice,
                            lineTotal: item.lineTotal,
                            quantity: item.quantity,
                            subtitle: [
                              if (item.selectedColor != null)
                                item.selectedColor!,
                              if (item.customText != null &&
                                  item.customText!.isNotEmpty)
                                '"${item.customText}"',
                            ].join(' · '),
                            onIncrement: () => cart.updateQuantity(
                              item.id,
                              item.quantity + 1,
                            ),
                            onDecrement: () => cart.updateQuantity(
                              item.id,
                              item.quantity - 1,
                            ),
                            onRemove: () => cart.removeItem(item.id),
                          );
                        },
                      ),
                    ),
                    _CartSummary(
                      subtotal: cart.subtotal,
                      delivery: cart.deliveryCharges,
                      total: cart.total,
                      onCheckout: () => context.pushOverlay('/checkout'),
                    ),
                  ],
                ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.lineTotal,
    required this.quantity,
    required this.subtitle,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final String name;
  final String? imageUrl;
  final double unitPrice;
  final double lineTotal;
  final int quantity;
  final String subtitle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceMuted,
                        child: const Icon(Icons.key),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.key, color: AppColors.primaryLight),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  Formatters.currency(unitPrice),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyButton(icon: Icons.remove, onTap: onDecrement),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _QtyButton(icon: Icons.add, onTap: onIncrement),
                    const Spacer(),
                    Text(
                      Formatters.currency(lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.subtotal,
    required this.delivery,
    required this.total,
    required this.onCheckout,
  });

  final double subtotal;
  final double delivery;
  final double total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.card,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _row(context, 'Subtotal', Formatters.currency(subtotal)),
            const SizedBox(height: 6),
            _row(
              context,
              'Delivery',
              delivery == 0 ? 'Free' : Formatters.currency(delivery),
            ),
            const Divider(height: 20),
            _row(
              context,
              'Total',
              Formatters.currency(total),
              bold: true,
            ),
            const SizedBox(height: 14),
            AppButton(label: 'Checkout', onPressed: onCheckout),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
