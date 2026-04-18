// lib/features/booking/create_party_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/navigation_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/booking_model.dart';
import '../home/viewmodels/navigation_view_model.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sportController = TextEditingController();
  final _notesController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '4');

  bool _loadingBookings = true;
  List<_BookingOption> _eligibleBookings = [];
  _BookingOption? _selectedBooking;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadEligibleBookings();
  }

  @override
  void dispose() {
    _sportController.dispose();
    _notesController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _loadEligibleBookings() async {
    setState(() => _loadingBookings = true);
    try {
      final service = BookingService(
        bookingRepository: BookingRepository(),
        facilityRepository: FacilityRepository(),
      );
      final all = await service.fetchMyBookingsWithFacilities();
      final now = DateTime.now();

      // Only confirmed bookings whose start time is in the future.
      final eligible = all.where((bwf) {
        final b = bwf.booking;
        if (b.status != 'confirmed') return false;
        final slotStart = DateTime(
          b.date.year, b.date.month, b.date.day, b.startHour,
        );
        return slotStart.isAfter(now);
      }).map((bwf) => _BookingOption(bwf)).toList();

      setState(() {
        _eligibleBookings = eligible;
        _loadingBookings = false;
      });
    } catch (e) {
      setState(() => _loadingBookings = false);
    }
  }

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host a Session')),
      body: _loadingBookings
          ? const Center(child: CircularProgressIndicator())
          : _eligibleBookings.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Select booking slot ────────────────────────
              const Text(
                'Select Your Booked Slot',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1C3A2A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Only future confirmed bookings are shown.',
                style:
                TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ..._eligibleBookings.map((opt) {
                final b = opt.bwf.booking;
                final isSelected = _selectedBooking == opt;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedBooking = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD6F0E0)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1C894E)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1C894E)
                                : const Color(0xFFD6F0E0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sports_tennis,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1C894E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.bwf.facilityName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1C3A2A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_fmtDate(b.date)}  •  '
                                    '${_fmt(b.startHour)} – ${_fmt(b.endHour)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: Color(0xFF1C894E)),
                      ],
                    ),
                  ),
                );
              }),

              if (_selectedBooking == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Please select a booking slot above.',
                    style: TextStyle(
                        color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // ── Sport ──────────────────────────────────────
              _Field(
                controller: _sportController,
                label: 'Sport (e.g. Badminton)',
              ),

              // ── Max Players ────────────────────────────────
              _Field(
                controller: _maxPlayersController,
                label: 'Max Players',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 2) return 'Min 2 players';
                  if (n > 20) return 'Max 20 players';
                  return null;
                },
              ),

              // ── Notes ──────────────────────────────────────
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                  ),
                  onPressed:
                  _submitting ? null : () => _submit(context),
                  child: _submitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white),
                  )
                      : const Text(
                    'Create Session',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No upcoming bookings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C3A2A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'You need a confirmed booking to host a party session. '
                  'Book a court first, then come back to create a session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C894E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                // Pop every route until we're back at MainNavigation (the first route).
                NavigationService.instance.popToRoot();

                // Give the navigator a frame to settle, then switch to Facility tab.
                await Future.delayed(const Duration(milliseconds: 100));

                final navCtx =
                    NavigationService.instance.navigator?.context;
                if (navCtx != null && navCtx.mounted) {
                  try {
                    // ignore: use_build_context_synchronously
                    Provider.of<NavigationViewModel>(navCtx, listen: false)
                        .setTab(1); // index 1 = Facility for both roles
                  } catch (_) {
                    // NavigationViewModel not found — already on home, that's fine.
                  }
                }
              },
              child: const Text('Book a Court'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_selectedBooking == null) {
      setState(() {}); // trigger rebuild to show error
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in');

      final b = _selectedBooking!.bwf.booking;

      await supabase.from('party_sessions').insert({
        'host_id': userId,
        'facility_id': b.facilityId,
        'booking_id': b.id,
        'sport': _sportController.text.trim(),
        'date': b.date.toIso8601String().substring(0, 10),
        'start_hour': b.startHour,
        'end_hour': b.endHour,
        'max_players': int.parse(_maxPlayersController.text.trim()),
        'current_players': 1,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session created! Others can now join.'),
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

class _BookingOption {
  final dynamic bwf; // BookingWithFacility
  _BookingOption(this.bwf);
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