// lib/features/booking/viewmodels/booking_schedule_view_model.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/booking_service.dart';
import '../../../models/booking_model.dart';
import '../../../models/facility_model.dart';

const int kMaxSlotsPerDay = 2;

class SelectedSlot {
  final TimeSlot slot;
  final String courtId;
  final String courtName;

  const SelectedSlot({
    required this.slot,
    required this.courtId,
    required this.courtName,
  });
}

enum ScheduleStatus { initial, loading, loaded, error }

class BookingScheduleViewModel extends ChangeNotifier {
  Timer? _clockTimer;

  BookingScheduleViewModel({
    required BookingService bookingService,
    required Facility facility,
  })  : _service = bookingService,
        _facility = facility {
    _selectedDate = _today();
    _weekStart = _mondayOf(_selectedDate);
    _startClock();
  }

  final BookingService _service;
  final Facility _facility;

  late DateTime _selectedDate;
  late DateTime _weekStart;

  final Map<String, Set<int>> _bookedHoursCache = {};
  final Map<String, ScheduleStatus> _courtStatus = {};
  final Map<String, SelectedSlot> _selectedSlots = {};

  // Tracks how many slots the user already has confirmed for this
  // facility on the currently selected date (fetched from Supabase).
  int _existingBookingCount = 0;

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  Facility get facility => _facility;
  DateTime get selectedDate => _selectedDate;
  DateTime get weekStart => _weekStart;
  Map<String, SelectedSlot> get selectedSlots =>
      Map.unmodifiable(_selectedSlots);
  bool get hasSelection => _selectedSlots.isNotEmpty;
  double get grandTotal => _selectedSlots.length * _facility.pricePerSlot;

  /// How many more slots the user is allowed to add today for this facility.
  int get remainingSlots =>
      kMaxSlotsPerDay - _existingBookingCount - _selectedSlots.length;

  bool isCourtLoading(String courtId) =>
      _courtStatus[courtId] == ScheduleStatus.loading;

  String get formattedDate {
    final d = _selectedDate;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isToday(DateTime d) => isSameDay(d, _today());

  List<DateTime> get weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  String fmtShortDay(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  String fmtMonth(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[d.month - 1];
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      _selectedSlots.removeWhere((_, selected) {
        return selected.slot.effectiveStatus(now) == SlotStatus.expired;
      });
      notifyListeners();
    });
  }

  // ── Slot generation ───────────────────────────────────────────────────────

  List<TimeSlot> slotsForCourt(String courtId) {
    final bookedHours = _bookedHoursCache[courtId] ?? {};
    return List.generate(
      _facility.closeHour - _facility.openHour,
          (i) {
        final h = _facility.openHour + i;
        return TimeSlot(
          courtId: courtId,
          date: _selectedDate,
          startHour: h,
          endHour: h + 1,
          status: bookedHours.contains(h)
              ? SlotStatus.booked
              : SlotStatus.available,
        );
      },
    );
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  /// Loads both booked hours (for slot display) AND the user's existing
  /// confirmed bookings for this facility on [date] (for the daily cap).
  Future<void> loadBookedHoursForDate(DateTime date) async {
    // 1. Load per-court booked hours (for slot grid display)
    for (final court in _facility.courts) {
      if (_courtStatus[court.id] == ScheduleStatus.loading) continue;
      _courtStatus[court.id] = ScheduleStatus.loading;
      notifyListeners();

      try {
        final hours = await _service.fetchBookedHours(
            courtId: court.id, date: date);
        _bookedHoursCache[court.id] = hours;
        _courtStatus[court.id] = ScheduleStatus.loaded;
      } catch (_) {
        _courtStatus[court.id] = ScheduleStatus.error;
      }
      notifyListeners();
    }

    // 2. Count existing confirmed/pending bookings for this user on this
    //    facility + date so we can enforce kMaxSlotsPerDay across sessions.
    await _loadExistingBookingCount(date);
  }

  /// Counts how many active bookings (confirmed or pending) the current user
  /// already has for this facility on the given date.
  Future<void> _loadExistingBookingCount(DateTime date) async {
    try {
      final allBookings = await _service.fetchMyBookingsWithFacilities();
      final dateStr = date.toIso8601String().substring(0, 10);

      _existingBookingCount = allBookings.where((bwf) {
        final b = bwf.booking;
        final bDate = b.date.toIso8601String().substring(0, 10);
        return b.facilityId == _facility.id &&
            bDate == dateStr &&
            (b.status == 'confirmed' || b.status == 'pending');
      }).length;

      notifyListeners();
    } catch (_) {
      // If we can't fetch, be conservative: don't block the user,
      // the in-session counter (_selectedSlots) still applies.
      _existingBookingCount = 0;
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  /// Tries to toggle a slot. Returns an error string if the action is not
  /// allowed, or null on success.
  String? toggleSlot(Court court, TimeSlot slot) {
    final effective = slot.effectiveStatus(DateTime.now());
    if (effective != SlotStatus.available) return null;

    // Deselect if already selected
    if (_selectedSlots.containsKey(slot.id)) {
      _selectedSlots.remove(slot.id);
      notifyListeners();
      return null;
    }

    // Check daily cap (existing confirmed + current in-session selections)
    final totalAfterAdd = _existingBookingCount + _selectedSlots.length + 1;
    if (totalAfterAdd > kMaxSlotsPerDay) {
      final alreadyBooked = _existingBookingCount > 0
          ? ' You already have $_existingBookingCount confirmed booking${_existingBookingCount > 1 ? 's' : ''} on this date.'
          : '';
      return 'Maximum $kMaxSlotsPerDay slots per facility per day.$alreadyBooked';
    }

    _selectedSlots[slot.id] = SelectedSlot(
      slot: slot,
      courtId: court.id,
      courtName: court.name,
    );
    notifyListeners();
    return null;
  }

  bool isSlotSelected(String slotId) => _selectedSlots.containsKey(slotId);

  // ── Navigation ────────────────────────────────────────────────────────────

  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedSlots.clear();
    _existingBookingCount = 0; // reset while new count loads
    notifyListeners();
    loadBookedHoursForDate(date);
  }

  void previousWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    notifyListeners();
  }

  void nextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    notifyListeners();
  }
}