// lib/features/admin/admin_terms_screen.dart
//
// Admin screen to view AND edit the Terms & Conditions.
// Storage: uses a sentinel row in the `announcements` table with
// title == '__terms_and_conditions__'. The `updated_at` column is
// stored in the `data` JSON field as a workaround (no schema change needed).
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';

class AdminTermsScreen extends StatefulWidget {
  const AdminTermsScreen({super.key});

  @override
  State<AdminTermsScreen> createState() => _AdminTermsScreenState();
}

class _AdminTermsScreenState extends State<AdminTermsScreen> {
  static const _sentinel = '__terms_and_conditions__';

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

  late final TextEditingController _controller;
  String? _existingRowId;
  DateTime? _lastUpdated;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final response = await supabase
          .from('announcements')
          .select('id, body, updated_at, created_at')
          .eq('title', _sentinel)
          .maybeSingle();

      if (response != null) {
        _existingRowId = response['id'] as String?;
        _controller.text = (response['body'] as String?) ?? _defaultContent;
        // Use updated_at if available, else created_at
        final dateStr = (response['updated_at'] as String?) ??
            (response['created_at'] as String?);
        if (dateStr != null) {
          _lastUpdated = DateTime.tryParse(dateStr);
        }
      } else {
        _existingRowId = null;
        _controller.text = _defaultContent;
        _lastUpdated = null;
      }
    } catch (_) {
      _controller.text = _defaultContent;
      _lastUpdated = null;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final adminId = supabase.auth.currentUser?.id;
      final now = DateTime.now();
      final nowIso = now.toUtc().toIso8601String();

      if (_existingRowId != null) {
        await supabase.from('announcements').update({
          'body': _controller.text,
          'updated_at': nowIso,
        }).eq('id', _existingRowId!);
      } else {
        final result = await supabase
            .from('announcements')
            .insert({
          'title': _sentinel,
          'body': _controller.text,
          'target_type': 'none',
          'created_by': adminId,
          'notification_sent': true,
          'updated_at': nowIso,
        })
            .select('id')
            .single();
        _existingRowId = result['id'] as String?;
      }

      _lastUpdated = now;
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terms & Conditions updated successfully.'),
          backgroundColor: Color(0xFF1C894E),
        ),
      );
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = 'Save failed: ${e.toString()}';
      });
    }
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancelEditing() {
    _load();
    setState(() => _editing = false);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        actions: [
          if (!_loading)
            _editing
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _saving ? null : _cancelEditing,
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1C894E)))
                      : const Text('Save',
                      style: TextStyle(
                          color: Color(0xFF1C894E),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            )
                : IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: _startEditing,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Admin banner
          Container(
            color: const Color(0xFFD6F0E0),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Color(0xFF1C894E), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _editing
                        ? 'Edit mode — changes are visible to all users after saving.'
                        : 'Tap the \u270f\ufe0f icon to edit the Terms & Conditions.',
                    style: const TextStyle(
                        color: Color(0xFF1C894E), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null)
            Container(
              color: Colors.red.shade50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _editing
                ? Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                  hintText: 'Enter terms content\u2026',
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.6),
              ),
            )
                : _ReadOnlyView(
              content: _controller.text,
              lastUpdated: _lastUpdated != null
                  ? _formatDate(_lastUpdated!)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Read-only formatted view ───────────────────────────────────────────────

class _ReadOnlyView extends StatelessWidget {
  const _ReadOnlyView({required this.content, this.lastUpdated});
  final String content;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final sections = <_Section>[];
    final lines = content.split('\n');
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

    if (sections.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(content,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87, height: 1.6)),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Last updated: ${lastUpdated ?? 'N/A'}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sections.length + 1,
      itemBuilder: (_, i) {
        if (i == sections.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'Last updated: ${lastUpdated ?? 'N/A'}',
                style:
                const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }
        final s = sections[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        );
      },
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}