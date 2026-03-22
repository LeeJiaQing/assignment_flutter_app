// lib/features/home/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin/admin_dashboard_screen.dart';
import '../admin/qr_scanner_screen.dart';
import '../chat/realtime_chat_screen.dart';
import '../facility/facility_screen.dart';
import '../home/home_screen.dart';
import '../party/party_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/notification_screen.dart';
import 'viewmodels/navigation_view_model.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    vm.ensureValidIndex();

    final pages = vm.isAdmin
        ? const [
      AdminDashboardScreen(),
      FacilityScreen(),
      PartyScreen(),
      RealtimeChatScreen(),
      QrScannerScreen(),
      ProfileScreen(),
    ]
        : const [
      HomePage(),
      FacilityScreen(),
      PartyScreen(),
      RealtimeChatScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CourtNow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Announcements',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: vm.currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: vm.currentIndex,
        selectedItemColor: const Color(0xFF6DCC98),
        unselectedItemColor: Colors.grey,
        onTap: vm.setTab,
        items: vm.items,
      ),
    );
  }
}