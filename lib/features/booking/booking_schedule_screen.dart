// lib/features/booking/booking_schedule_screen.dart
//jq
import 'package:flutter/material.dart';

import '../../models/court_model.dart';
import '../../models/facility_model.dart';
import '../../models/facility_seed.dart';
import 'payment_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants / theme colours
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class BookingScheduleScreen extends StatefulWidget {
  /// Pass the facility the user tapped "Book Now" on.
  /// Falls back to the first facility if not provided.
  final Facility? facility;

  const BookingScheduleScreen({super.key, this.facility});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  late final Facility _facility;
  late DateTime _selectedDate;
  late DateTime _weekStart; // Monday of the displayed week

  /// Selected slot ids (max _kMaxSlots per day across all courts)
  final Set<String> _selectedIds = {};

  /// For the summary bar: store the actual TimeSlot objects selected
  final List<_SelectedSlot> _selectedSlots = [];

  @override
  void initState() {
    super.initState();
    // Use provided facility, fall back to first in catalogue
    _facility = widget.facility ?? facilityList.first;
    _selectedDate = _today();
    _weekStart = _mondayOf(_selectedDate);
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _mondayOf(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _fmtMonth(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[d.month - 1];
  }

  String _fmtShortDay(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── slot selection logic ─────────────────────────────────────────────────

  void _toggleSlot(Court court, TimeSlot slot) {
    final now = DateTime.now();
    final effective = slot.effectiveStatus(now);
    if (effective != SlotStatus.available) return;

    setState(() {
      if (_selectedIds.contains(slot.id)) {
        _selectedIds.remove(slot.id);
        _selectedSlots.removeWhere((s) => s.slotId == slot.id);
      } else {
        if (_selectedIds.length >= _kMaxSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can book a maximum of 2 slots per day.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedIds.add(slot.id);
        _selectedSlots.add(_SelectedSlot(
          slotId: slot.id,
          courtName: court.name,
          slotLabel: slot.label,
        ));
      }
    });
  }

  // ── week navigation ──────────────────────────────────────────────────────

  void _prevWeek() => setState(() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
  });

  void _nextWeek() => setState(() {
    _weekStart = _weekStart.add(const Duration(days: 7));
  });

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          _facility.name,
          style:
          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildLegend(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: _facility.courts
                  .map((c) => _buildCourtCard(c))
                  .toList(),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  // ── calendar header ──────────────────────────────────────────────────────

  Widget _buildCalendarHeader() {
    final days = List.generate(5, (i) => _weekStart.add(Duration(days: i)));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Month row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.black),
                onPressed: _prevWeek,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _fmtMonth(_weekStart),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.black),
                onPressed: _nextWeek,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) => _buildDayCell(d)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime d) {
    final isSelected = _isSameDay(d, _selectedDate);
    final isToday = _isSameDay(d, _today());

    return GestureDetector(
      onTap: () => setState(() {
        _selectedDate = d;
        // Clear selection when date changes
        _selectedIds.clear();
        _selectedSlots.clear();
      }),
      child: SizedBox(
        width: 52,
        child: Column(
          children: [
            Text(
              _fmtShortDay(d),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? _kGreen : Colors.black87,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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
              child: Text(
                '${d.day}',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── legend ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(_kAvailableChip, _kAvailableText, 'Available'),
          const SizedBox(width: 24),
          _legendDot(_kUnavailableChip, _kUnavailableText, 'Unavailable'),
        ],
      ),
    );
  }

  Widget _legendDot(Color bg, Color textColor, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: textColor.withOpacity(0.4)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ── court card ───────────────────────────────────────────────────────────

  Widget _buildCourtCard(Court court) {
    final slots = court.slotsForDate(_selectedDate);
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            court.name,
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots
                .map((slot) => _buildSlotChip(court, slot, now))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotChip(Court court, TimeSlot slot, DateTime now) {
    final effective = slot.effectiveStatus(now);
    final isSelected = _selectedIds.contains(slot.id);

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
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          slot.label,
          style: TextStyle(
            color: textColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── bottom summary bar ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final hasSelection = _selectedSlots.isNotEmpty;

    String facilityLine = '';
    String dateLine = '';
    String timeLine = '';
    String totalLine = '';

    if (hasSelection) {
      final first = _selectedSlots.first;
      facilityLine = '${_facility.name} – ${first.courtName}';
      final d = _selectedDate;
      dateLine =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      timeLine = _selectedSlots.map((s) => s.slotLabel).join(', ');
      final total = _selectedSlots.length * _facility.pricePerSlot;
      totalLine = 'RM ${total.toStringAsFixed(2)}';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSelection) ...[
            Text('Facility: $facilityLine',
                style: const TextStyle(fontSize: 13)),
            Text('Date: $dateLine', style: const TextStyle(fontSize: 13)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Time: $timeLine',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Total: $totalLine',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
              onPressed: hasSelection
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentScreen(),
                  ),
                );
              }
                  : null,
              child: const Text(
                'Checkout',
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple data class for a selected slot in the summary bar
// ─────────────────────────────────────────────────────────────────────────────
class _SelectedSlot {
  final String slotId;
  final String courtName;
  final String slotLabel;

  const _SelectedSlot({
    required this.slotId,
    required this.courtName,
    required this.slotLabel,
  });
}