// lib/features/chat/admin_dm_list_screen.dart
//
// Admin chat hub: lists every user who has sent a DM to admin,
// sorted by most-recent message. Tap a row to open the DM thread.
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../chat/realtime_chat_screen.dart';

class AdminDmListScreen extends StatefulWidget {
  const AdminDmListScreen({super.key});

  @override
  State<AdminDmListScreen> createState() => _AdminDmListScreenState();
}

class _AdminDmListScreenState extends State<AdminDmListScreen> {
  late Future<List<_DmThread>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadThreads();
  }

  Future<List<_DmThread>> _loadThreads() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return [];

    // Fetch all DM channels that include the admin (channel_id starts with 'dm_')
    // and grab the latest message + the other participant's profile.
    final rows = await supabase
        .from('messages')
        .select('channel_id, content, created_at, sender_id')
        .like('channel_id', 'dm_%')
        .order('created_at', ascending: false);

    if (rows == null || (rows as List).isEmpty) return [];

    // Group by channel_id, keep only the latest message per channel.
    final Map<String, Map<String, dynamic>> latestByChannel = {};
    for (final row in rows) {
      final ch = row['channel_id'] as String;
      if (!latestByChannel.containsKey(ch)) {
        latestByChannel[ch] = row as Map<String, dynamic>;
      }
    }

    // Filter to channels that involve this admin (channel contains myId or
    // the admin is one of the participants in a "dm_userA_userB" pattern).
    final myChannels = latestByChannel.entries.where((e) {
      return e.key.contains(myId);
    }).toList();

    if (myChannels.isEmpty) return [];

    // For each channel, determine the OTHER user's ID.
    final List<_DmThread> threads = [];
    for (final entry in myChannels) {
      final channelId = entry.key;
      final latestMsg = entry.value;

      // channel format: dm_userA_userB  (sorted IDs)
      final parts = channelId.replaceFirst('dm_', '').split('_');
      // parts may be two UUIDs — find the one that is NOT myId
      // UUIDs contain hyphens, so we need to rebuild them properly.
      // Channel is built as: [id1, id2]..sort() joined by '_'
      // But UUIDs themselves contain '_'? No — UUIDs use '-'.
      // Safe to split on first occurrence after 'dm_':
      final otherId = parts.firstWhere(
            (p) => p != myId,
        orElse: () => '',
      );
      if (otherId.isEmpty) continue;

      // Fetch the other user's profile.
      final profile = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', otherId)
          .maybeSingle();

      threads.add(_DmThread(
        channelId: channelId,
        otherUserId: otherId,
        otherUserName:
        (profile?['full_name'] as String?) ?? 'Unknown User',
        avatarUrl: profile?['avatar_url'] as String?,
        lastMessage: latestMsg['content'] as String? ?? '',
        lastMessageAt:
        DateTime.tryParse(latestMsg['created_at'] as String? ?? '') ??
            DateTime.now(),
        lastSenderId: latestMsg['sender_id'] as String? ?? '',
      ));
    }

    // Sort by most recent message first.
    threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return threads;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('User Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _loadThreads()),
          ),
        ],
      ),
      body: FutureBuilder<List<_DmThread>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Failed to load messages',
                      style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () =>
                        setState(() => _future = _loadThreads()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final threads = snapshot.data ?? [];

          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No user messages yet.',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Messages from users will appear here.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = _loadThreads()),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, indent: 72, endIndent: 16),
              itemBuilder: (_, i) {
                final t = threads[i];
                final myId = supabase.auth.currentUser?.id;
                final isLastByMe = t.lastSenderId == myId;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFD6F0E0),
                    backgroundImage: t.avatarUrl != null
                        ? NetworkImage(t.avatarUrl!)
                        : null,
                    child: t.avatarUrl == null
                        ? Text(
                      t.otherUserName.isNotEmpty
                          ? t.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Color(0xFF1C894E),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                        : null,
                  ),
                  title: Text(
                    t.otherUserName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      isLastByMe
                          ? 'You: ${t.lastMessage}'
                          : t.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600),
                    ),
                  ),
                  trailing: Text(
                    _formatTime(t.lastMessageAt),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RealtimeChatScreen(
                          channelId: t.channelId,
                          chatTitle: t.otherUserName,
                          readOnly: false, // Admin CAN reply in DMs
                        ),
                      ),
                    );
                    // Refresh list after returning.
                    setState(() => _future = _loadThreads());
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DmThread {
  final String channelId;
  final String otherUserId;
  final String otherUserName;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderId;

  const _DmThread({
    required this.channelId,
    required this.otherUserId,
    required this.otherUserName,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
  });
}