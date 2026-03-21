// lib/features/booking/booking_schedule_screen.dart
//jq
import 'package:flutter/material.dart';

import '../../core/repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import '../../models/facility_model.dart';
import 'payment_screen.dart';

const _kGreen = Color(0xFF1C894E);
const _kGreenLight = Color(0xFF6DCC98);
const _kBg = Color(0xFFC8DFC3);
const _kCardBg = Colors.white;
const _kAvailableChip = Color(0xFFD6F0E0);
const _kAvailableText = Color(0xFF1C894E);
const _kSelectedChip = Color(0xFF1C894E);
const _kUnavailableChip = Color(0xFFFFD6D6);
const _kUnavailableText = Color(0xFFB00020);
const _kExpiredChip = Color(0xFFE0E0E0);
const _kExpiredText = Color(0xFF9E9E9E);
const int _kMaxSlots = 2;

class BookingScheduleScreen extends StatefulWidget {
  final Facility facility;
  const BookingScheduleScreen({super.key, required this.facility});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  final _repo = BookingRepository();

  late DateTime _selectedDate;
  late DateTime _weekStart;

  // courtId -> Set<bookedHour> fetched from Supabase
  final Map<String, Set<int>> _bookedHoursCache = {};
  final Map<String, bool> _loadingCourts = {};

  // slotId -> _SelectedSlot
  final Map<String, _SelectedSlot> _selectedSlots = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = _today();
    _weekStart = _mondayOf(_selectedDate);
    _loadBookedHoursForDate(_selectedDate);
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtMonth(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[d.month - 1];
  }

  String _fmtShortDay(DateTime d) {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return days[d.weekday - 1];
  }

  String get _formattedDate {
    final d = _selectedDate;
    return '${d.day.toString().padLeft(2,'0')}/'
        '${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  // ── slot generation from facility open/close hours ────────────────────────

  List<TimeSlot> _slotsForCourt(String courtId) {
    final bookedHours = _bookedHoursCache[courtId] ?? {};
    final slots = <TimeSlot>[];

    for (int h = widget.facility.openHour; h < widget.facility.closeHour; h++) {
      final slot = TimeSlot(
        courtId:   courtId,
        date:      _selectedDate,
        startHour: h,
        endHour:   h + 1,
        status: bookedHours.contains(h)
            ? SlotStatus.booked
            : SlotStatus.available,
      );
      slots.add(slot);
    }
    return slots;
  }

  // ── Supabase fetch ────────────────────────────────────────────────────────

  Future<void> _loadBookedHoursForDate(DateTime date) async {
    for (final court in widget.facility.courts) {
      if (_loadingCourts[court.id] == true) continue;
      setState(() => _loadingCourts[court.id] = true);

      try {
        final hours = await _repo.fetchBookedHours(
            courtId: court.id, date: date);
        if (mounted) {
          setState(() {
            _bookedHoursCache[court.id] = hours;
            _loadingCourts[court.id] = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingCourts[court.id] = false);
      }
    }
  }

  // ── slot selection ────────────────────────────────────────────────────────

  void _toggleSlot(Court court, TimeSlot slot) {
    final effective = slot.effectiveStatus(DateTime.now());
    if (effective != SlotStatus.available) return;

    setState(() {
      if (_selectedSlots.containsKey(slot.id)) {
        _selectedSlots.remove(slot.id);
      } else {
        if (_selectedSlots.length >= _kMaxSlots) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You can book a maximum of 2 slots per day.'),
            duration: Duration(seconds: 2),
          ));
          return;
        }
        _selectedSlots[slot.id] = _SelectedSlot(
          slot:      slot,
          courtId:   court.id,
          courtName: court.name,
        );
      }
    });
  }

  // ── checkout ──────────────────────────────────────────────────────────────

  void _checkout() {
    final entries = _selectedSlots.values.toList();
    final bookings = entries
        .map((s) => BookingInfo(
      facilityName: widget.facility.name,
      facilityId:   widget.facility.id,
      courtId:      s.courtId,
      courtName:    s.courtName,
      imageUrl:     widget.facility.imageUrl,
      date:         _selectedDate,
      formattedDate: _formattedDate,
      startHour:    s.slot.startHour,
      endHour:      s.slot.endHour,
      timeLabel:    s.slot.label,
      pricePerSlot: widget.facility.pricePerSlot,
    ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          bookings:   bookings,
          grandTotal: entries.length * widget.facility.pricePerSlot,
        ),
      ),
    );
  }

  // ── week navigation ───────────────────────────────────────────────────────

  void _prevWeek() => setState(
          () => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(widget.facility.name,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildLegend(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: widget.facility.courts
                  .map(_buildCourtCard)
                  .toList(),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  // ── calendar ──────────────────────────────────────────────────────────────

  Widget _buildCalendarHeader() {
    final days = List.generate(5, (i) => _weekStart.add(Duration(days: i)));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFD6F0E0),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevWeek,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
              Text(_fmtMonth(_weekStart),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextWeek,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map(_buildDayCell).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime d) {
    final isSelected = _isSameDay(d, _selectedDate);
    final isToday = _isSameDay(d, _today());
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = d;
          _selectedSlots.clear();
        });
        _loadBookedHoursForDate(d);
      },
      child: SizedBox(
        width: 52,
        child: Column(
          children: [
            Text(_fmtShortDay(d),
                style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? _kGreen : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal)),
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? _kGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: _kGreen, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text('${d.day}',
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── legend ────────────────────────────────────────────────────────────────

  Widget _buildLegend() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(_kAvailableChip, _kAvailableText, 'Available'),
        const SizedBox(width: 24),
        _dot(_kUnavailableChip, _kUnavailableText, 'Unavailable'),
      ],
    ),
  );

  Widget _dot(Color bg, Color fg, String label) => Row(
    children: [
      Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: fg.withOpacity(0.4)))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  // ── court card ────────────────────────────────────────────────────────────

  Widget _buildCourtCard(Court court) {
    final isLoading = _loadingCourts[court.id] == true;
    final slots = _slotsForCourt(court.id);
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _kCardBg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(court.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map((s) => _buildSlotChip(court, s, now))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotChip(Court court, TimeSlot slot, DateTime now) {
    final effective = slot.effectiveStatus(now);
    final isSelected = _selectedSlots.containsKey(slot.id);

    Color chipColor;
    Color textColor;
    bool tappable = false;

    if (isSelected) {
      chipColor = _kSelectedChip;
      textColor = Colors.white;
      tappable = true;
    } else {
      switch (effective) {
        case SlotStatus.available:
          chipColor = _kAvailableChip;
          textColor = _kAvailableText;
          tappable = true;
          break;
        case SlotStatus.booked:
          chipColor = _kUnavailableChip;
          textColor = _kUnavailableText;
          break;
        case SlotStatus.expired:
          chipColor = _kExpiredChip;
          textColor = _kExpiredText;
          break;
      }
    }

    return GestureDetector(
      onTap: tappable ? () => _toggleSlot(court, slot) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: chipColor, borderRadius: BorderRadius.circular(20)),
        child: Text(slot.label,
            style: TextStyle(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ── bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final slots = _selectedSlots.values.toList();
    final hasSelection = slots.isNotEmpty;
    final total = slots.length * widget.facility.pricePerSlot;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSelection) ...[
            Text(
              'Facility: ${widget.facility.name} – ${slots.first.courtName}',
              style: const TextStyle(fontSize: 13),
            ),
            Text('Date: $_formattedDate',
                style: const TextStyle(fontSize: 13)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Time: ${slots.map((s) => s.slot.label).join(', ')}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('Total: RM ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreenLight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: _kExpiredChip,
              ),
              onPressed: hasSelection ? _checkout : null,
              child: const Text('Checkout',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedSlot {
  final TimeSlot slot;
  final String courtId;
  final String courtName;
  const _SelectedSlot({
    required this.slot,
    required this.courtId,
    required this.courtName,
  });
}