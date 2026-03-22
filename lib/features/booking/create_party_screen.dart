// lib/features/booking/create_party_screen.dart
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';

/// Screen for hosting a new party session.
/// All form state is local — no ViewModel needed for a simple one-shot form.
class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _facilityIdController = TextEditingController();
  final _sportController = TextEditingController();
  final _notesController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '4');
  final _openHourController = TextEditingController(text: '8');
  final _closeHourController = TextEditingController(text: '10');

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  @override
  void dispose() {
    _facilityIdController.dispose();
    _sportController.dispose();
    _notesController.dispose();
    _maxPlayersController.dispose();
    _openHourController.dispose();
    _closeHourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host a Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(
                  controller: _facilityIdController,
                  label: 'Facility ID'),
              _Field(
                  controller: _sportController,
                  label: 'Sport (e.g. Badminton)'),
              _Field(
                controller: _maxPlayersController,
                label: 'Max Players',
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _openHourController,
                      label: 'Start Hour (0–23)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _closeHourController,
                      label: 'End Hour (0–23)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _DatePickerRow(
                date: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
              _Field(
                controller: _notesController,
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
                  onPressed: _submitting ? null : () => _submit(context),
                  child: _submitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Create Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in');

      await supabase.from('party_sessions').insert({
        'host_id': userId,
        'facility_id': _facilityIdController.text.trim(),
        'sport': _sportController.text.trim(),
        'date': _date.toIso8601String().substring(0, 10),
        'start_hour': int.parse(_openHourController.text.trim()),
        'end_hour': int.parse(_closeHourController.text.trim()),
        'max_players': int.parse(_maxPlayersController.text.trim()),
        'current_players': 1,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session created!'),
          backgroundColor: Color(0xFF1C894E),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.required = true,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool required;
  final int maxLines;

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
        validator: required
            ? (v) =>
        (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Text('Date: ',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/${date.year}',
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime.now(),
                lastDate:
                DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) onChanged(picked);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}