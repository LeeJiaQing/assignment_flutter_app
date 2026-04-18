// lib/features/party/myparty_screen_page.dart
//
// Shows sessions the current user is hosting OR has joined as a member.
// Uses PartyViewModel which now tracks joined session IDs internally.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/party_view_model.dart';
import 'widgets/party_session_card.dart';
import 'party_chat_screen.dart';

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

class _MyPartyView extends StatelessWidget {
  const _MyPartyView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PartyViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Sessions')),
      backgroundColor: const Color(0xFFF4FAF6),
      body: switch (vm.status) {
        PartyStatus.initial || PartyStatus.loading =>
        const Center(child: CircularProgressIndicator()),
        PartyStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(vm.errorMessage ?? 'Something went wrong',
                  style: const TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () =>
                    context.read<PartyViewModel>().loadSessions(),
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
    // mySessions = sessions user is hosting + sessions they joined as member
    final mySessions = vm.mySessions;

    if (mySessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text("You haven't joined any sessions yet.",
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 8),
            Text('Browse the Party tab to find one!',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PartyViewModel>().loadSessions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mySessions.length,
        itemBuilder: (_, i) {
          final session = mySessions[i];
          void goToDetail() => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PartyDetailChatScreen(session: session),
            ),
          );
          return PartySessionCard(
            session: session,
            // Always "joined" from this screen — button stays disabled.
            isJoined: true,
            onTap: goToDetail,
            onJoin: () {},
          );
        },
      ),
    );
  }
}