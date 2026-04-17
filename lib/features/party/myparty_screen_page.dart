// lib/features/party/myparty_screen_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_config.dart';
import 'viewmodels/party_view_model.dart';
import 'widgets/party_session_card.dart';
import 'party_chat_screen.dart';

/// Shows the sessions the current user is hosting OR has joined.
class MyPartyScreenPage extends StatelessWidget {
  const MyPartyScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartyViewModel()..loadSessions(),
      child: const _MyPartyView(),
    );
  }
}

class _MyPartyView extends StatefulWidget {
  const _MyPartyView();

  @override
  State<_MyPartyView> createState() => _MyPartyViewState();
}

class _MyPartyViewState extends State<_MyPartyView> {
  /// IDs of sessions the current user has joined (not as host).
  Set<String> _joinedSessionIds = {};
  bool _joinedLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadJoinedSessions();
  }

  Future<void> _loadJoinedSessions() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('party_members')
          .select('session_id')
          .eq('user_id', userId);

      setState(() {
        _joinedSessionIds = (response as List<dynamic>)
            .map((r) => r['session_id'] as String)
            .toSet();
        _joinedLoaded = true;
      });
    } catch (_) {
      setState(() => _joinedLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PartyViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Sessions')),
      backgroundColor: const Color(0xFFF4FAF6),
      body: switch (vm.status) {
        PartyStatus.initial ||
        PartyStatus.loading =>
        const Center(child: CircularProgressIndicator()),
        PartyStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                vm.errorMessage ?? 'Something went wrong',
                style: const TextStyle(color: Colors.grey),
              ),
              TextButton(
                onPressed: () {
                  _loadJoinedSessions();
                  context.read<PartyViewModel>().loadSessions();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        PartyStatus.loaded => _buildList(context, vm),
      },
    );
  }

  Widget _buildList(BuildContext context, PartyViewModel vm) {
    if (!_joinedLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final uid = supabase.auth.currentUser?.id;

    // Combine: sessions the user is hosting + sessions they joined as a member
    final mySessions = vm.sessions.where((s) {
      return s.hostId == uid || _joinedSessionIds.contains(s.id);
    }).toList();

    if (mySessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "You haven't joined any sessions yet.",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Browse the Party tab to find one!',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadJoinedSessions();
        await context.read<PartyViewModel>().loadSessions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mySessions.length,
        itemBuilder: (_, i) {
          final session = mySessions[i];
          void goToDetail() => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PartyDetailChatScreen(session: session),
            ),
          );
          return PartySessionCard(
            session: session,
            onTap: goToDetail,
            // No join button on "my sessions" — user is already in.
            onJoin: () {},
          );
        },
      ),
    );
  }
}