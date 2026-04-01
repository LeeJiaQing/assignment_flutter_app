// lib/features/notification/viewmodels/notification_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../models/notification_model.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationViewModel extends ChangeNotifier {
  NotificationStatus _status = NotificationStatus.initial;
  List<NotificationItem> _notifications = [];
  String? _errorMessage;

  NotificationStatus get status => _status;
  List<NotificationItem> get notifications => _notifications;
  String? get errorMessage => _errorMessage;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _status = NotificationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      _notifications = (response as List<dynamic>)
          .map((json) =>
          NotificationItem.fromJson(json as Map<String, dynamic>))
          .toList();
      _status = NotificationStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NotificationStatus.error;
    }

    notifyListeners();
  }
}
