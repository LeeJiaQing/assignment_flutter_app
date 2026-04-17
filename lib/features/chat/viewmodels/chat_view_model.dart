// lib/features/chat/viewmodels/chat_view_model.dart
//
// Strategy:
//  • Optimistic insert: sender sees message instantly.
//  • After insert: reload from server to get real ID + senderName.
//  • 5-second poll keeps all participants in sync without needing
//    Supabase Realtime to be enabled on the messages table.
//  • Real-time subscription attempted as bonus; ignored if unavailable.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  bool get isMe => senderId == supabase.auth.currentUser?.id;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    senderId: json['sender_id'] as String,
    senderName:
    (json['profiles'] as Map?)?['full_name'] as String? ?? 'User',
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({required this.channelId});

  final String channelId;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  RealtimeChannel? _realtimeChannel;
  Timer? _pollTimer;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ── Initial load ───────────────────────────────────────────────────────────

  Future<void> loadMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _fetchMessages();

    _isLoading = false;
    notifyListeners();

    _subscribeRealtime();
    _startPolling();
  }

  // ── Fetch (merge, no flicker) ──────────────────────────────────────────────

  Future<void> _fetchMessages() async {
    try {
      final response = await supabase
          .from('messages')
          .select('*, profiles(full_name)')
          .eq('channel_id', channelId)
          .order('created_at', ascending: true);

      final fetched = (response as List<dynamic>)
          .map((json) =>
          ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      // Rebuild list from server truth, removing optimistic placeholders.
      _messages
        ..removeWhere((m) => m.id.startsWith('optimistic_'))
        ..clear();
      _messages.addAll(fetched);
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // ── Real-time (best-effort) ────────────────────────────────────────────────

  void _subscribeRealtime() {
    _realtimeChannel?.unsubscribe();
    try {
      _realtimeChannel = supabase
          .channel('chat_$channelId')
          .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'channel_id',
          value: channelId,
        ),
        callback: (_) async {
          await _fetchMessages();
          notifyListeners();
        },
      )
          .subscribe();
    } catch (_) {
      // Real-time unavailable — polling covers updates.
    }
  }

  // ── Poll every 5 s ─────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _fetchMessages();
      notifyListeners();
    });
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'You must be signed in to send messages.';
      notifyListeners();
      return;
    }

    // Optimistic: show message right away.
    final optimisticId =
        'optimistic_${DateTime.now().millisecondsSinceEpoch}';
    _messages.add(ChatMessage(
      id: optimisticId,
      senderId: userId,
      senderName: 'You',
      content: trimmed,
      createdAt: DateTime.now(),
    ));
    notifyListeners();

    try {
      await supabase.from('messages').insert({
        'channel_id': channelId,
        'sender_id': userId,
        'content': trimmed,
      });
      // Replace optimistic with real server data.
      await _fetchMessages();
      notifyListeners();
    } catch (e) {
      _messages.removeWhere((m) => m.id == optimisticId);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}