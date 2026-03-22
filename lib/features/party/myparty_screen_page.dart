// lib/features/party/myparty_screen_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/party_view_model.dart';
import 'widgets/party_session_card.dart';

/// Shows only the sessions the current user is hosting or has joined.
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
      body: switch (vm.status) {
        PartyStatus.initial ||
        PartyStatus.loading =>
        const Center(child: CircularProgressIndicator()),
        PartyStatus.error => Center(
          child: Text(
            vm.errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        PartyStatus.loaded => vm.sessions.isEmpty
            ? const Center(
          child: Text("You haven't joined any sessions yet.",
              style: TextStyle(color: Colors.grey)),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.sessions.length,
          itemBuilder: (_, i) => PartySessionCard(
            session: vm.sessions[i],
            onJoin: () {},
          ),
        ),
      },
    );
  }
}