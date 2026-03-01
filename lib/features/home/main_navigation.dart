import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../booking/booking_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../notification/notification_screen.dart';
import '../party/party_screen.dart';
import '../profile/profile_screen.dart';

bool isAdmin = true;

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> pages = isAdmin
      ? const [
    HomePage(),
    BookingScreen(),
    NotificationScreen(),
    PartyScreen(),
    UserScreen(),
    AdminDashboardScreen(),
  ]
      : const [
    HomePage(),
    BookingScreen(),
    NotificationScreen(),
    PartyScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CourtNow"),
      ),
      body: IndexedStack(
        index: currentIndex, // index of the children
        children: pages, // list of pages
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF6DCC98),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Booking",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notification",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: "Party",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
        ],
      ),
    );
  }
}