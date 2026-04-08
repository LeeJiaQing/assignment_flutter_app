// lib/models/notification_model.dart

enum NotificationType {
  announcement,
  bookingReminder,
  partyJoined,
  unknown;

  static NotificationType fromString(String s) {
    switch (s) {
      case 'announcement':
        return NotificationType.announcement;
      case 'booking_reminder':
        return NotificationType.bookingReminder;
      case 'party_joined':
        return NotificationType.partyJoined;
      default:
        return NotificationType.unknown;
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final Map<String, dynamic> data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.unknown,
    this.data = const {},
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: (json['is_read'] as bool?) ?? false,
        type: NotificationType.fromString(
            (json['type'] as String?) ?? ''),
        data: (json['data'] as Map<String, dynamic>?) ?? {},
      );

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    type: type,
    data: data,
  );
}