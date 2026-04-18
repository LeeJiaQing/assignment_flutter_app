import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import 'realtime_chat_screen.dart';

/// Member chat tab: opens a direct message thread with an admin account.
class UserAdminDmScreen extends StatefulWidget {
  const UserAdminDmScreen({super.key});

  @override
  State<UserAdminDmScreen> createState() => _UserAdminDmScreenState();
}

class _UserAdminDmScreenState extends State<UserAdminDmScreen> {
  late Future<_AdminTarget?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAdminTarget();
  }

  Future<_AdminTarget?> _loadAdminTarget() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return null;

    final row = await supabase
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'admin')
        .neq('id', myId)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;

    final adminId = row['id'] as String;
    final adminName = (row['full_name'] as String?)?.trim();
    final ids = [myId, adminId]..sort();
    final channelId = 'dm_${ids[0]}_${ids[1]}';
    return _AdminTarget(
      channelId: channelId,
      title: (adminName == null || adminName.isEmpty)
          ? 'Admin Support'
          : adminName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminTarget?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: Center(
              child: TextButton(
                onPressed: () => setState(() => _future = _loadAdminTarget()),
                child: const Text('Retry loading admin chat'),
              ),
            ),
          );
        }

        final target = snapshot.data;
        if (target == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: const Center(
              child: Text(
                'Admin account not found yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return RealtimeChatScreen(
          channelId: target.channelId,
          chatTitle: target.title,
        );
      },
    );
  }
}

class _AdminTarget {
  const _AdminTarget({required this.channelId, required this.title});
  final String channelId;
  final String title;
}
