// lib/features/feedback/viewmodels/feedback_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';

enum FeedbackStatus { idle, submitting, success, error }

class FeedbackViewModel extends ChangeNotifier {
  FeedbackStatus _status = FeedbackStatus.idle;
  String? _errorMessage;

  FeedbackStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _status == FeedbackStatus.submitting;

  Future<void> submitFeedback({
    required String subject,
    required String message,
    required int rating,
  }) async {
    _status = FeedbackStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final user =
          supabase.auth.currentSession?.user ?? supabase.auth.currentUser;
      var userId = user?.id;

      if (userId == null) {
        final fetchedUser = await supabase.auth.getUser();
        userId = fetchedUser.user?.id;
      }

      if (userId == null) {
        throw Exception('You must be signed in before sending feedback.');
      }

      await supabase.from('feedback').insert({
        'user_id': userId,
        'subject': subject.trim(),
        'message': message.trim(),
        'rating': rating,
      });

      _status = FeedbackStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = FeedbackStatus.error;
    }

    notifyListeners();
  }

  void reset() {
    _status = FeedbackStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
