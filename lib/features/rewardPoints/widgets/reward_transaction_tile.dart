// lib/features/rewardPoints/widgets/reward_transaction_tile.dart
import 'package:flutter/material.dart';

import '../viewmodels/reward_points_view_model.dart';

class RewardTransactionTile extends StatelessWidget {
  const RewardTransactionTile({super.key, required this.transaction});

  final RewardTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isEarned = transaction.isEarned;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isEarned
            ? const Color(0xFFD6F0E0)
            : const Color(0xFFFFE5E5),
        child: Icon(
          isEarned ? Icons.add : Icons.remove,
          color: isEarned ? const Color(0xFF1C894E) : Colors.red.shade400,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _formatDate(transaction.createdAt),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      trailing: Text(
        '${isEarned ? '+' : ''}${transaction.points} pts',
        style: TextStyle(
          color: isEarned ? const Color(0xFF1C894E) : Colors.red.shade400,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
