// lib/features/notification/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/notification_view_model.dart';
import 'widgets/notification_tile.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationViewModel()..loadNotifications(),
      child: _NotificationView(showAppBar: showAppBar),
    );
  }
}

class _NotificationView extends StatelessWidget {
  const _NotificationView({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();

    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: const Text('Announcements'))
          : null,
      backgroundColor: const Color(0xFFF7F7F7),
      body: switch (vm.status) {
        NotificationStatus.initial ||
        NotificationStatus.loading =>
        const Center(child: CircularProgressIndicator()),
        NotificationStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                vm.errorMessage ?? 'Failed to load announcements',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: () => context
                    .read<NotificationViewModel>()
                    .loadNotifications(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        NotificationStatus.loaded => vm.notifications.isEmpty
            ? const Center(
          child: Text('No announcements yet.',
              style: TextStyle(color: Colors.grey)),
        )
            : RefreshIndicator(
          onRefresh: () => context
              .read<NotificationViewModel>()
              .loadNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.notifications.length,
            itemBuilder: (_, i) =>
                NotificationTile(item: vm.notifications[i]),
          ),
        ),
      },
    );
  }
}