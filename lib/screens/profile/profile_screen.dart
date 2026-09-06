import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/providers/favorites_provider.dart';
import 'package:keychain_shop/providers/notifications_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/widgets/app_button.dart';

/// Basic profile tab for Phase 2 (full profile module in Phase 5).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final unread = context.watch<NotificationsProvider>().unreadCount;
    final favCount = context.watch<FavoritesProvider>().count;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C3E50),
                  Color(0xFF8B5A2B),
                ],
              ),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  child: Text(
                    (user?.name.isNotEmpty == true)
                        ? user!.name.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Guest',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appTagline,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Orders',
                  subtitle: 'Track home-to-home delivery',
                  onTap: () => context.push('/orders'),
                ),
                const Divider(height: 1, indent: 72),
                _ProfileTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle:
                      unread > 0 ? '$unread unread' : 'Order updates & offers',
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1, indent: 72),
                _ProfileTile(
                  icon: Icons.favorite_border,
                  title: 'Favorites',
                  subtitle: '$favCount saved',
                  onTap: () => context.push('/favorites'),
                ),
                const Divider(height: 1, indent: 72),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: 'Home-to-home delivery addresses',
                  onTap: () => context.push('/addresses'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQ & contact',
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Help & Support'),
                        content: const Text(
                          'For order issues, open the order detail and check tracking.\n\n'
                          'Email: support@keychainshop.local\n'
                          'Home-to-home delivery usually takes 2–4 days.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 72),
                _ProfileTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: '${AppConstants.appName} · v1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Final Year Project — Flutter + Firebase.',
                      children: const [
                        SizedBox(height: 12),
                        Text(AppConstants.appTagline),
                      ],
                    );
                  },
                ),
                if (auth.isAdmin) ...[
                  const Divider(height: 1, indent: 72),
                  _ProfileTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin panel',
                    subtitle: 'Manage store',
                    onTap: () => context.go('/admin'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Logout',
            isOutlined: true,
            icon: Icons.logout,
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
