// lib/features/notification/widgets/notification_tile.dart
import 'package:flutter/material.dart';

import '../../../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: item.isRead
              ? Colors.grey.shade200
              : const Color(0xFFD6F0E0),
          child: Icon(
            item.isRead
                ? Icons.notifications_outlined
                : Icons.notifications_active_outlined,
            color: item.isRead ? Colors.grey : const Color(0xFF1C894E),
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight:
            item.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.body,
                style:
                const TextStyle(fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(
              _formatDate(item.createdAt),
              style:
              const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}