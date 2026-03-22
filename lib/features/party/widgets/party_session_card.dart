// lib/features/party/widgets/party_session_card.dart
import 'package:flutter/material.dart';

import '../viewmodels/party_view_model.dart';

class PartySessionCard extends StatelessWidget {
  const PartySessionCard({
    super.key,
    required this.session,
    required this.onJoin,
  });

  final PartySession session;
  final VoidCallback onJoin;

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
    return Container(
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
                _SportBadge(sport: session.sport),
                const Spacer(),
                _PlayersBadge(session: session),
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
                icon: Icons.calendar_today_outlined, text: _dateLabel),
            const SizedBox(height: 3),
            _InfoRow(icon: Icons.access_time_outlined, text: _timeLabel),
            const SizedBox(height: 3),
            _InfoRow(
                icon: Icons.person_outline, text: 'Host: ${session.hostName}'),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 3),
              _InfoRow(
                  icon: Icons.notes_outlined, text: session.notes!),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: session.isFull
                      ? Colors.grey.shade300
                      : const Color(0xFF6DCC98),
                  foregroundColor: session.isFull
                      ? Colors.grey.shade600
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: session.isFull ? null : onJoin,
                child: Text(
                  session.isFull ? 'Session Full' : 'Join Session',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportBadge extends StatelessWidget {
  const _SportBadge({required this.sport});
  final String sport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        sport,
        style: const TextStyle(
          color: Color(0xFF1C894E),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PlayersBadge extends StatelessWidget {
  const _PlayersBadge({required this.session});
  final PartySession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.group_outlined, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '${session.currentPlayers}/${session.maxPlayers}',
          style: TextStyle(
            fontSize: 12,
            color: session.isFull ? Colors.red : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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