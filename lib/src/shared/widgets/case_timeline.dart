import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/cases/domain/case_event.dart';

class CaseTimeline extends StatelessWidget {
  const CaseTimeline({super.key, required this.events});

  final List<CaseEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text('No timeline events yet.');
    }

    return Column(
      children: events.map((event) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.radio_button_checked, size: 16),
          title: Text(event.title),
          subtitle: Text(event.description),
          trailing: Text(
            DateFormat.yMMMd().add_jm().format(event.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }).toList(),
    );
  }
}
