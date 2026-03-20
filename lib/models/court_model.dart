// lib/models/court_model.dart

enum SlotStatus { available, booked, expired }

class TimeSlot {
  final String id;
  final String label; // e.g. "8:00 AM - 9:00 AM"
  final DateTime start;
  final DateTime end;
  SlotStatus status;

  TimeSlot({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    this.status = SlotStatus.available,
  });

  /// Recompute expired status relative to [now].
  SlotStatus effectiveStatus(DateTime now) {
    if (status == SlotStatus.booked) return SlotStatus.booked;
    if (start.isBefore(now)) return SlotStatus.expired;
    return SlotStatus.available;
  }
}

class Court {
  final String id;
  final String name; // e.g. "Court 1"
  /// key = date string "yyyy-MM-dd", value = list of slots for that day
  final Map<String, List<TimeSlot>> scheduleByDate;

  Court({
    required this.id,
    required this.name,
    required this.scheduleByDate,
  });

  List<TimeSlot> slotsForDate(DateTime date) {
    final key = _dateKey(date);
    return scheduleByDate[key] ?? [];
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class Facility {
  final String id;
  final String name;
  final List<Court> courts;

  Facility({
    required this.id,
    required this.name,
    required this.courts,
  });
}