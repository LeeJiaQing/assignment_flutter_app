// lib/core/services/notification_service.dart
//
// Handles:
//  - FCM device token registration / refresh
//  - Scheduling in-app booking reminders (1 h before slot)
//  - Inserting user_notifications rows directly when needed
//
// Push delivery (FCM) is handled server-side via a Supabase Edge Function
// triggered by the notify_announcement_targets() / notify_party_joined()
// database functions. This file only manages the client side.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';

import '../../features/notification/notification_detail_screen.dart';
import '../../models/notification_model.dart';
import 'navigation_service.dart';
import '../supabase/supabase_config.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _pushInitialized = false;

  Future<void> initPushNotifications() async {
    if (_pushInitialized || kIsWeb) return;
    _pushInitialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('NotificationService.initPushNotifications Firebase init: $e');
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _openNotificationDetail(_notificationFromPayload(payload));
      },
    );

    const channel = AndroidNotificationChannel(
      'courtnow_notifications',
      'CourtNow Notifications',
      description: 'Announcements, booking reminders, and party updates.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await syncTokenForCurrentUser();

    _messaging.onTokenRefresh.listen(
      (token) => registerToken(token, platform: defaultTargetPlatform.name),
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> syncTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await registerToken(token, platform: defaultTargetPlatform.name);
  }

  // ── FCM Token ──────────────────────────────────────────────────────────────

  /// Call this after the user signs in and after Firebase gives a new token.
  /// On Android/iOS this integrates with firebase_messaging; here we store
  /// whatever token the caller provides (or a stub in debug).
  Future<void> registerToken(String token,
      {String platform = 'android'}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('fcm_tokens').upsert(
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
          .from('fcm_tokens')
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

    return List<Map<String, dynamic>>.from(response as List);
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
        'body':
        'Your court at $facilityName starts at ${_fmtTime(slotStart)}. Get ready!',
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

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final payload = _notificationPayloadFromMessage(message);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? payload['title'] as String?,
      message.notification?.body ?? payload['body'] as String?,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'courtnow_notifications',
          'CourtNow Notifications',
          channelDescription:
              'Announcements, booking reminders, and party updates.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final payload = _notificationPayloadFromMessage(message);
    final item = NotificationItem(
      id: payload['id'] as String,
      title: payload['title'] as String,
      body: payload['body'] as String,
      createdAt: DateTime.parse(payload['created_at'] as String),
      isRead: false,
      type: NotificationType.fromString(payload['type'] as String),
      data: {
        if (payload['long_body'] != null) 'long_body': payload['long_body'],
      },
    );
    _openNotificationDetail(item);
  }

  Map<String, dynamic> _notificationPayloadFromMessage(RemoteMessage message) {
    final data = message.data;
    final now = DateTime.now().toIso8601String();
    return {
      'id': data['id'] ?? data['notification_id'] ?? now,
      'title': data['title'] ?? message.notification?.title ?? 'Notification',
      'body': data['body'] ?? message.notification?.body ?? '',
      'long_body': data['long_body'],
      'type': data['type'] ?? 'announcement',
      'created_at': data['created_at'] ?? now,
    };
  }

  NotificationItem _notificationFromPayload(String payloadText) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(payloadText) as Map<String, dynamic>;
    } catch (_) {
      decoded = const {};
    }

    final createdAt = DateTime.tryParse((decoded['created_at'] ?? '') as String) ??
        DateTime.now();
    final longBody = decoded['long_body'] as String?;

    return NotificationItem(
      id: (decoded['id'] as String?) ?? createdAt.toIso8601String(),
      title: (decoded['title'] as String?) ?? 'Notification',
      body: (decoded['body'] as String?) ?? '',
      createdAt: createdAt,
      type: NotificationType.fromString((decoded['type'] as String?) ?? ''),
      data: {
        if (longBody != null && longBody.isNotEmpty) 'long_body': longBody,
      },
    );
  }

  void _openNotificationDetail(NotificationItem item) {
    final navigator = NavigationService.instance.navigator;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(item: item),
      ),
    );
  }
}
