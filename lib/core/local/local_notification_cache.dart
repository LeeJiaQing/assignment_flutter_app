import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

const _kNotificationTtlMs = 24 * 60 * 60 * 1000; // 24 hours

class LocalNotificationCache {
  final _db = LocalDatabase.instance;

  Future<void> saveNotifications({
    required String userId,
    required List<Map<String, dynamic>> rows,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'notification_cache',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      for (final row in rows) {
        await txn.insert(
          'notification_cache',
          {
            'id': row['id'] as String,
            'user_id': userId,
            'type': (row['type'] as String?) ?? 'unknown',
            'title': (row['title'] as String?) ?? '',
            'body': (row['body'] as String?) ?? '',
            'data_json': jsonEncode(_asMap(row['data'])),
            'is_read': ((row['is_read'] as bool?) ?? false) ? 1 : 0,
            'created_at': (row['created_at'] as String?) ?? DateTime.now().toIso8601String(),
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    required String userId,
    bool ignoreExpiry = false,
  }) async {
    final db = await _db.database;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _kNotificationTtlMs;

    final rows = await db.query(
      'notification_cache',
      where: ignoreExpiry ? 'user_id = ?' : 'user_id = ? AND cached_at > ?',
      whereArgs: ignoreExpiry ? [userId] : [userId, cutoff],
      orderBy: 'created_at DESC',
    );

    return rows
        .map((r) => {
              'id': r['id'] as String,
              'user_id': r['user_id'] as String,
              'type': r['type'] as String? ?? 'unknown',
              'title': r['title'] as String,
              'body': r['body'] as String,
              'data': _decodeData(r['data_json'] as String?),
              'is_read': (r['is_read'] as int) == 1,
              'created_at': r['created_at'] as String,
            })
        .toList();
  }

  Future<void> markRead({
    required String userId,
    required String notificationId,
  }) async {
    final db = await _db.database;
    await db.update(
      'notification_cache',
      {'is_read': 1},
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, notificationId],
    );
  }

  Future<void> markAllRead({required String userId}) async {
    final db = await _db.database;
    await db.update(
      'notification_cache',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  Map<String, dynamic> _decodeData(String? encoded) {
    if (encoded == null || encoded.isEmpty) return {};
    try {
      final parsed = jsonDecode(encoded);
      if (parsed is Map<String, dynamic>) return parsed;
      return {};
    } catch (_) {
      return {};
    }
  }
}
