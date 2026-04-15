import 'package:flutter/material.dart';

import '../../../core/repositories/auth_repository.dart';

class FacilityPageViewModel extends ChangeNotifier {
  FacilityPageViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isAdmin = false;
  bool _isLoadingRole = true;

  bool get isAdmin => _isAdmin;
  bool get isLoadingRole => _isLoadingRole;

  Future<void> loadRole() async {
    _isLoadingRole = true;
    notifyListeners();

    final role = await _authRepository.getCurrentUserRole();
    _isAdmin = role == UserRole.admin;
    _isLoadingRole = false;
    notifyListeners();
  }
}
