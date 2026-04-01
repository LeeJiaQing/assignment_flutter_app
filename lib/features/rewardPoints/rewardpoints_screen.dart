// lib/features/rewardPoints/rewardpoints_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/reward_points_view_model.dart';
import 'widgets/reward_transaction_tile.dart';

class RewardPointsScreen extends StatelessWidget {
  const RewardPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RewardPointsViewModel()..loadRewards(),
      child: const _RewardPointsView(),
    );
  }
}

class _RewardPointsView extends StatelessWidget {
  const _RewardPointsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RewardPointsViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(title: const Text('Reward Points')),
      body: switch (vm.status) {
        RewardStatus.initial ||
        RewardStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        RewardStatus.error => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  vm.errorMessage ?? 'Failed to load rewards',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<RewardPointsViewModel>().loadRewards(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        RewardStatus.loaded => Column(
            children: [
              _PointsBanner(points: vm.totalPoints),
              // How to earn/redeem info
              _InfoCard(),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Transaction History',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1C3A2A)),
                  ),
                ),
              ),
              Expanded(
                child: vm.transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions yet.\nStart booking to earn points!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<RewardPointsViewModel>().loadRewards(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: vm.transactions.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (_, i) => RewardTransactionTile(
                            transaction: vm.transactions[i],
                          ),
                        ),
                      ),
              ),
            ],
          ),
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF1C894E), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Earn 1 pt per RM 1 spent. Redeem 100 pts = RM 1 discount at checkout.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1C3A2A),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C894E), Color(0xFF6DCC98)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C894E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$points pts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ RM ${(points / 100).toStringAsFixed(2)} discount value',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
