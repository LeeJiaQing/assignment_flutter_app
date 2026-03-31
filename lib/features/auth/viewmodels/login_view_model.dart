import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../models/auth_credentials.dart';

enum LoginStatus { initial, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  LoginStatus _status = LoginStatus.initial;
  String? _errorMessage;

  LoginStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LoginStatus.loading;

  Future<bool> signIn(AuthCredentials credentials) async {
    if (!credentials.isValidEmail) {
      _status = LoginStatus.error;
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    if (!credentials.isValidPassword) {
      _status = LoginStatus.error;
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(credentials.email.trim(), credentials.password);
      _status = LoginStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = LoginStatus.error;
      _errorMessage = _friendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String fullName,
    required AuthCredentials credentials,
  }) async {
    if (fullName.trim().isEmpty) {
      _status = LoginStatus.error;
      _errorMessage = 'Please enter your full name.';
      notifyListeners();
      return false;
    }

    if (!credentials.isValidEmail || !credentials.isValidPassword) {
      _status = LoginStatus.error;
      _errorMessage = 'Please provide valid account details.';
      notifyListeners();
      return false;
    }

    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: credentials.email.trim(),
        password: credentials.password,
        fullName: fullName.trim(),
      );
      _status = LoginStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = LoginStatus.error;
      _errorMessage = _friendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  String _friendlyMessage(Object e) {
    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    return 'Authentication failed. Please try again.';
  }
}
