// lib/features/chat/viewmodels/chat_view_model.dart
//
// Strategy:
//  • Optimistic insert: sender sees message instantly.
//  • After every send: reload from server to confirm with real row + senderName.
//  • 5-second poll keeps all participants in sync (no Realtime dependency).
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // The join is: messages join profiles on sender_id = profiles.id
    // Supabase returns the joined row as json['profiles'] => {'full_name': '...'}
    final profileName =
    (json['profiles'] as Map<String, dynamic>?)?['full_name'] as String?;
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderName: profileName ?? 'User',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
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

  // ── Fetch — always replaces list from server truth ─────────────────────────

  Future<void> _fetchMessages() async {
    try {
      // Join profiles on sender_id so we always get the real display name.
      final response = await supabase
          .from('messages')
          .select('id, sender_id, content, created_at, profiles(full_name)')
          .eq('channel_id', channelId)
          .order('created_at', ascending: true);

      final fetched = (response as List<dynamic>)
          .map((json) =>
          ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      // Rebuild from server, dropping any optimistic placeholders.
      _messages
        ..removeWhere((m) => m.id.startsWith('optimistic_'))
        ..clear();
      _messages.addAll(fetched);
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // ── Real-time subscription (best-effort) ───────────────────────────────────

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

  // ── Poll every 4 s — reliable fallback for all participants ───────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _fetchMessages();
      notifyListeners();
    });
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be signed in to send messages.';
      notifyListeners();
      return;
    }

    // Optimistic insert so the sender sees the message immediately.
    final optimisticId =
        'optimistic_${DateTime.now().millisecondsSinceEpoch}';
    _messages.add(ChatMessage(
      id: optimisticId,
      senderId: user.id,
      senderName: user.userMetadata?['full_name'] as String? ?? 'You',
      content: trimmed,
      createdAt: DateTime.now(),
    ));
    notifyListeners();

    try {
      await supabase.from('messages').insert({
        'channel_id': channelId,
        'sender_id': user.id,
        'content': trimmed,
      });
      // Replace optimistic row with the real server row (has proper ID + name).
      await _fetchMessages();
      notifyListeners();
    } catch (e) {
      _messages.removeWhere((m) => m.id == optimisticId);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}