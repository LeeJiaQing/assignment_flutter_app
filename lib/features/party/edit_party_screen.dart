// lib/features/party/edit_party_screen.dart
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import 'viewmodels/party_view_model.dart';

class EditPartyScreen extends StatefulWidget {
  const EditPartyScreen({super.key, required this.session});

  final PartySession session;

  @override
  State<EditPartyScreen> createState() => _EditPartyScreenState();
}

class _EditPartyScreenState extends State<EditPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sportCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _maxPlayersCtrl;
  bool _saving = false;
  bool _deleting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _sportCtrl = TextEditingController(text: widget.session.sport);
    _notesCtrl = TextEditingController(text: widget.session.notes ?? '');
    _maxPlayersCtrl =
        TextEditingController(text: widget.session.maxPlayers.toString());
  }

  @override
  void dispose() {
    _sportCtrl.dispose();
    _notesCtrl.dispose();
    _maxPlayersCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMsg = null;
    });
    try {
      // Update core fields first — these columns always exist.
      await supabase.from('party_sessions').update({
        'sport': _sportCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        'max_players': int.parse(_maxPlayersCtrl.text.trim()),
      }).eq('id', widget.session.id);

      // Try to set is_edited = true separately so a missing column
      // doesn't break the whole save.
      try {
        await supabase.from('party_sessions').update({
          'is_edited': true,
        }).eq('id', widget.session.id);
      } catch (_) {
        // Column may not exist yet — ignore, run the SQL migration to add it.
      }

      if (!mounted) return;
      Navigator.pop(context, true); // true = was edited
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMsg = e.toString();
      });
    } finally {
      if (mounted && _errorMsg == null) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
            'Are you sure you want to delete this session? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _errorMsg = null;
    });
    try {
      // Step 1: delete all members of this session first (FK constraint).
      await supabase
          .from('party_members')
          .delete()
          .eq('session_id', widget.session.id);

      // Step 2: delete the session itself.
      await supabase
          .from('party_sessions')
          .delete()
          .eq('id', widget.session.id);

      if (!mounted) return;
      Navigator.pop(context, 'deleted');
    } catch (e) {
      setState(() {
        _deleting = false;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Session'),
        actions: [
          IconButton(
            icon: _deleting
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete session',
            onPressed: (_saving || _deleting) ? null : _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6F0E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF1C894E), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saving changes will show an "Edited" badge to all participants.',
                        style: TextStyle(
                            color: Color(0xFF1C894E), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Error display
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              _Field(
                controller: _sportCtrl,
                label: 'Sport',
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              _Field(
                controller: _maxPlayersCtrl,
                label: 'Max Players',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < widget.session.currentPlayers) {
                    return 'Must be ≥ current players (${widget.session.currentPlayers})';
                  }
                  if (n > 20) return 'Max 20 players';
                  return null;
                },
              ),
              _Field(
                controller: _notesCtrl,
                label: 'Notes (optional)',
                required: false,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C894E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_saving || _deleting) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.required = true,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool required;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: validator ??
            (required
                ? (v) =>
            (v == null || v.trim().isEmpty) ? 'Required' : null
                : null),
      ),
    );
  }
}