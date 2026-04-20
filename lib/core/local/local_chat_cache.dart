import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

const _kChatTtlMs = 7 * 24 * 60 * 60 * 1000; // 7 days

class LocalChatCache {
  final _db = LocalDatabase.instance;

  Future<void> saveMessages({
    required String channelId,
    required List<Map<String, dynamic>> messages,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'chat_message_cache',
        where: 'channel_id = ?',
        whereArgs: [channelId],
      );

      for (final m in messages) {
        await txn.insert(
          'chat_message_cache',
          {
            'id': m['id'] as String,
            'channel_id': channelId,
            'sender_id': m['sender_id'] as String,
            'sender_name': m['sender_name'] as String,
            'content': m['content'] as String,
            'created_at': m['created_at'] as String,
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required String channelId,
    bool ignoreExpiry = false,
  }) async {
    final db = await _db.database;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _kChatTtlMs;

    final rows = await db.query(
      'chat_message_cache',
      where: ignoreExpiry
          ? 'channel_id = ?'
          : 'channel_id = ? AND cached_at > ?',
      whereArgs: ignoreExpiry ? [channelId] : [channelId, cutoff],
      orderBy: 'created_at ASC',
    );

    return rows
        .map((r) => {
              'id': r['id'] as String,
              'sender_id': r['sender_id'] as String,
              'sender_name': r['sender_name'] as String,
              'content': r['content'] as String,
              'created_at': r['created_at'] as String,
            })
        .toList();
  }

  Future<void> upsertMessage({
    required String channelId,
    required Map<String, dynamic> message,
  }) async {
    final db = await _db.database;
    await db.insert(
      'chat_message_cache',
      {
        'id': message['id'] as String,
        'channel_id': channelId,
        'sender_id': message['sender_id'] as String,
        'sender_name': message['sender_name'] as String,
        'content': message['content'] as String,
        'created_at': message['created_at'] as String,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
