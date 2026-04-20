// lib/features/home/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_dependencies.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_party_screen.dart';
import '../admin/qr_scanner_screen.dart';
import '../admin/admin_dm_list_screen.dart';
import '../chat/user_admin_dm_screen.dart';
import '../facility/facility_screen.dart';
import '../home/home_screen.dart';
import '../notification/notification_screen.dart';
import '../notification/viewmodels/notification_view_model.dart';
import '../party/party_screen.dart';
import '../profile/profile_screen.dart';
import 'viewmodels/navigation_view_model.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
          NavigationViewModel(
            authRepository: context.read<AppDependencies>().authRepository,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
          NotificationViewModel()..loadNotifications(),
        ),
      ],
      child: const _MainNavigationView(),
    );
  }
}

class _MainNavigationView extends StatelessWidget {
  const _MainNavigationView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();
    final notifVm = context.watch<NotificationViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    vm.ensureValidIndex();

    final pages = vm.isAdmin
        ? [
      const AdminDashboardScreen(),
      const FacilityScreen(),
      const AdminPartyScreen(),
      const AdminDmListScreen(),   // ← Admin sees DM list instead of general chat
      const QrScannerScreen(),
      const ProfileScreen(),
    ]
        : const [
      HomePage(),
      FacilityScreen(),
      PartyScreen(),
      UserAdminDmScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CourtNow'),
        actions: [
          // ── Notification bell with unread badge ──────────────────────
          if (!vm.isAdmin)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                    // Reload badge count after returning
                    if (context.mounted) {
                      context
                          .read<NotificationViewModel>()
                          .loadNotifications();
                    }
                  },
                ),
                if (notifVm.unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        notifVm.unreadCount > 99
                            ? '99+'
                            : '${notifVm.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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
