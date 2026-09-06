import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/prefs_helper.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/brand_mark.dart';

class _OnboardPage {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const _pages = [
  _OnboardPage(
    icon: Icons.key_outlined,
    title: 'Custom Keychains',
    subtitle:
        'Browse premium and customizable keychains crafted for every style.',
  ),
  _OnboardPage(
    icon: Icons.palette_outlined,
    title: 'Make It Yours',
    subtitle:
        'Add names, colors, and personal designs — your keychain, your way.',
  ),
  _OnboardPage(
    icon: Icons.home_outlined,
    title: 'Home-to-Home Delivery',
    subtitle:
        'Order online and get your keychains delivered safely to your door.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await PrefsHelper.setOnboardingComplete();
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E6D6),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BrandMark(size: 148, icon: p.icon),
                          const SizedBox(height: 40),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            p.subtitle,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: AppButton(
                  label: isLast ? 'Get Started' : 'Next',
                  onPressed: _next,
                  icon: isLast ? Icons.arrow_forward : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
