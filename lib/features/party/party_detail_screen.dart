// lib/features/party/party_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/party_view_model.dart';
import 'widgets/party_session_card.dart';

class PartyDetailScreen extends StatelessWidget {
  const PartyDetailScreen({super.key, required this.session});

  final PartySession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PartySessionCard(
          session: session,
          onJoin: () => _handleJoin(context),
        ),
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context) async {
    final vm = context.read<PartyViewModel>();
    final success = await vm.joinSession(session.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'You have joined the session!'
            : 'Failed to join. ${vm.errorMessage ?? ''}'),
        backgroundColor:
        success ? const Color(0xFF1C894E) : Colors.red.shade700,
      ),
    );

    if (success) Navigator.pop(context);
  }
}