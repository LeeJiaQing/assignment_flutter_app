// lib/core/repositories/auth_repository.dart
import '../supabase/supabase_config.dart';

enum UserRole { admin, user }

class AuthRepository {
  /// Returns the role of the currently signed-in user by reading
  /// the profiles table.  Falls back to [UserRole.user] if no row exists.
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

  /// Sign in with email + password.
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Register a new user.
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
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  bool get isSignedIn => supabase.auth.currentUser != null;
}