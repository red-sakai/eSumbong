import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/case_providers.dart';
import '../data/functions_service.dart';

class HearingScheduleScreen extends ConsumerStatefulWidget {
  const HearingScheduleScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<HearingScheduleScreen> createState() => _HearingScheduleScreenState();
}

class _HearingScheduleScreenState extends ConsumerState<HearingScheduleScreen> {
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 2));

  Future<void> _save() async {
    final caseData = await ref.read(caseRepositoryProvider).getCaseById(widget.caseId);
    final respondentPhone = caseData?.respondentPhone.isNotEmpty == true
        ? caseData!.respondentPhone
        : '+639171234567';

    await ref.read(caseRepositoryProvider).scheduleHearing(
          caseId: widget.caseId,
          hearingDate: _selectedDateTime,
        );

    // Trigger a realistic UniSMS summons message in the demo activity log.
    await ref.read(functionsServiceProvider).sendSummons(
      caseId: widget.caseId,
      respondentPhone: respondentPhone,
      hearingDate: _selectedDateTime,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Hearing scheduled for ${DateFormat.yMMMd().add_jm().format(_selectedDateTime)}',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hearing Scheduler')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Case: ${widget.caseId}'),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Selected Hearing Date and Time'),
              subtitle: Text(
                DateFormat.yMMMMd().add_jm().format(_selectedDateTime),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !context.mounted) {
                    return;
                  }
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                  );
                  if (time == null || !context.mounted) {
                    return;
                  }
                  setState(() {
                    _selectedDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Hearing Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
