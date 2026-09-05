import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/widgets/app_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order placed!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your keychains are on the way via home-to-home delivery. '
                'Track status anytime from My Orders.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Order ID',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      orderId,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Track order',
                onPressed: () => context.go('/orders/$orderId'),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Continue shopping',
                isOutlined: true,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'My orders',
                isOutlined: true,
                onPressed: () => context.go('/orders'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
