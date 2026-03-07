import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    this.fallbackRole = UserRole.user,
  });

  final UserRole fallbackRole;

  @override
  Future<UserRole> getCurrentUserRole() async {
    // TODO: replace fallback with real Supabase role lookup.
    // Suggested flow:
    // 1) read current user from Supabase auth
    // 2) fetch role from user metadata or profiles table
    // 3) map role string to UserRole enum
    return fallbackRole;
  }
}
