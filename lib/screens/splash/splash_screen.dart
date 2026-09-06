import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/prefs_helper.dart';
import 'package:keychain_shop/widgets/brand_mark.dart';

/// Brand splash — routes to onboarding, login, or home after init.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1600));
    final auth = context.read<AuthProvider>();

    // Wait until auth stream has resolved at least once.
    while (!auth.initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    final onboarded = await PrefsHelper.isOnboardingComplete();
    await minDelay;
    if (!mounted) return;

    if (!onboarded) {
      context.go('/onboarding');
      return;
    }

    if (auth.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAF7F2),
              Color(0xFFF0E6D8),
              Color(0xFFE8D5C0),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandMark(size: 104, icon: Icons.key_rounded),
                const SizedBox(height: 28),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
