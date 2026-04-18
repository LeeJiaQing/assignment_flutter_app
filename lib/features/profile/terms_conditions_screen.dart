// lib/features/profile/terms_conditions_screen.dart
import 'package:flutter/material.dart';
import '../../core/supabase/supabase_config.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() =>
      _TermsConditionsScreenState();
}

class _TermsConditionsScreenState
    extends State<TermsConditionsScreen> {
  static const _sentinel = '__terms_and_conditions__';
  static const _datePfx = '__updated:';

  bool _loading = true;
  String _content = '';
  String? _lastUpdated;

  static const _defaultContent =
      '1. Acceptance of Terms\n'
      'By using CourtNow, you agree to these terms and conditions.\n\n'
      '2. Bookings & Payments\n'
      'All bookings are subject to availability. Payments are processed '
      'securely.\n\n'
      '3. User Responsibilities\n'
      'Users are responsible for arriving on time and treating facilities '
      'with respect.\n\n'
      '4. Privacy Policy\n'
      'We collect only the data necessary to operate the service.\n\n'
      '5. Changes to Terms\n'
      'We reserve the right to update these terms at any time.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await supabase
          .from('announcements')
          .select('body')
          .eq('title', _sentinel)
          .maybeSingle();

      if (response != null) {
        final raw = (response['body'] as String?) ?? _defaultContent;
        final (content, dt) = _decode(raw);
        _content = content;
        if (dt != null) _lastUpdated = _fmt(dt);
      } else {
        _content = _defaultContent;
      }
    } catch (_) {
      _content = _defaultContent;
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Strips the hidden date prefix written by AdminTermsScreen.
  (String, DateTime?) _decode(String raw) {
    if (raw.startsWith(_datePfx)) {
      final nl = raw.indexOf('\n');
      if (nl != -1) {
        final dt = DateTime.tryParse(raw.substring(_datePfx.length, nl));
        return (raw.substring(nl + 1), dt);
      }
    }
    return (raw, null);
  }

  String _fmt(DateTime dt) {
    const m = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final sections = <_Section>[];
    final lines = _content.split('\n');
    String? curTitle;
    final buf = StringBuffer();

    for (final line in lines) {
      final t = line.trim();
      if (RegExp(r'^\d+\.\s+.+').hasMatch(t)) {
        if (curTitle != null) {
          sections.add(_Section(title: curTitle, body: buf.toString().trim()));
          buf.clear();
        }
        curTitle = t;
      } else if (t.isNotEmpty) {
        buf.writeln(t);
      }
    }
    if (curTitle != null) {
      sections.add(_Section(title: curTitle, body: buf.toString().trim()));
    }

    final items =
    sections.isEmpty ? [_Section(title: '', body: _content)] : sections;

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
                    fontSize: 13, color: Colors.black87, height: 1.6)),
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