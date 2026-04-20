// lib/core/services/notification_service.dart
//
// Handles:
//  - Device push token registration / refresh
//  - Scheduling in-app booking reminders (1 h before slot)
//  - Inserting user_notifications rows directly when needed
//
// Push delivery is handled server-side via Supabase
// triggered by the notify_announcement_targets() / notify_party_joined()
// database functions. This file only manages the client side.

import 'package:flutter/foundation.dart';

import '../supabase/supabase_config.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ── Push token (Supabase-only) ────────────────────────────────────────────

  /// Call this after the user signs in and when a new push token is available.
  /// The app stores whatever token the caller provides.
  Future<void> registerToken(String token,
      {String platform = 'android'}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, token',
      );
    } catch (e) {
      debugPrint('NotificationService.registerToken error: $e');
    }
  }

  /// Remove this device's token on sign-out.
  Future<void> unregisterToken(String token) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', token);
    } catch (e) {
      debugPrint('NotificationService.unregisterToken error: $e');
    }
  }

  // ── In-app notifications ───────────────────────────────────────────────────

  /// Fetch all user_notifications for the signed-in user.
  Future<List<Map<String, dynamic>>> fetchMyNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('user_notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final rawRows = List<Map<String, dynamic>>.from(response as List);
    if (rawRows.isEmpty) return rawRows;

    final announcementIds = rawRows
        .where((row) => row['type'] == 'announcement')
        .map(_announcementIdFromRow)
        .whereType<String>()
        .toSet();

    final activeAnnouncements = <String, Map<String, dynamic>>{};
    if (announcementIds.isNotEmpty) {
      final announcements = await supabase
          .from('announcements')
          .select('id,title,body')
          .inFilter('id', announcementIds.toList());
      for (final item
          in List<Map<String, dynamic>>.from(announcements as List)) {
        final id = item['id']?.toString();
        if (id != null) activeAnnouncements[id] = item;
      }
    }

    final deduped = <String, Map<String, dynamic>>{};
    for (final row in rawRows) {
      if (row['type'] == 'announcement') {
        final announcementId = _announcementIdFromRow(row);
        if (announcementId == null) {
          // Ignore malformed/legacy announcement notifications that cannot be
          // reconciled with the announcements table.
          continue;
        }

        final active = activeAnnouncements[announcementId];
        if (active == null) {
          // Parent announcement was deleted by admin.
          continue;
        }
        row['title'] = active['title'] ?? row['title'];
        row['body'] = active['body'] ?? row['body'];
        final key = 'announcement:$announcementId';
        final existing = deduped[key];
        if (existing == null || _createdAt(existing).isBefore(_createdAt(row))) {
          deduped[key] = row;
        }
        continue;
      }

      deduped['notification:${row['id']}'] = row;
    }

    final cleaned = deduped.values.toList()
      ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
    return cleaned;
  }

  /// Mark a single notification as read.
  Future<void> markRead(String notificationId) async {
    await supabase
        .from('user_notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read for this user.
  Future<void> markAllRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('user_notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Schedule a booking reminder by inserting a user_notification row
  /// immediately (the reminder about an upcoming slot).
  /// In a production app this would be triggered server-side 1 h before.
  Future<void> scheduleBookingReminder({
    required String bookingId,
    required String facilityName,
    required DateTime slotStart,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Only schedule if the slot is in the future
      if (slotStart.isBefore(DateTime.now())) return;

      await supabase.from('user_notifications').insert({
        'user_id': userId,
        'type': 'booking_reminder',
        'title': '⏰ Upcoming Booking',
        'body': 'Your court at $facilityName starts at ${_fmtTime(slotStart)}. '
            'Get ready!',
        'data': {'booking_id': bookingId},
        'is_read': false,
      });
    } catch (e) {
      debugPrint('NotificationService.scheduleBookingReminder: $e');
    }
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour;
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  String? _announcementIdFromRow(Map<String, dynamic> row) {
    final data = row['data'];
    if (data is! Map) return null;
    final id = data['announcement_id'];
    return id?.toString();
  }

  DateTime _createdAt(Map<String, dynamic> row) {
    final createdAt = row['created_at']?.toString();
    return DateTime.tryParse(createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
