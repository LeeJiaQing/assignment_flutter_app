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

  Timer? _clockTimer;
  int _loadVersion = 0;

  late DateTime _selectedDate;
  late DateTime _weekStart;

  final Map<String, Set<int>> _bookedHoursCache = {};
  final Map<String, ScheduleStatus> _courtStatus = {};
  final Map<String, SelectedSlot> _selectedSlots = {};

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Facility get facility => _facility;
  DateTime get selectedDate => _selectedDate;
  DateTime get weekStart => _weekStart;
  Map<String, SelectedSlot> get selectedSlots =>
      Map.unmodifiable(_selectedSlots);
  bool get hasSelection => _selectedSlots.isNotEmpty;
  double get grandTotal => _selectedSlots.length * _facility.pricePerSlot;

  bool isCourtLoading(String courtId) =>
      _courtStatus[courtId] == ScheduleStatus.loading;

  String get formattedDate {
    final d = _selectedDate;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[d.month - 1];
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      final before = _selectedSlots.length;
      _selectedSlots.removeWhere(
        (_, selected) => selected.slot.effectiveStatus(now) == SlotStatus.expired,
      );
      if (_selectedSlots.length != before || isToday(_selectedDate)) {
        notifyListeners();
      }
    });
  }

  String _cacheKey(String courtId, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return '$courtId-${normalizedDate.toIso8601String()}';
  }

  List<TimeSlot> slotsForCourt(String courtId) {
    final bookedHours = _bookedHoursCache[_cacheKey(courtId, _selectedDate)] ?? {};
    return List.generate(
      _facility.closeHour - _facility.openHour,
      (i) {
        final h = _facility.openHour + i;
        return TimeSlot(
          courtId: courtId,
          date: _selectedDate,
          startHour: h,
          endHour: h + 1,
          status:
              bookedHours.contains(h) ? SlotStatus.booked : SlotStatus.available,
        );
      },
    );
  }

  Future<void> loadBookedHoursForDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final requestVersion = ++_loadVersion;

    for (final court in _facility.courts) {
      _courtStatus[court.id] = ScheduleStatus.loading;
    }
    notifyListeners();

    final futures = _facility.courts.map((court) async {
      try {
        final hours = await _service.fetchBookedHours(
          courtId: court.id,
          date: normalizedDate,
        );

        if (requestVersion != _loadVersion) {
          return;
        }

        _bookedHoursCache[_cacheKey(court.id, normalizedDate)] = hours;
        _courtStatus[court.id] = ScheduleStatus.loaded;
      } catch (_) {
        if (requestVersion != _loadVersion) {
          return;
        }
        _courtStatus[court.id] = ScheduleStatus.error;
      }
    });

    await Future.wait(futures);

    if (requestVersion == _loadVersion) {
      notifyListeners();
    }
  }

  String? toggleSlot(Court court, TimeSlot slot) {
    final effective = slot.effectiveStatus(DateTime.now());
    if (effective != SlotStatus.available) return null;

    if (_selectedSlots.containsKey(slot.id)) {
      _selectedSlots.remove(slot.id);
      notifyListeners();
      return null;
    }

    if (_selectedSlots.length >= kMaxSlotsPerDay) {
      return 'You can book a maximum of $kMaxSlotsPerDay slots per day.';
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

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _selectedSlots.clear();
    notifyListeners();
    loadBookedHoursForDate(_selectedDate);
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
