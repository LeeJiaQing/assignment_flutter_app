// lib/features/notification/viewmodels/notification_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/local/local_notification_cache.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../models/notification_model.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationViewModel extends ChangeNotifier {
  NotificationStatus _status = NotificationStatus.initial;
  List<NotificationItem> _notifications = [];
  String? _errorMessage;

  final LocalNotificationCache _cache = LocalNotificationCache();

  NotificationStatus get status => _status;
  List<NotificationItem> get notifications => _notifications;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _status = NotificationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _notifications = [];
      _status = NotificationStatus.loaded;
      notifyListeners();
      return;
    }

    try {
      if (ConnectivityService.instance.isOnline) {
        final rows = await NotificationService.instance.fetchMyNotifications();
        _notifications = rows.map((j) => NotificationItem.fromJson(j)).toList();
        await _cache.saveNotifications(userId: userId, rows: rows);
        _status = NotificationStatus.loaded;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Fall back to cache
    }

    try {
      final rows = await _cache.getNotifications(userId: userId, ignoreExpiry: true);
      _notifications = rows.map((j) => NotificationItem.fromJson(j)).toList();
      _status = NotificationStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NotificationStatus.error;
    }

    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final userId = supabase.auth.currentUser?.id;

    _notifications = _notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();

    if (userId != null) {
      await _cache.markRead(userId: userId, notificationId: id);
    }

    if (ConnectivityService.instance.isOnline) {
      await NotificationService.instance.markRead(id);
    }
  }

  Future<void> markAllRead() async {
    final userId = supabase.auth.currentUser?.id;

    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    if (userId != null) {
      await _cache.markAllRead(userId: userId);
    }

    if (ConnectivityService.instance.isOnline) {
      await NotificationService.instance.markAllRead();
    }
  }
}
