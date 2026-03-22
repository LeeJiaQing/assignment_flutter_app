// lib/features/profile/viewmodels/profile_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/repositories/auth_repository.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../models/user_model.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  ProfileStatus _status = ProfileStatus.initial;
  UserProfile? _profile;
  String? _errorMessage;

  ProfileStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _authRepository.isSignedIn;

  Future<void> loadProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _status = ProfileStatus.loaded;
        notifyListeners();
        return;
      }

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _profile = UserProfile.fromJson({
          ...response as Map<String, dynamic>,
          'email': supabase.auth.currentUser?.email ?? '',
        });
      }

      _status = ProfileStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProfileStatus.error;
    }

    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('profiles').update({
        'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', userId);

      await loadProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _profile = null;
    _status = ProfileStatus.initial;
    notifyListeners();
  }
}