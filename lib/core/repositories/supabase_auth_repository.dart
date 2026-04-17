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

  @override
  // TODO: implement isSignedIn
  bool get isSignedIn => throw UnimplementedError();

  @override
  Future<void> signIn(String email, String password) {
    // TODO: implement signIn
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }

  @override
  Future<void> signUp({required String email, required String password, required String fullName}) {
    // TODO: implement signUp
    throw UnimplementedError();
  }

  @override
  Future<void> ensureProfile({required String email, required String fullName}) {
    // TODO: implement ensureProfile
    throw UnimplementedError();
  }

  @override
  Future<bool> doesEmailExist(String email) {
    // TODO: implement doesEmailExist
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetCode(String email) {
    // TODO: implement sendPasswordResetCode
    throw UnimplementedError();
  }

  @override
  Future<void> updatePassword(String newPassword) {
    // TODO: implement updatePassword
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyPasswordResetCode({required String email, required String code}) {
    // TODO: implement verifyPasswordResetCode
    throw UnimplementedError();
  }
}
