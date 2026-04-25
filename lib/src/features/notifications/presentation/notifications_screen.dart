import 'package:flutter/material.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        SectionHeader(title: 'Notifications'),
        SizedBox(height: 12),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.notifications_active_outlined),
            title: Text('Summons Sent'),
            subtitle: Text('Case KP-2026-0001 has new summons activity.'),
          ),
        ),
        SizedBox(height: 10),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event_note_outlined),
            title: Text('Hearing Reminder'),
            subtitle: Text('Upcoming hearing tomorrow at 9:00 AM.'),
          ),
        ),
      ],
    );

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: body,
    );
  }
}
