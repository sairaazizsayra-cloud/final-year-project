import 'package:flutter/material.dart';

import 'package:keychain_shop/theme/app_theme.dart';

/// Brass key mark used on splash, auth, and branded empty states.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 56,
    this.icon = Icons.key_rounded,
    this.color,
    this.iconColor,
  });

  final double size;
  final IconData icon;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.32),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: iconColor ?? Colors.white,
      ),
    );
  }
}
