// lib/features/auth/viewmodels/auth_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
      : _repo = authRepository;

  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.signIn(email, password);
      _status = AuthStatus.success;
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      // After signUp, Supabase may have already created a session.
      // Check if we're signed in — if yes, go straight to success.
      // If not (email confirmation required), show a friendly message.
      final isSignedIn = _repo.isSignedIn;

      if (isSignedIn) {
        // Ensure the profile row exists with the correct name
        await _repo.ensureProfile(email: email, fullName: fullName);
        _status = AuthStatus.success;
      } else {
        // Email confirmation is enabled — user must confirm before logging in
        _errorMessage =
        'Account created! Please check your email to confirm your account, then log in.';
        _status = AuthStatus.error; // Use error state to show the message
      }
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<bool> doesEmailExist(String email) => _repo.doesEmailExist(email);

  Future<void> sendPasswordResetCode(String email) =>
      _repo.sendPasswordResetCode(email);

  Future<bool> verifyPasswordResetCode({
    required String email,
    required String code,
  }) =>
      _repo.verifyPasswordResetCode(email: email, code: code);

  Future<void> updatePassword(String newPassword) =>
      _repo.updatePassword(newPassword);

  String _parseError(String raw) {
    debugPrint('Auth error raw: $raw');
    if (raw.contains('Invalid login credentials') ||
        raw.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('User already registered') ||
        raw.contains('already registered')) {
      return 'This email is already registered. Please login instead.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account before logging in.';
    }
    if (raw.contains('network') ||
        raw.contains('SocketException') ||
        raw.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (raw.contains('Password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (raw.contains('Unable to validate email address')) {
      return 'Invalid email format.';
    }
    if (raw.contains('email rate limit exceeded')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void reset() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
