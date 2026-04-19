// lib/features/admin/user_list_screen.dart
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../chat/realtime_chat_screen.dart';
import '../../models/user_model.dart';
import 'user_bookings_screen.dart';
import 'user_details_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<UserProfile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchUsers();
  }

  Future<List<UserProfile>> _fetchUsers() async {
    final response = await supabase
        .from('profiles')
        .select()
        .neq('role', 'admin')
        .order('full_name');

    return (response as List<dynamic>)
        .map((json) => UserProfile.fromJson({
      ...json as Map<String, dynamic>,
      'email': json['email'] ?? '',
    }))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: FutureBuilder<List<UserProfile>>(
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
                  Text(snapshot.error.toString()),
                  TextButton(
                    onPressed: () =>
                        setState(() => _future = _fetchUsers()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = _fetchUsers()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1),
              itemBuilder: (_, i) => _UserTile(user: users[i]),
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final UserProfile user;

  String _channelIdForUser(UserProfile user) {
    final me = supabase.auth.currentUser?.id;
    if (me == null || me == user.id) {
      return 'dm_${user.id}';
    }
    final pair = [me, user.id]..sort();
    return 'dm_${pair[0]}_${pair[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFD6F0E0),
        child: Text(
          user.fullName.isNotEmpty
              ? user.fullName[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: Color(0xFF1C894E), fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(user.email,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Chat',
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1C894E)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RealtimeChatScreen(
                  channelId: _channelIdForUser(user),
                  chatTitle: 'Chat: ${user.fullName}',
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bookings',
            icon: const Icon(Icons.event_note_outlined, color: Color(0xFF1C894E)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserBookingsScreen(user: user),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => UserDetailsScreen(user: user)),
      ),
    );
  }
}
