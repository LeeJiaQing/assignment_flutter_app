// lib/core/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';

enum UserRole { admin, user }

class AuthRepository {
  Future<UserRole> getCurrentUserRole() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return UserRole.user;

    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return UserRole.user;
    return (response['role'] as String) == 'admin'
        ? UserRole.admin
        : UserRole.user;
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    // Profile upsert is deferred to ensureProfile() which is called
    // only once we've confirmed a session exists.
  }

  /// Upserts the profile row. Safe to call multiple times.
  Future<void> ensureProfile({
    required String email,
    required String fullName,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'full_name': fullName,
        'role': 'user',
      });
    } catch (_) {
      // RLS may block this during email-confirmation flows; ignore.
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<bool> doesEmailExist(String email) async {
    final response = await supabase
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    return response != null;
  }

  Future<void> sendPasswordResetCode(String email) async {
    await supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  Future<bool> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final response = await supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    return response.user != null || response.session != null;
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  bool get isSignedIn => supabase.auth.currentUser != null;
}
