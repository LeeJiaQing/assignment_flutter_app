// lib/models/facility_seed.dart
import 'court_model.dart';
import 'facility_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Catalogue of facilities with different operating hours & prices
// ─────────────────────────────────────────────────────────────────────────────

final List<Facility> facilityList = [
  buildFacility(
    id: 'f1',
    name: 'Arena Pickleball Court',
    address: '12, Jalan Helang Bald, Kepong Baru, Tambahan, Kuala Lumpur',
    imagePath: 'assets/images/facility/facility.png',
    courtCount: 2,
    openHour: 8,
    closeHour: 20,
    pricePerSlot: 8.0,
  ),
  buildFacility(
    id: 'f2',
    name: 'Kepong Pickleball',
    address: '45, Jalan Kepong, Kepong, Kuala Lumpur',
    imagePath: 'assets/images/facility/facility.png',
    courtCount: 3,
    openHour: 7,
    closeHour: 22,
    pricePerSlot: 10.0,
  ),
  buildFacility(
    id: 'f3',
    name: 'Banting Badminton Court',
    address: '88, Jalan Banting, Banting, Selangor',
    imagePath: 'assets/images/facility/facility.png',
    courtCount: 4,
    openHour: 6,
    closeHour: 23,
    pricePerSlot: 6.0,
  ),
  buildFacility(
    id: 'f4',
    name: 'PJ Sports Arena',
    address: '3, Jalan SS2/64, Petaling Jaya, Selangor',
    imagePath: 'assets/images/facility/facility.png',
    courtCount: 2,
    openHour: 9,
    closeHour: 21,
    pricePerSlot: 12.0,
  ),
  buildFacility(
    id: 'f5',
    name: 'Cheras Futsal Hub',
    address: '20, Jalan Cheras, Kuala Lumpur',
    imagePath: 'assets/images/facility/facility.png',
    courtCount: 2,
    openHour: 10,
    closeHour: 24,
    pricePerSlot: 15.0,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Factory that builds a Facility with dynamically generated schedules
// ─────────────────────────────────────────────────────────────────────────────

Facility buildFacility({
  required String id,
  required String name,
  required String address,
  required String imagePath,
  required int courtCount,
  required int openHour,
  required int closeHour,
  required double pricePerSlot,
}) {
  final courts = List.generate(
    courtCount,
        (i) => _buildCourt(
      id: '${id}_c${i + 1}',
      name: 'Court ${i + 1}',
      openHour: openHour,
      closeHour: closeHour,
    ),
  );

  return Facility(
    id: id,
    name: name,
    address: address,
    imagePath: imagePath,
    courts: courts,
    openHour: openHour,
    closeHour: closeHour,
    pricePerSlot: pricePerSlot,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

Court _buildCourt({
  required String id,
  required String name,
  required int openHour,
  required int closeHour,
}) {
  final Map<String, List<TimeSlot>> schedule = {};
  final today = DateTime.now();

  for (int offset = -2; offset <= 14; offset++) {
    final date = today.add(Duration(days: offset));
    final key = _key(date);
    schedule[key] = _slotsForDate(
      courtId: id,
      date: date,
      openHour: openHour,
      closeHour: closeHour,
    );
  }

  return Court(id: id, name: name, scheduleByDate: schedule);
}

List<TimeSlot> _slotsForDate({
  required String courtId,
  required DateTime date,
  required int openHour,
  required int closeHour,
}) {
  // Generate 1-hour pairs from openHour to closeHour
  final hourPairs = <List<int>>[];
  for (int h = openHour; h < closeHour; h++) {
    hourPairs.add([h, h + 1]);
  }

  final bookedHours = _bookedHoursForDate(courtId, date, openHour, closeHour);

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

/// Deterministic pseudo-random booked slots per court+date.
Set<int> _bookedHoursForDate(
    String courtId, DateTime date, int openHour, int closeHour) {
  final seed = date.day + date.month * 31 + courtId.codeUnits.first;
  final available = List.generate(closeHour - openHour, (i) => openHour + i);
  if (available.isEmpty) return {};
  return {
    available[seed % available.length],
    available[(seed + 2) % available.length],
    available[(seed + 4) % available.length],
  };
}

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmt(int hour) {
  final suffix = hour < 12 ? 'AM' : 'PM';
  final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$h:00 $suffix';
}