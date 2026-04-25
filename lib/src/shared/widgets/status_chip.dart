import 'package:flutter/material.dart';

import '../../features/cases/domain/case_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      CaseStatus.pending => Colors.orange,
      CaseStatus.summonsSent => Colors.indigo,
      CaseStatus.hearingScheduled => Colors.blue,
      CaseStatus.failedMediation => Colors.red,
      CaseStatus.completed => Colors.green,
    };

    return Chip(
      label: Text(status.label),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
