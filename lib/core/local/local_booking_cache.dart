// lib/core/local/local_booking_cache.dart
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/booking_model.dart';
import 'local_database.dart';

const _kBookingTtlMs = 60 * 60 * 1000; // 1 hour

class LocalBookingCache {
  final _db = LocalDatabase.instance;
  final _uuid = const Uuid();

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> saveBookings(List<Booking> bookings) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final b in bookings) {
        await txn.insert(
          'bookings',
          {
            'id': b.id,
            'user_id': b.userId,
            'court_id': b.courtId,
            'facility_id': b.facilityId,
            'date': b.date.toIso8601String().substring(0, 10),
            'start_hour': b.startHour,
            'end_hour': b.endHour,
            'status': b.status,
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<List<Booking>> getMyBookings({bool ignoreExpiry = false}) async {
    final db = await _db.database;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _kBookingTtlMs;

    final rows = ignoreExpiry
        ? await db.query('bookings', orderBy: 'date DESC')
        : await db.query(
      'bookings',
      where: 'cached_at > ?',
      whereArgs: [cutoff],
      orderBy: 'date DESC',
    );

    return rows.map(_rowToBooking).toList();
  }

  Future<bool> hasFreshData() async {
    final db = await _db.database;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _kBookingTtlMs;
    final result = await db.query(
      'bookings',
      where: 'cached_at > ?',
      whereArgs: [cutoff],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ── Pending (offline) bookings ─────────────────────────────────────────────

  /// Queue a booking to be synced once connectivity is restored.
  Future<String> enqueuePendingBooking({
    required String courtId,
    required String facilityId,
    required DateTime date,
    required int startHour,
    required int endHour,
    required double amount,
    required String method,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();

    await db.insert('pending_bookings', {
      'local_id': id,
      'court_id': courtId,
      'facility_id': facilityId,
      'date': date.toIso8601String().substring(0, 10),
      'start_hour': startHour,
      'end_hour': endHour,
      'amount': amount,
      'method': method,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });

    return id;
  }

  Future<List<PendingBooking>> getPendingBookings() async {
    final db = await _db.database;
    final rows = await db.query(
      'pending_bookings',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
    return rows.map(PendingBooking.fromMap).toList();
  }

  Future<void> markSynced(String localId) async {
    final db = await _db.database;
    await db.update(
      'pending_bookings',
      {'synced': 1},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> deleteSynced() async {
    final db = await _db.database;
    await db.delete('pending_bookings', where: 'synced = ?', whereArgs: [1]);
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('bookings');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Booking _rowToBooking(Map<String, dynamic> r) => Booking(
    id: r['id'] as String,
    userId: r['user_id'] as String,
    courtId: r['court_id'] as String,
    facilityId: r['facility_id'] as String,
    date: DateTime.parse(r['date'] as String),
    startHour: r['start_hour'] as int,
    endHour: r['end_hour'] as int,
    status: r['status'] as String,
  );
}

class PendingBooking {
  final String localId;
  final String courtId;
  final String facilityId;
  final DateTime date;
  final int startHour;
  final int endHour;
  final double amount;
  final String method;
  final DateTime createdAt;

  const PendingBooking({
    required this.localId,
    required this.courtId,
    required this.facilityId,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.amount,
    required this.method,
    required this.createdAt,
  });

  factory PendingBooking.fromMap(Map<String, dynamic> m) => PendingBooking(
    localId: m['local_id'] as String,
    courtId: m['court_id'] as String,
    facilityId: m['facility_id'] as String,
    date: DateTime.parse(m['date'] as String),
    startHour: m['start_hour'] as int,
    endHour: m['end_hour'] as int,
    amount: m['amount'] as double,
    method: m['method'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}