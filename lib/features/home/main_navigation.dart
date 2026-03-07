import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notification/notification_screen.dart';
import 'viewmodels/navigation_view_model.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NavigationViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    viewModel.ensureValidIndex();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CourtNow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Announcements',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: viewModel.currentIndex,
        children: viewModel.pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: viewModel.currentIndex,
        selectedItemColor: const Color(0xFF6DCC98),
        unselectedItemColor: Colors.grey,
        onTap: viewModel.setTab,
        items: viewModel.items,
      ),
    );
  }
}
