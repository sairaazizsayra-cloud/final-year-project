import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/firebase_options.dart';
import 'package:keychain_shop/providers/address_provider.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/providers/cart_provider.dart';
import 'package:keychain_shop/providers/favorites_provider.dart';
import 'package:keychain_shop/providers/notifications_provider.dart';
import 'package:keychain_shop/providers/orders_provider.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/services/admin_functions_service.dart';
import 'package:keychain_shop/services/auth_service.dart';
import 'package:keychain_shop/services/coupon_service.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/services/notification_service.dart';
import 'package:keychain_shop/services/payment_service.dart';
import 'package:keychain_shop/services/storage_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[main] Firebase initialized');
  } catch (e, st) {
    debugPrint('[main] Firebase init failed: $e');
    debugPrint('$st');
  }

  runApp(const KeychainShopApp());
}

class KeychainShopApp extends StatelessWidget {
  const KeychainShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<PaymentService>(create: (_) => PaymentService()),
        Provider<AdminFunctionsService>(create: (_) => AdminFunctionsService()),
        Provider<CouponService>(create: (_) => CouponService()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider2<
          FirestoreService,
          AuthProvider,
          FavoritesProvider
        >(
          create: (context) => FavoritesProvider(
            firestoreService: context.read<FirestoreService>(),
          ),
          update: (context, firestore, auth, previous) {
            final provider =
                previous ?? FavoritesProvider(firestoreService: firestore);
            provider.bindUser(auth.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<
          FirestoreService,
          AuthProvider,
          CartProvider
        >(
          create: (context) =>
              CartProvider(firestoreService: context.read<FirestoreService>()),
          update: (context, firestore, auth, previous) {
            final provider =
                previous ?? CartProvider(firestoreService: firestore);
            provider.bindUser(auth.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<
          FirestoreService,
          AuthProvider,
          AddressProvider
        >(
          create: (context) => AddressProvider(
            firestoreService: context.read<FirestoreService>(),
          ),
          update: (context, firestore, auth, previous) {
            final provider =
                previous ?? AddressProvider(firestoreService: firestore);
            provider.bindUser(auth.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<
          FirestoreService,
          AuthProvider,
          OrdersProvider
        >(
          create: (context) => OrdersProvider(
            firestoreService: context.read<FirestoreService>(),
          ),
          update: (context, firestore, auth, previous) {
            final provider =
                previous ?? OrdersProvider(firestoreService: firestore);
            provider.bindUser(auth.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<
          FirestoreService,
          AuthProvider,
          NotificationsProvider
        >(
          create: (context) => NotificationsProvider(
            firestoreService: context.read<FirestoreService>(),
          ),
          update: (context, firestore, auth, previous) {
            final provider =
                previous ?? NotificationsProvider(firestoreService: firestore);
            provider.bindUser(auth.user?.id);
            return provider;
          },
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  GoRouter? _router;
  bool _fcmReady = false;
  String? _syncedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.create(context.read<AuthProvider>());
    if (!_fcmReady) {
      _fcmReady = true;
      _bootstrapFcm();
    }
    _syncFcmTokenIfNeeded();
  }

  Future<void> _bootstrapFcm() async {
    final notifications = context.read<NotificationService>();
    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    notifications.onTokenRefresh = (token) {
      final uid = context.read<AuthProvider>().user?.id;
      if (uid != null) {
        authService.updateFcmToken(uid, token);
      }
    };

    notifications.onForegroundMessage = (RemoteMessage message) {
      final title = message.notification?.title ?? 'Keychain Shop';
      final body = message.notification?.body ?? '';
      messenger?.showSnackBar(
        SnackBar(content: Text(body.isEmpty ? title : '$title — $body')),
      );
    };

    notifications.onMessageOpened = (RemoteMessage message) {
      final orderId = message.data['orderId'];
      if (orderId != null && orderId.toString().isNotEmpty) {
        _router?.go('/orders/$orderId');
      } else {
        _router?.go('/notifications');
      }
    };

    await notifications.initialize();
    await notifications.subscribeToTopic('all_customers');
    if (mounted) _syncFcmTokenIfNeeded();
  }

  Future<void> _syncFcmTokenIfNeeded() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      _syncedUserId = null;
      return;
    }
    if (_syncedUserId == user.id) return;
    _syncedUserId = user.id;

    final authService = context.read<AuthService>();
    final notificationService = context.read<NotificationService>();
    final token = await notificationService.getToken();
    if (token != null) {
      try {
        await authService.updateFcmToken(user.id, token);
      } catch (e) {
        debugPrint('[main] FCM token sync failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when auth changes so token sync runs for new sessions.
    context.watch<AuthProvider>();

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router!,
    );
  }
}
