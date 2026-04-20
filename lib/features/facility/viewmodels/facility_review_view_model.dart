// lib/features/facility/viewmodels/facility_review_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';

class FacilityReview {
  final String id;
  final String userId;
  final String authorName;
  final String facilityId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const FacilityReview({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.facilityId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory FacilityReview.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String;
    final fullName = (json['profiles'] as Map?)?['full_name'] as String?;
    final fallbackSuffix =
        userId.length >= 6 ? userId.substring(0, 6) : userId;
    final authorName = (fullName?.trim().isNotEmpty ?? false)
        ? fullName!.trim()
        : 'User $fallbackSuffix';

    return FacilityReview(
      id: json['id'] as String,
      userId: userId,
      authorName: authorName,
      facilityId: json['facility_id'] as String,
      rating: json['rating'] as int,
      comment: (json['review'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

enum ReviewStatus { initial, loading, loaded, error }

class FacilityReviewViewModel extends ChangeNotifier {
  FacilityReviewViewModel({required this.facilityId});

  final String facilityId;

  ReviewStatus _status = ReviewStatus.initial;
  List<FacilityReview> _reviews = [];
  String? _errorMessage;

  ReviewStatus get status => _status;
  List<FacilityReview> get reviews => _reviews;
  String? get errorMessage => _errorMessage;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (sum, r) => sum + r.rating) / _reviews.length;
  }

  Future<void> loadReviews() async {
    _status = ReviewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('facility_ratings')
          .select('*, profiles(full_name)')
          .eq('facility_id', facilityId)
          .not('review', 'is', null)
          .neq('review', '')
          .order('created_at', ascending: false);

      _reviews = (response as List<dynamic>)
          .map((json) => FacilityReview.fromJson(json as Map<String, dynamic>))
          .toList();
      _status = ReviewStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ReviewStatus.error;
    }

    notifyListeners();
  }

  Future<bool> submitReview({required int rating, required String comment}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('facility_ratings').upsert({
        'user_id': userId,
        'facility_id': facilityId,
        'rating': rating,
        'review': comment.trim(),
      }, onConflict: 'facility_id,user_id');

      await _refreshAverageRatingColumn();
      await loadReviews();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _refreshAverageRatingColumn() async {
    final response = await supabase
        .from('facility_ratings')
        .select('rating')
        .eq('facility_id', facilityId);

    final ratings = (response as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['rating'] as int)
        .toList();

    final average = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    await supabase
        .from('facilities')
        .update({'average_rating': average})
        .eq('id', facilityId);
  }
}
