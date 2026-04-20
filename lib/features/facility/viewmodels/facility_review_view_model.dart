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

  factory FacilityReview.fromJson(
    Map<String, dynamic> json, {
    String? resolvedAuthorName,
  }) {
    final userId = json['user_id'] as String;
    final fullName =
        resolvedAuthorName ?? (json['profiles'] as Map?)?['full_name'] as String?;
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
      rating: _parseRating(json['rating']),
      comment: (json['review'] ?? json['comment']) as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static int _parseRating(dynamic rating) {
    if (rating is int) return rating;
    if (rating is num) return rating.toInt();
    return int.parse(rating.toString());
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
      final rows = await _fetchRowsWithFacilityIdFallback();
      final filteredRows = rows.where((row) {
        final text = ((row['review'] ?? row['comment']) as String?)?.trim() ??
            '';
        return text.isNotEmpty;
      }).toList();

      final userIds = filteredRows
          .map((row) => row['user_id'] as String)
          .toSet()
          .toList();

      final authorNameById = <String, String>{};
      if (userIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', userIds);

        for (final row in (profiles as List<dynamic>).cast<Map<String, dynamic>>()) {
          final id = row['id'] as String?;
          final fullName = (row['full_name'] as String?)?.trim();
          if (id != null && fullName != null && fullName.isNotEmpty) {
            authorNameById[id] = fullName;
          }
        }
      }

      _reviews = filteredRows
          .map(
            (json) => FacilityReview.fromJson(
              json,
              resolvedAuthorName: authorNameById[json['user_id'] as String],
            ),
          )
          .toList();
      _status = ReviewStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ReviewStatus.error;
    }

    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _fetchRowsWithFacilityIdFallback() async {
    final response = await supabase
        .from('facility_ratings')
        .select('*')
        .eq('facility_id', facilityId)
        .order('created_at', ascending: false);

    final primaryRows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    if (primaryRows.isNotEmpty) return primaryRows;

    final candidateIds = <String>{facilityId};
    try {
      final facilityRow = await supabase
          .from('facilities')
          .select('id, facility_id')
          .or('id.eq.$facilityId,facility_id.eq.$facilityId')
          .maybeSingle();

      if (facilityRow != null) {
        final row = facilityRow as Map<String, dynamic>;
        final id = row['id'] as String?;
        final legacyId = row['facility_id'] as String?;
        if (id != null && id.isNotEmpty) candidateIds.add(id);
        if (legacyId != null && legacyId.isNotEmpty) candidateIds.add(legacyId);
      }
    } catch (_) {
      // Ignore fallback resolution errors (e.g. facilities.facility_id absent).
    }

    if (candidateIds.length == 1) return primaryRows;

    final fallbackResponse = await supabase
        .from('facility_ratings')
        .select('*')
        .inFilter('facility_id', candidateIds.toList())
        .order('created_at', ascending: false);

    return (fallbackResponse as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<bool> submitReview({required int rating, required String comment}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('facility_ratings').upsert({
        'user_id': userId,
        'facility_id': facilityId,
        'rating': rating,
        'comment': comment.trim(),
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
