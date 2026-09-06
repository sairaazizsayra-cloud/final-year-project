import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keychain_shop/admin/auth/admin_login_screen.dart';
import 'package:keychain_shop/admin/categories/admin_categories_screen.dart';
import 'package:keychain_shop/admin/coupons/admin_coupons_screen.dart';
import 'package:keychain_shop/admin/customers/admin_customers_screen.dart';
import 'package:keychain_shop/admin/dashboard/admin_dashboard_screen.dart';
import 'package:keychain_shop/admin/dashboard/admin_shell.dart';
import 'package:keychain_shop/admin/deliveries/admin_deliveries_screen.dart';
import 'package:keychain_shop/admin/orders/admin_order_detail_screen.dart';
import 'package:keychain_shop/admin/orders/admin_orders_screen.dart';
import 'package:keychain_shop/admin/products/admin_product_form_screen.dart';
import 'package:keychain_shop/admin/products/admin_products_screen.dart';
import 'package:keychain_shop/admin/reports/admin_reports_screen.dart';
import 'package:keychain_shop/admin/reviews/admin_reviews_screen.dart';
import 'package:keychain_shop/models/address_model.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/screens/auth/forgot_password_screen.dart';
import 'package:keychain_shop/screens/auth/login_screen.dart';
import 'package:keychain_shop/screens/auth/signup_screen.dart';
import 'package:keychain_shop/screens/checkout/address_form_screen.dart';
import 'package:keychain_shop/screens/checkout/addresses_screen.dart';
import 'package:keychain_shop/screens/checkout/checkout_screen.dart';
import 'package:keychain_shop/screens/checkout/order_success_screen.dart';
import 'package:keychain_shop/screens/home/main_shell.dart';
import 'package:keychain_shop/screens/onboarding/onboarding_screen.dart';
import 'package:keychain_shop/screens/orders/order_detail_screen.dart';
import 'package:keychain_shop/screens/orders/orders_screen.dart';
import 'package:keychain_shop/screens/products/favorites_screen.dart';
import 'package:keychain_shop/screens/products/product_detail_screen.dart';
import 'package:keychain_shop/screens/products/product_list_screen.dart';
import 'package:keychain_shop/screens/products/search_screen.dart';
import 'package:keychain_shop/screens/profile/notifications_screen.dart';
import 'package:keychain_shop/screens/splash/splash_screen.dart';
import 'package:keychain_shop/utils/product_filters.dart';

/// Navigator keys owned by the single [GoRouter] instance.
class AppNavigatorKeys {
  AppNavigatorKeys();

  final GlobalKey<NavigatorState> root =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  final GlobalKey<NavigatorState> adminShell =
      GlobalKey<NavigatorState>(debugLabel: 'adminShell');
}

/// Application routes powered by go_router.
class AppRouter {
  AppRouter._();

  static const home = '/home';
  static const browse = '/browse';
  static const cart = '/cart';
  static const profile = '/profile';

  static ProductSection _parseSection(String? value) {
    return ProductSection.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ProductSection.all,
    );
  }

  /// Full-screen customer routes nested under a tab so `parentNavigatorKey`
  /// is legal (must be a descendant of the branch, not a sibling of the shell).
  static List<RouteBase> _tabOverlayRoutes(AppNavigatorKeys keys) {
    return [
      GoRoute(
        path: 'search',
        parentNavigatorKey: keys.root,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: 'favorites',
        parentNavigatorKey: keys.root,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: 'products',
        parentNavigatorKey: keys.root,
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final title = state.uri.queryParameters['title'];
          final section = _parseSection(
            state.uri.queryParameters['section'],
          );
          return ProductListScreen(
            categoryId: categoryId,
            title: title,
            section: section,
          );
        },
      ),
      GoRoute(
        path: 'products/:id',
        parentNavigatorKey: keys.root,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: 'checkout',
        parentNavigatorKey: keys.root,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: 'order-success/:orderId',
        parentNavigatorKey: keys.root,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderSuccessScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: 'orders',
        parentNavigatorKey: keys.root,
        builder: (context, state) {
          final tab = int.tryParse(
                state.uri.queryParameters['tab'] ?? '0',
              ) ??
              0;
          return OrdersScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: 'orders/:id',
        parentNavigatorKey: keys.root,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: 'notifications',
        parentNavigatorKey: keys.root,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: 'addresses',
        parentNavigatorKey: keys.root,
        builder: (context, state) {
          final select = state.uri.queryParameters['select'] == '1';
          return AddressesScreen(selectMode: select);
        },
        routes: [
          GoRoute(
            path: 'form',
            parentNavigatorKey: keys.root,
            builder: (context, state) {
              final existing = state.extra is AddressModel
                  ? state.extra as AddressModel
                  : null;
              return AddressFormScreen(existing: existing);
            },
          ),
        ],
      ),
    ];
  }

  static GoRouter create(AuthProvider auth, AppNavigatorKeys keys) {
    return GoRouter(
      navigatorKey: keys.root,
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final path = state.matchedLocation;
        final isAuth = auth.isAuthenticated;
        final authReady = auth.initialized;
        final isAdmin = auth.isAdmin;
        final isAdminPath = path.startsWith('/admin');
        final isAdminLogin = path == '/admin/login';

        if (path == '/splash' || !authReady) return null;

        final isPublicAuthRoute = path == '/login' ||
            path == '/signup' ||
            path == '/forgot-password' ||
            path == '/onboarding' ||
            isAdminLogin;

        if (!isAuth && !isPublicAuthRoute) {
          return isAdminPath ? '/admin/login' : '/login';
        }

        if (isAuth && isAdminLogin) {
          return isAdmin ? '/admin' : '/home';
        }

        if (isAuth &&
            (path == '/login' ||
                path == '/signup' ||
                path == '/forgot-password')) {
          return isAdmin ? '/admin' : '/home';
        }

        if (isAuth && isAdminPath && !isAdminLogin && !isAdmin) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        ShellRoute(
          navigatorKey: keys.adminShell,
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            // Nest fullscreen form under products so parentNavigatorKey can
            // target the root navigator (direct ShellRoute children cannot).
            GoRoute(
              path: '/admin/products',
              builder: (context, state) => const AdminProductsScreen(),
              routes: [
                GoRoute(
                  path: 'form',
                  parentNavigatorKey: keys.root,
                  builder: (context, state) {
                    final existing = state.extra is ProductModel
                        ? state.extra as ProductModel
                        : null;
                    return AdminProductFormScreen(existing: existing);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/admin/categories',
              builder: (context, state) => const AdminCategoriesScreen(),
            ),
            GoRoute(
              path: '/admin/customers',
              builder: (context, state) => const AdminCustomersScreen(),
            ),
            GoRoute(
              path: '/admin/orders',
              builder: (context, state) => const AdminOrdersScreen(),
            ),
            GoRoute(
              path: '/admin/orders/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AdminOrderDetailScreen(orderId: id);
              },
            ),
            GoRoute(
              path: '/admin/deliveries',
              builder: (context, state) => const AdminDeliveriesScreen(),
            ),
            GoRoute(
              path: '/admin/reviews',
              builder: (context, state) => const AdminReviewsScreen(),
            ),
            GoRoute(
              path: '/admin/coupons',
              builder: (context, state) => const AdminCouponsScreen(),
            ),
            GoRoute(
              path: '/admin/reports',
              builder: (context, state) => const AdminReportsScreen(),
            ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: home,
                  builder: (context, state) => const HomeBranch(),
                  routes: _tabOverlayRoutes(keys),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: browse,
                  builder: (context, state) => const BrowseBranch(),
                  routes: _tabOverlayRoutes(keys),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: cart,
                  builder: (context, state) => const CartBranch(),
                  routes: _tabOverlayRoutes(keys),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: profile,
                  builder: (context, state) => const ProfileBranch(),
                  routes: _tabOverlayRoutes(keys),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Pushes full-screen customer routes onto the current tab branch.
///
/// Overlay paths must be nested under the shell (not siblings). Pushing a
/// sibling overlay made go_router insert the shell twice and triggered
/// `!keyReservation.contains(key)` on add-to-cart / checkout.
extension AppOverlayNav on BuildContext {
  String get shellPrefix {
    final loc = GoRouterState.of(this).matchedLocation;
    if (loc.startsWith(AppRouter.browse)) return AppRouter.browse;
    if (loc.startsWith(AppRouter.cart)) return AppRouter.cart;
    if (loc.startsWith(AppRouter.profile)) return AppRouter.profile;
    return AppRouter.home;
  }

  Future<T?> pushOverlay<T extends Object?>(
    String overlayPath, {
    Object? extra,
  }) {
    assert(overlayPath.startsWith('/'), 'overlayPath must start with /');
    return push<T>('$shellPrefix$overlayPath', extra: extra);
  }

  void goOverlay(String overlayPath, {Object? extra}) {
    assert(overlayPath.startsWith('/'), 'overlayPath must start with /');
    go('$shellPrefix$overlayPath', extra: extra);
  }
}
