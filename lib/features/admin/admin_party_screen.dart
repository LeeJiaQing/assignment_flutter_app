// lib/features/admin/admin_party_screen.dart
//
// Admin-only party list. Admins can view sessions and their chat but cannot:
//   • Add / edit / delete a session
//   • Join a session
//   • Send messages in the party chat
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../party/viewmodels/party_view_model.dart';
import '../party/party_chat_screen.dart';

class AdminPartyScreen extends StatelessWidget {
  const AdminPartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartyViewModel()..loadSessions(),
      child: const _AdminPartyView(),
    );
  }
}

class _AdminPartyView extends StatelessWidget {
  const _AdminPartyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Expanded(child: _AdminSessionList()),
          ],
        ),
      ),
      // No FloatingActionButton — admin cannot host/create sessions.
    );
  }

  Widget _buildHeader() => const Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Party',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C3A2A),
            height: 1.1,
          ),
        ),
        Text(
          'Sessions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C894E),
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

class _AdminSessionList extends StatelessWidget {
  const _AdminSessionList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PartyViewModel>();

    return switch (vm.status) {
      PartyStatus.initial ||
      PartyStatus.loading =>
      const Center(child: CircularProgressIndicator()),
      PartyStatus.error => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              vm.errorMessage ?? 'Failed to load sessions',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            TextButton(
              onPressed: () =>
                  context.read<PartyViewModel>().loadSessions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      PartyStatus.loaded => _buildList(context, vm),
    };
  }

  Widget _buildList(BuildContext context, PartyViewModel vm) {
    final sessions = vm.sessions;

    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No party sessions yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PartyViewModel>().loadSessions(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sessions.length,
        itemBuilder: (_, i) {
          final session = sessions[i];
          return _AdminSessionTile(
            session: session,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PartyDetailChatScreen(session: session),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Admin-specific session tile (no join / no action buttons) ──────────────

class _AdminSessionTile extends StatelessWidget {
  const _AdminSessionTile(
      {required this.session, required this.onTap});
  final PartySession session;
  final VoidCallback onTap;

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  String get _timeLabel =>
      '${_fmt(session.startHour)} – ${_fmt(session.endHour)}';

  String get _dateLabel {
    final d = session.date;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sport badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F0E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.sport,
                      style: const TextStyle(
                        color: Color(0xFF1C894E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Player count
                  Row(
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${session.currentPlayers}/${session.maxPlayers}',
                        style: TextStyle(
                          fontSize: 12,
                          color: session.isFull
                              ? Colors.red
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                session.facilityName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C3A2A),
                ),
              ),
              const SizedBox(height: 6),
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: _dateLabel),
              const SizedBox(height: 3),
              _InfoRow(
                  icon: Icons.access_time_outlined,
                  text: _timeLabel),
              const SizedBox(height: 3),
              _InfoRow(
                  icon: Icons.person_outline,
                  text: 'Host: ${session.hostName}'),
              if (session.notes != null &&
                  session.notes!.isNotEmpty) ...[
                const SizedBox(height: 3),
                _InfoRow(
                    icon: Icons.notes_outlined, text: session.notes!),
              ],
              const SizedBox(height: 12),
              // View details / chat button — view only
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View Details & Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1C894E),
                    side: const BorderSide(color: Color(0xFF1C894E)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}