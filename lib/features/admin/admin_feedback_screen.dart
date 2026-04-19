// lib/features/admin/admin_feedback_screen.dart
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';

class FeedbackEntry {
  final String id;
  final String? userId;
  final String subject;
  final String message;
  final int rating;
  final DateTime createdAt;
  String userName; // populated separately

  FeedbackEntry({
    required this.id,
    this.userId,
    required this.subject,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.userName = 'Unknown User',
  });

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
    id: json['id'] as String,
    userId: json['user_id'] as String?,
    subject: json['subject'] as String? ?? '(No subject)',
    message: json['message'] as String? ?? '',
    rating: json['rating'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<FeedbackEntry> _feedbackList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Fix: separate async work from setState ─────────────────────────────────
  Future<void> _load() async {
    // Step 1: update loading state synchronously
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 2: do all async work OUTSIDE setState
      final response = await supabase
          .from('feedback')
          .select('id, user_id, subject, message, rating, created_at')
          .order('created_at', ascending: false);

      final entries = (response as List<dynamic>)
          .map((j) => FeedbackEntry.fromJson(j as Map<String, dynamic>))
          .toList();

      // Step 3: fetch user names separately (no join needed)
      final userIds = entries
          .where((e) => e.userId != null)
          .map((e) => e.userId!)
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        final profilesResponse = await supabase
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', userIds);

        final nameMap = <String, String>{};
        for (final p in profilesResponse as List<dynamic>) {
          nameMap[p['id'] as String] =
              (p['full_name'] as String?) ?? 'Unknown User';
        }

        entries.removeWhere((entry) {
          if (entry.userId == null) return false;
          return roleMap[entry.userId!]?.toLowerCase() == 'admin';
        });

        for (final entry in entries) {
          if (entry.userId != null) {
            entry.userName = nameMap[entry.userId!] ?? 'Unknown User';
          }
        }
      }

      // Step 4: update state synchronously after all async work is done
      setState(() {
        _feedbackList = entries;
        _loading = false;
      });
    } catch (e) {
      // Step 4 (error case): also update state synchronously
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('User Feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _feedbackList.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _feedbackList.length,
          itemBuilder: (_, i) =>
              _FeedbackCard(entry: _feedbackList[i]),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          'Failed to load feedback',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _load,
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.feedback_outlined, size: 56, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No feedback yet.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      ],
    ),
  );
}

// ── Feedback Card ──────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry});
  final FeedbackEntry entry;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            // Header: user + date
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFD6F0E0),
                  child: Text(
                    entry.userName.isNotEmpty
                        ? entry.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF1C894E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(entry.createdAt),
                        style:
                        const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Star rating
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < entry.rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFC107),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Subject
            Text(
              entry.subject,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1C3A2A),
              ),
            ),
            const SizedBox(height: 6),

            // Message
            Text(
              entry.message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
