import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background FCM handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    '[FCM background] ${message.messageId} ${message.notification?.title}',
  );
}

/// Firebase Cloud Messaging + token sync helpers.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  bool _initialized = false;
  void Function(String token)? onTokenRefresh;
  void Function(RemoteMessage message)? onForegroundMessage;
  void Function(RemoteMessage message)? onMessageOpened;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) {
      debugPrint('[NotificationService] Firebase not ready');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
        '[NotificationService] permission=${settings.authorizationStatus}',
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          '[NotificationService] foreground: ${message.notification?.title}',
        );
        onForegroundMessage?.call(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint(
          '[NotificationService] opened: ${message.notification?.title}',
        );
        onMessageOpened?.call(message);
      });

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        onMessageOpened?.call(initial);
      }

      _messaging.onTokenRefresh.listen((token) {
        debugPrint('[NotificationService] token refresh');
        onTokenRefresh?.call(token);
      });

      _initialized = true;
      debugPrint('[NotificationService] FCM initialized');
    } catch (e) {
      debugPrint('[NotificationService] init failed: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[NotificationService] getToken failed: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[NotificationService] subscribed to $topic');
    } catch (e) {
      debugPrint('[NotificationService] subscribe failed: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('[NotificationService] unsubscribe failed: $e');
    }
  }
}
