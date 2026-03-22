// lib/features/party/party_chat_screen.dart
import 'package:flutter/material.dart';

/// Placeholder for party session chat.
/// Wire a real-time Supabase channel or similar here when ready.
/// All message state belongs in a PartyChatViewModel (to be implemented).
class PartyChatScreen extends StatelessWidget {
  const PartyChatScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Chat')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 60, color: Color(0xFF1C894E)),
            const SizedBox(height: 16),
            const Text(
              'Party Chat',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Session: $sessionId',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}