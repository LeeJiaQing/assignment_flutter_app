// lib/models/facility_seed.dart
import 'court_model.dart';

/// Generates a [Facility] with realistic fake schedules across multiple dates.
Facility getFacility() {
  return Facility(
    id: 'f1',
    name: 'Arena Pickleball Court',
    courts: [
      _buildCourt('c1', 'Court 1'),
      _buildCourt('c2', 'Court 2'),
    ],
  );
}

Court _buildCourt(String id, String name) {
  final Map<String, List<TimeSlot>> schedule = {};

  // Build slots for today ± 14 days so any week the user browses has data.
  final today = DateTime.now();
  for (int offset = -2; offset <= 14; offset++) {
    final date = today.add(Duration(days: offset));
    final key = _key(date);
    schedule[key] = _slotsForDate(id, date);
  }

  return Court(id: id, name: name, scheduleByDate: schedule);
}

List<TimeSlot> _slotsForDate(String courtId, DateTime date) {
  // Fixed hour pairs that make up the day's schedule
  const hourPairs = [
    [8, 9],
    [9, 10],
    [10, 11],
    [11, 12],
    [12, 13],
    [13, 14],
    [14, 15],
    [15, 16],
    [16, 17],
    [17, 18],
    [18, 19],
  ];

  // Deterministically mark some slots as booked so different dates look different
  final bookedHours = _bookedHoursForDate(courtId, date);

  return hourPairs.map((pair) {
    final start = DateTime(date.year, date.month, date.day, pair[0]);
    final end = DateTime(date.year, date.month, date.day, pair[1]);
    final label = '${_fmt(pair[0])} - ${_fmt(pair[1])}';
    final isBooked = bookedHours.contains(pair[0]);

    return TimeSlot(
      id: '${courtId}_${_key(date)}_${pair[0]}',
      label: label,
      start: start,
      end: end,
      status: isBooked ? SlotStatus.booked : SlotStatus.available,
    );
  }).toList();
}

/// Returns a set of starting hours that are pre-booked for this court+date combo.
Set<int> _bookedHoursForDate(String courtId, DateTime date) {
  // Use a simple hash so each court/date combo has different booked slots.
  final seed = date.day + date.month * 31 + courtId.codeUnits.first;
  final options = [9, 11, 13, 15, 17];
  return {options[seed % options.length], options[(seed + 2) % options.length]};
}

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmt(int hour) {
  final suffix = hour < 12 ? 'AM' : 'PM';
  final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$h:00 $suffix';
}