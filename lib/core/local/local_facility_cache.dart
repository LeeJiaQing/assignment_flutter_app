// lib/core/local/local_facility_cache.dart

// Directives must appear before declarations
export 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import 'package:sqflite/sqflite.dart';
import '../../models/facility_model.dart';
import 'local_database.dart';

/// Cache TTL: 30 minutes
const _kTtlMs = 30 * 60 * 1000;

class LocalFacilityCache {
  final _db = LocalDatabase.instance;

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> saveFacilities(List<Facility> facilities) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final f in facilities) {
        await txn.insert(
          'facilities',
          {
            'id': f.id,
            'name': f.name,
            'address': f.address,
            'image_url': f.imageUrl,
            'open_hour': f.openHour,
            'close_hour': f.closeHour,
            'price_per_slot': f.pricePerSlot,
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Upsert courts
        await txn.delete('courts',
            where: 'facility_id = ?', whereArgs: [f.id]);
        for (final c in f.courts) {
          await txn.insert('courts', {
            'id': c.id,
            'facility_id': c.facilityId,
            'name': c.name,
          });
        }
      }
    });
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<List<Facility>> getFacilities({bool ignoreExpiry = false}) async {
    final db = await _db.database;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _kTtlMs;

    final rows = ignoreExpiry
        ? await db.query('facilities', orderBy: 'name ASC')
        : await db.query(
      'facilities',
      where: 'cached_at > ?',
      whereArgs: [cutoff],
      orderBy: 'name ASC',
    );

    if (rows.isEmpty) return [];

    final courts = await db.query('courts');
    final courtsByFacility = <String, List<Court>>{};
    for (final c in courts) {
      final fid = c['facility_id'] as String;
      courtsByFacility.putIfAbsent(fid, () => []).add(Court(
        id: c['id'] as String,
        facilityId: fid,
        name: c['name'] as String,
      ));
    }

    return rows.map((r) {
      final id = r['id'] as String;
      return Facility(
        id: id,
        name: r['name'] as String,
        address: r['address'] as String,
        imageUrl: r['image_url'] as String?,
        openHour: r['open_hour'] as int,
        closeHour: r['close_hour'] as int,
        pricePerSlot: r['price_per_slot'] as double,
        courts: courtsByFacility[id] ?? [],
      );
    }).toList();
  }

  Future<Facility?> getFacility(String id) async {
    final all = await getFacilities(ignoreExpiry: true);
    try {
      return all.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasFreshData() async {
    final db = await _db.database;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _kTtlMs;
    final result = await db.query(
      'facilities',
      where: 'cached_at > ?',
      whereArgs: [cutoff],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('courts');
      await txn.delete('facilities');
    });
  }

  Future<void> clearFacility(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('courts', where: 'facility_id = ?', whereArgs: [id]);
      await txn.delete('facilities', where: 'id = ?', whereArgs: [id]);
    });
  }
}