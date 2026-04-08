// lib/features/notification/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import 'viewmodels/notification_view_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      NotificationViewModel()..loadNotifications(),
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
          ? AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (vm.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C894E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${vm.unreadCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (vm.unreadCount > 0)
            TextButton(
              onPressed: () => context
                  .read<NotificationViewModel>()
                  .markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                    color: Color(0xFF1C894E), fontSize: 13),
              ),
            ),
        ],
      )
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
              const Icon(Icons.wifi_off,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                vm.errorMessage ?? 'Failed to load notifications',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('No notifications yet.',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: () => context
              .read<NotificationViewModel>()
              .loadNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.notifications.length,
            itemBuilder: (_, i) => _NotificationTile(
              item: vm.notifications[i],
              onTap: () => context
                  .read<NotificationViewModel>()
                  .markRead(vm.notifications[i].id),
            ),
          ),
        ),
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(
      {required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  IconData get _icon {
    switch (item.type) {
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.bookingReminder:
        return Icons.access_time_outlined;
      case NotificationType.partyJoined:
        return Icons.group_add_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (item.type) {
      case NotificationType.announcement:
        return const Color(0xFF1C894E);
      case NotificationType.bookingReminder:
        return Colors.orange.shade700;
      case NotificationType.partyJoined:
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  Color get _iconBg {
    switch (item.type) {
      case NotificationType.announcement:
        return const Color(0xFFD6F0E0);
      case NotificationType.bookingReminder:
        return Colors.orange.shade50;
      case NotificationType.partyJoined:
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF0FAF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? Colors.transparent
                : const Color(0xFF1C894E).withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF1C3A2A),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1C894E),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(item.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}