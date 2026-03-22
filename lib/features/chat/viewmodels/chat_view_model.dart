// lib/features/chat/viewmodels/chat_view_model.dart
import 'package:flutter/material.dart';

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

  bool get isMe =>
      senderId == supabase.auth.currentUser?.id;

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

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('messages')
          .select('*, profiles(full_name)')
          .eq('channel_id', channelId)
          .order('created_at', ascending: true);

      _messages
        ..clear()
        ..addAll((response as List<dynamic>)
            .map((json) =>
            ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList());
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('messages').insert({
        'channel_id': channelId,
        'sender_id': userId,
        'content': content.trim(),
      });
      await loadMessages();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}