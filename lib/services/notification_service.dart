import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:keychain_shop/firebase_options.dart';

/// Background FCM handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint(
    '[FCM background] ${message.messageId} ${message.notification?.title}',
  );
}

/// Firebase Cloud Messaging + token sync helpers.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messagingOverride = messaging;

  final FirebaseMessaging? _messagingOverride;

  bool _initialized = false;
  void Function(String token)? onTokenRefresh;
  void Function(RemoteMessage message)? onForegroundMessage;
  void Function(RemoteMessage message)? onMessageOpened;

  bool get isInitialized => _initialized;

  /// FCM native plugin is not registered on Windows/Linux.
  static bool get isPlatformSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get _canUseMessaging =>
      isPlatformSupported && Firebase.apps.isNotEmpty;

  FirebaseMessaging? get _messaging {
    if (!_canUseMessaging) return null;
    return _messagingOverride ?? FirebaseMessaging.instance;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    final messaging = _messaging;
    if (messaging == null) {
      debugPrint('[NotificationService] FCM skipped on this platform');
      return;
    }

    try {
      // Background handler is registered from main() on mobile only.
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
        '[NotificationService] permission=${settings.authorizationStatus}',
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(
        (message) {
          debugPrint(
            '[NotificationService] foreground: ${message.notification?.title}',
          );
          onForegroundMessage?.call(message);
        },
        onError: (Object e) {
          debugPrint('[NotificationService] onMessage error: $e');
        },
      );

      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) {
          debugPrint(
            '[NotificationService] opened: ${message.notification?.title}',
          );
          onMessageOpened?.call(message);
        },
        onError: (Object e) {
          debugPrint('[NotificationService] onMessageOpenedApp error: $e');
        },
      );

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        onMessageOpened?.call(initial);
      }

      messaging.onTokenRefresh.listen(
        (token) {
          debugPrint('[NotificationService] token refresh');
          onTokenRefresh?.call(token);
        },
        onError: (Object e) {
          debugPrint('[NotificationService] token refresh error: $e');
        },
      );

      _initialized = true;
      debugPrint('[NotificationService] FCM initialized');
    } catch (e) {
      debugPrint('[NotificationService] init failed: $e');
    }
  }

  Future<String?> getToken() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      return await messaging.getToken();
    } catch (e) {
      debugPrint('[NotificationService] getToken failed: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      await messaging.subscribeToTopic(topic);
      debugPrint('[NotificationService] subscribed to $topic');
    } catch (e) {
      debugPrint('[NotificationService] subscribe failed: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      await messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('[NotificationService] unsubscribe failed: $e');
    }
  }
}
