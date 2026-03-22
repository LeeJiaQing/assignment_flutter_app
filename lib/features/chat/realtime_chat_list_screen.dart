// lib/features/chat/realtime_chat_list_screen.dart
import 'package:flutter/material.dart';

import 'realtime_chat_screen.dart';

/// Entry point that lists available chat channels.
/// For now lists the general channel; extend with Supabase channels query.
class RealtimeChatListScreen extends StatelessWidget {
  const RealtimeChatListScreen({super.key});

  static const _channels = [
    _ChannelInfo(id: 'general', name: 'General', icon: Icons.forum_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _channels.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final ch = _channels[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD6F0E0),
              child: Icon(ch.icon,
                  color: const Color(0xFF1C894E), size: 20),
            ),
            title: Text(ch.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RealtimeChatScreen(channelId: ch.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChannelInfo {
  const _ChannelInfo(
      {required this.id, required this.name, required this.icon});
  final String id;
  final String name;
  final IconData icon;
}