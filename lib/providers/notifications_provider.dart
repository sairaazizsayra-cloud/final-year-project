import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:keychain_shop/models/notification_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';

/// In-app notifications from Firestore (FCM also writes here via Cloud Functions).
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;

  String? _userId;
  List<NotificationModel> _items = [];
  StreamSubscription<List<NotificationModel>>? _subscription;
  bool _loading = false;
  String? _error;

  List<NotificationModel> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  String? get error => _error;

  int get unreadCount => _items.where((n) => !n.isRead).length;

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _items = [];
    _error = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _subscription = _firestore.watchUserNotifications(userId).listen(
      (list) {
        _items = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[NotificationsProvider] $e');
        _loading = false;
        _error = 'Could not load notifications.';
        notifyListeners();
      },
    );
  }

  Future<void> markRead(String id) async {
    try {
      await _firestore.markNotificationRead(id);
    } catch (e) {
      debugPrint('[NotificationsProvider] markRead: $e');
    }
  }

  Future<void> markAllRead() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _firestore.markAllNotificationsRead(uid);
    } catch (e) {
      debugPrint('[NotificationsProvider] markAllRead: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.deleteNotification(id);
    } catch (e) {
      debugPrint('[NotificationsProvider] delete: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
