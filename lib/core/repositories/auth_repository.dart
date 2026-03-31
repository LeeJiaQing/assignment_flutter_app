// lib/core/repositories/auth_repository.dart
import '../supabase/supabase_config.dart';

enum UserRole { admin, user }

class AuthRepository {
  /// Returns the role of the currently signed-in user by reading
  /// the profiles table. Falls back to [UserRole.user] if no row exists.
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
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final user = response.user;
    if (user != null) {
      try {
        await supabase.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'full_name': fullName,
          'role': 'user',
        });
      } catch (_) {
        // Some projects enforce strict RLS during sign-up (especially when
        // email confirmation is enabled and session is not yet active).
        // Profile bootstrap can be retried later after a verified sign-in.
      }
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  bool get isSignedIn => supabase.auth.currentUser != null;
}