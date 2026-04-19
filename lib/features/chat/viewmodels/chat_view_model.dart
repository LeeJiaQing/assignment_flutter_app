// lib/features/chat/viewmodels/chat_view_model.dart
//
// Strategy:
//  • Static in-memory cache keyed by channelId — messages persist even if
//    the widget is disposed and re-created (tab switching, screen close/reopen).
//  • Optimistic insert: sender sees message instantly.
//  • After every send: reload from server to confirm with real row + senderName.
//  • 4-second poll keeps all participants in sync (no Realtime dependency).
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
    // profiles join on sender_id -> profiles.id
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

  // ── Static cache so messages survive screen close/reopen ──────────────────
  static final Map<String, List<ChatMessage>> _cache = {};

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
    // Restore from cache immediately so previous messages show at once.
    if (_cache.containsKey(channelId)) {
      _messages.addAll(_cache[channelId]!);
      notifyListeners();
    }

    _isLoading = true;
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
      final response = await supabase
          .from('messages')
          .select('id, sender_id, content, created_at, profiles(full_name)')
          .eq('channel_id', channelId)
          .order('created_at', ascending: true);

      final fetched = (response as List<dynamic>)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      // Rebuild from server, dropping any optimistic placeholders.
      _messages
        ..removeWhere((m) => m.id.startsWith('optimistic_'))
        ..clear();
      _messages.addAll(fetched);

      // Update cache.
      _cache[channelId] = List.of(_messages);
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
    final optimisticId = 'optimistic_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: optimisticId,
      senderId: user.id,
      senderName: user.userMetadata?['full_name'] as String? ?? 'You',
      content: trimmed,
      createdAt: DateTime.now(),
    );
    _messages.add(optimistic);
    _cache[channelId] = List.of(_messages);
    notifyListeners();

    try {
      await supabase.from('messages').insert({
        'channel_id': channelId,
        'sender_id': user.id,
        'content': trimmed,
      });
      // Replace optimistic row with the real server row.
      await _fetchMessages();
      notifyListeners();
    } catch (e) {
      _messages.removeWhere((m) => m.id == optimisticId);
      _cache[channelId] = List.of(_messages);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}