// lib/core/services/auth_service.dart
import '../repositories/auth_repository.dart';
import '../supabase/supabase_config.dart';

export '../repositories/auth_repository.dart' show UserRole;

/// Thin service layer — wraps [AuthRepository] and exposes a stream of
/// auth-state changes for the rest of the app.
class AuthService {
  AuthService({required AuthRepository authRepository})
      : _repo = authRepository;

  final AuthRepository _repo;

  bool get isSignedIn => _repo.isSignedIn;

  String? get currentUserId => supabase.auth.currentUser?.id;

  Future<UserRole> getCurrentUserRole() => _repo.getCurrentUserRole();

  Future<void> signIn(String email, String password) =>
      _repo.signIn(email, password);

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _repo.signUp(email: email, password: password, fullName: fullName);

  Future<void> signOut() => _repo.signOut();

  /// Stream of auth state changes (sign-in, sign-out, token refresh, etc.)
  Stream<bool> get authStateChanges => supabase.auth.onAuthStateChange
      .map((event) => event.session != null);
}