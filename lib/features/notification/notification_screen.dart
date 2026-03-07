import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications_active_outlined),
            title: Text('Announcement 1'),
            subtitle: Text('This is where your latest announcement appears.'),
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.campaign_outlined),
            title: Text('Announcement 2'),
            subtitle: Text('Add real announcement records from Supabase later.'),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Announcements')) : null,
      backgroundColor: const Color(0xFFF7F7F7),
      body: content,
    );
  }
}
