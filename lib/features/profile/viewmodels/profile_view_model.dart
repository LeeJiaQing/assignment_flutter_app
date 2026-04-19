// lib/features/profile/viewmodels/profile_view_model.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // ── Upload avatar image to Supabase Storage ────────────────────────────────
  /// Uploads [imageFile] to the 'avatars' bucket and returns the public URL.
  /// Returns null on failure.
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final ext = imageFile.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp.$ext';
      final contentExt = ext == 'jpg' ? 'jpeg' : ext;

      final bytes = await imageFile.readAsBytes();

      await supabase.storage
          .from('avatars')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: false,
          contentType: 'image/$contentExt',
        ),
      );

      // Get the public URL
      final publicUrl =
      supabase.storage.from('avatars').getPublicUrl(filePath);

      // Append a cache-buster so the updated image loads fresh
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      _errorMessage = 'Avatar upload failed: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('profiles').update({
        'full_name': fullName,
        'avatar_url': avatarUrl, // null clears the avatar
      }).eq('id', userId);

      await loadProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProfileStatus.error;
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
