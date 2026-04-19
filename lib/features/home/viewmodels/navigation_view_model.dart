// lib/features/home/viewmodels/navigation_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/repositories/auth_repository.dart';

class NavigationViewModel extends ChangeNotifier {
  NavigationViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  int _currentIndex = 0;
  UserRole? _role;
  String? _requestedFacilityCategory;
  int _facilityFilterRequestToken = 0;

  int get currentIndex => _currentIndex;
  bool get isLoading => _role == null;
  bool get isAdmin => _role == UserRole.admin;
  String? get requestedFacilityCategory => _requestedFacilityCategory;
  int get facilityFilterRequestToken => _facilityFilterRequestToken;

  Future<void> initialize() async {
    _role = await _authRepository.getCurrentUserRole();
    notifyListeners();
  }

  int get pageCount => isAdmin ? 6 : 5;

  List<BottomNavigationBarItem> get items => isAdmin
      ? const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.stadium_outlined), label: 'Facility'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Party'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'QR Scanner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ]
      : const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.stadium_outlined), label: 'Facility'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Party'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ];

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void ensureValidIndex() {
    if (_currentIndex >= pageCount) {
      _currentIndex = 0;
    }
  }

  void openFacilityWithCategory(String category) {
    _requestedFacilityCategory = category;
    _facilityFilterRequestToken++;
    _currentIndex = 1; // Facility tab for both admin and normal users
    notifyListeners();
  }

  void clearRequestedFacilityCategory() {
    _requestedFacilityCategory = null;
  }
}
