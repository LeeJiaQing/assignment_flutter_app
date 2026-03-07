import 'package:flutter/material.dart';

import '../../../core/repositories/auth_repository.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../admin/qr_scanner_screen.dart';
import '../../booking/booking_screen.dart';
import '../../home/home_screen.dart';
import '../../party/party_screen.dart';
import '../../profile/profile_screen.dart';

class NavigationViewModel extends ChangeNotifier {
  NavigationViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  final AuthRepository _authRepository;

  int _currentIndex = 0;
  UserRole? _role;

  int get currentIndex => _currentIndex;
  bool get isLoading => _role == null;
  bool get isAdmin => _role == UserRole.admin;

  Future<void> initialize() async {
    _role = await _authRepository.getCurrentUserRole();
    notifyListeners();
  }

  List<Widget> get pages => isAdmin
      ? const [
          HomePage(),
          BookingScreen(),
          PartyScreen(),
          UserScreen(),
          AdminDashboardScreen(),
          QrScannerScreen(),
        ]
      : const [
          HomePage(),
          BookingScreen(),
          PartyScreen(),
          UserScreen(),
        ];

  List<BottomNavigationBarItem> get items => isAdmin
      ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Party',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QR Scanner',
          ),
        ]
      : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Party',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void ensureValidIndex() {
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }
  }
}
