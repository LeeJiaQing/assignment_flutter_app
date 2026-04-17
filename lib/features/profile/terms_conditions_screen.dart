// lib/features/profile/terms_conditions_screen.dart
//
// Member read-only view of the Terms & Conditions.
// Fetches live content from the same sentinel row used by AdminTermsScreen.
// Falls back to hardcoded defaults if the row doesn't exist yet.
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() =>
      _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  static const _sentinel = '__terms_and_conditions__';

  bool _loading = true;
  String _content = '';
  String? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final response = await supabase
          .from('announcements')
          .select('body, updated_at, created_at')
          .eq('title', _sentinel)
          .maybeSingle();

      if (response != null) {
        _content = (response['body'] as String?) ?? _defaultContent;
        final dateStr = (response['updated_at'] as String?) ??
            (response['created_at'] as String?);
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null) _lastUpdated = _formatDate(dt);
        }
      } else {
        _content = _defaultContent;
      }
    } catch (_) {
      _content = _defaultContent;
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static const _defaultContent =
      '1. Acceptance of Terms\n'
      'By using CourtNow, you agree to these terms and conditions. '
      'If you do not agree, please do not use the application.\n\n'
      '2. Bookings & Payments\n'
      'All bookings are subject to availability. Payments are processed '
      'securely. Cancellations must be made at least 24 hours before the '
      'scheduled session to receive a refund.\n\n'
      '3. User Responsibilities\n'
      'Users are responsible for arriving on time and treating facilities '
      'with respect. Any damage caused to facilities may result in '
      'suspension of your account.\n\n'
      '4. Privacy Policy\n'
      'We collect only the data necessary to operate the service. '
      'Your data is never sold to third parties. See our Privacy Policy '
      'for full details.\n\n'
      '5. Changes to Terms\n'
      'We reserve the right to update these terms at any time. '
      'Continued use of the application after changes constitutes '
      'acceptance of the new terms.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final sections = <_Section>[];
    final lines = _content.split('\n');
    String? currentTitle;
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (RegExp(r'^\d+\.\s+.+').hasMatch(trimmed)) {
        if (currentTitle != null) {
          sections.add(_Section(
              title: currentTitle, body: buffer.toString().trim()));
          buffer.clear();
        }
        currentTitle = trimmed;
      } else if (trimmed.isNotEmpty) {
        buffer.writeln(trimmed);
      }
    }
    if (currentTitle != null) {
      sections.add(
          _Section(title: currentTitle, body: buffer.toString().trim()));
    }

    final items = sections.isEmpty
        ? [_Section(title: '', body: _content)]
        : sections;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...items.map((s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 6),
                child: Text(s.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C3A2A))),
              ),
            Text(s.body,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.6)),
          ],
        )),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Last updated: ${_lastUpdated ?? 'March 2026'}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}