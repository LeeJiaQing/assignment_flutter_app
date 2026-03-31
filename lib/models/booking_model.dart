// lib/models/booking_model.dart

enum SlotStatus { available, booked, expired }

class TimeSlot {
  final String courtId;
  final DateTime date;
  final int startHour;
  final int endHour;
  SlotStatus status;

  TimeSlot({
    required this.courtId,
    required this.date,
    required this.startHour,
    required this.endHour,
    this.status = SlotStatus.available,
  });

  String get id =>
      '${courtId}_${date.toIso8601String().substring(0, 10)}_$startHour';

  String get label {
    String fmt(int h) {
      final suffix = h < 12 ? 'AM' : 'PM';
      final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$v:00 $suffix';
    }
    return '${fmt(startHour)} - ${fmt(endHour)}';
  }

  SlotStatus effectiveStatus(DateTime now) {
    if (status == SlotStatus.booked) return SlotStatus.booked;
    final slotStart = DateTime(date.year, date.month, date.day, startHour);
    // Treat slot as expired as soon as its start time is reached.
    // Using only `isBefore` can leave boundary-time cases (exact hour)
    // incorrectly shown as available on some devices.
    if (!slotStart.isAfter(now)) return SlotStatus.expired;
    return SlotStatus.available;
  }
}

class Booking {
  final String id;
  final String userId;
  final String courtId;
  final String facilityId;
  final DateTime date;
  final int startHour;
  final int endHour;
  final String status; // pending | confirmed | cancelled

  const Booking({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.facilityId,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    courtId: json['court_id'] as String,
    facilityId: json['facility_id'] as String,
    date: DateTime.parse(json['date'] as String),
    startHour: json['start_hour'] as int,
    endHour: json['end_hour'] as int,
    status: json['status'] as String,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'court_id': courtId,
    'facility_id': facilityId,
    'date': date.toIso8601String().substring(0, 10),
    'start_hour': startHour,
    'end_hour': endHour,
    'status': status,
  };
}

class Payment {
  final String bookingId;
  final String userId;
  final double amount;
  final String method; // tng | card | banking

  const Payment({
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'user_id': userId,
    'amount': amount,
    'method': method,
    'status': 'paid',
  };
}
