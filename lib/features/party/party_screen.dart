// lib/features/party/party_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/party_view_model.dart';
import 'widgets/party_session_card.dart';
import 'party_chat_screen.dart';

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartyViewModel()..loadSessions(),
      child: const _PartyView(),
    );
  }
}

class _PartyView extends StatelessWidget {
  const _PartyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Expanded(child: _SessionList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/party/create'),
        icon: const Icon(Icons.add),
        label: const Text('Host Session'),
        backgroundColor: const Color(0xFF1C894E),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() => const Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Find a',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C3A2A),
                height: 1.1)),
        Text('Party',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C894E),
                height: 1.1)),
      ],
    ),
  );
}

class _SessionList extends StatelessWidget {
  const _SessionList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PartyViewModel>();

    return switch (vm.status) {
      PartyStatus.initial || PartyStatus.loading =>
      const Center(child: CircularProgressIndicator()),
      PartyStatus.error => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(vm.errorMessage ?? 'Failed to load sessions',
                style: TextStyle(color: Colors.grey.shade600)),
            TextButton(
              onPressed: () => context.read<PartyViewModel>().loadSessions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      PartyStatus.loaded => _buildList(context, vm),
    };
  }

  Widget _buildList(BuildContext context, PartyViewModel vm) {
    // Show ALL sessions — host sees their own with "Hosting" badge and no join button.
    final sessions = vm.allSessions;

    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No sessions available.\nBe the first to host!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PartyViewModel>().loadSessions(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: sessions.length,
        itemBuilder: (_, i) {
          final session = sessions[i];
          return PartySessionCard(
            session: session,
            isJoined: vm.isJoined(session.id),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PartyDetailChatScreen(session: session),
              ),
            ),
            onJoin: () => _handleJoin(context, session.id),
          );
        },
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context, String sessionId) async {
    final success =
    await context.read<PartyViewModel>().joinSession(sessionId);
    if (!context.mounted) return;

    final vm = context.read<PartyViewModel>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'You have joined the session!'
            : vm.errorMessage ?? 'Failed to join. Please try again.'),
        backgroundColor:
        success ? const Color(0xFF1C894E) : Colors.red.shade700,
      ),
    );
  }
}