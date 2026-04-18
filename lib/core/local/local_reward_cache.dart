import 'package:sqflite/sqflite.dart';

import '../../features/rewardPoints/viewmodels/reward_points_view_model.dart';
import 'local_database.dart';

const _kRewardTtlMs = 24 * 60 * 60 * 1000; // 24 hours

class LocalRewardCache {
  final _db = LocalDatabase.instance;

  Future<void> saveTransactions({
    required String userId,
    required List<RewardTransaction> transactions,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'reward_transaction_cache',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      for (final t in transactions) {
        await txn.insert(
          'reward_transaction_cache',
          {
            'id': t.id,
            'user_id': userId,
            'points': t.points,
            'description': t.description,
            'created_at': t.createdAt.toIso8601String(),
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<RewardTransaction>> getTransactions({
    required String userId,
    bool ignoreExpiry = false,
  }) async {
    final db = await _db.database;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _kRewardTtlMs;

    final rows = await db.query(
      'reward_transaction_cache',
      where: ignoreExpiry ? 'user_id = ?' : 'user_id = ? AND cached_at > ?',
      whereArgs: ignoreExpiry ? [userId] : [userId, cutoff],
      orderBy: 'created_at DESC',
    );

    return rows
        .map(
          (r) => RewardTransaction(
            id: r['id'] as String,
            points: r['points'] as int,
            description: r['description'] as String,
            createdAt: DateTime.parse(r['created_at'] as String),
          ),
        )
        .toList();
  }
}
