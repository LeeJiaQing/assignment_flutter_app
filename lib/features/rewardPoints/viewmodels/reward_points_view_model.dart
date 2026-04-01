// lib/features/rewardPoints/viewmodels/reward_points_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';

enum RewardStatus { initial, loading, loaded, error }

class RewardTransaction {
  final String id;
  final int points;
  final String description;
  final DateTime createdAt;

  const RewardTransaction({
    required this.id,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  bool get isEarned => points > 0;

  factory RewardTransaction.fromJson(Map<String, dynamic> json) =>
      RewardTransaction(
        id: json['id'] as String,
        points: json['points'] as int,
        description: json['description'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class RewardPointsViewModel extends ChangeNotifier {
  RewardStatus _status = RewardStatus.initial;
  int _totalPoints = 0;
  List<RewardTransaction> _transactions = [];
  String? _errorMessage;

  RewardStatus get status => _status;
  int get totalPoints => _totalPoints;
  List<RewardTransaction> get transactions => _transactions;
  String? get errorMessage => _errorMessage;

  Future<void> loadRewards() async {
    _status = RewardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _status = RewardStatus.loaded;
        notifyListeners();
        return;
      }

      final response = await supabase
          .from('reward_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _transactions = (response as List<dynamic>)
          .map((json) => RewardTransaction.fromJson(
          json as Map<String, dynamic>))
          .toList();

      _totalPoints = _transactions.fold(0, (sum, t) => sum + t.points);
      _status = RewardStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = RewardStatus.error;
    }

    notifyListeners();
  }

  /// Earn points after a successful payment.
  /// Awards 1 point per RM 1 spent (rounded down).
  static Future<void> earnPoints({
    required double amount,
    required String description,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final points = amount.floor(); // 1 point per RM 1
      if (points <= 0) return;

      await supabase.from('reward_transactions').insert({
        'user_id': userId,
        'points': points,
        'description': description,
      });
    } catch (e) {
      // Silently fail — don't block payment flow
      debugPrint('RewardPoints.earnPoints error: $e');
    }
  }

  /// Redeem points for a discount. 100 points = RM 1.
  /// Returns true if redemption succeeded.
  static Future<bool> redeemPoints({
    required int points,
    required String description,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('reward_transactions').insert({
        'user_id': userId,
        'points': -points, // negative = redemption
        'description': description,
      });
      return true;
    } catch (e) {
      debugPrint('RewardPoints.redeemPoints error: $e');
      return false;
    }
  }

  /// Get total available points for current user.
  static Future<int> getAvailablePoints() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await supabase
          .from('reward_transactions')
          .select('points')
          .eq('user_id', userId);

      final total = (response as List<dynamic>)
          .fold<int>(0, (sum, row) => sum + (row['points'] as int));
      return total < 0 ? 0 : total;
    } catch (_) {
      return 0;
    }
  }
}
