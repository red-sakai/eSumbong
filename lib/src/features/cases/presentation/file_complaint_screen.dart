import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/case_providers.dart';
import '../domain/case_event.dart';
import '../domain/case_status.dart';
import '../domain/complaint_case.dart';

class FileComplaintScreen extends ConsumerStatefulWidget {
  const FileComplaintScreen({super.key});

  @override
  ConsumerState<FileComplaintScreen> createState() =>
      _FileComplaintScreenState();
}

class _FileComplaintScreenState extends ConsumerState<FileComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complainantController = TextEditingController();
  final _respondentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _evidenceController = TextEditingController();
  DateTime _incidentDate = DateTime.now();

  @override
  void dispose() {
    _complainantController.dispose();
    _respondentController.dispose();
    _descriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final caseId = 'KP-${DateTime.now().millisecondsSinceEpoch}';
    final evidence = _evidenceController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final currentUser = ref.read(authControllerProvider);

    final complaintCase = ComplaintCase(
      id: caseId,
      createdByUserId: currentUser?.id ?? 'anonymous-user',
      complainantName: _complainantController.text.trim(),
      respondentName: _respondentController.text.trim(),
      description: _descriptionController.text.trim(),
      incidentDate: _incidentDate,
      status: CaseStatus.pending,
      evidenceUrls: evidence,
      events: <CaseEvent>[
        CaseEvent(
          title: 'Case Filed',
          description: 'Complaint submitted through mobile app.',
          timestamp: DateTime.now(),
        ),
      ],
    );

    await ref.read(caseRepositoryProvider).createCase(complaintCase);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Complaint submitted with Case ID $caseId')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Complaint')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _complainantController,
              decoration: const InputDecoration(labelText: 'Complainant Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _respondentController,
              decoration: const InputDecoration(labelText: 'Respondent Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Incident Description',
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Incident Date'),
              subtitle: Text(_incidentDate.toIso8601String().split('T').first),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: _incidentDate,
                  );
                  if (picked != null) {
                    setState(() => _incidentDate = picked);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _evidenceController,
              decoration: const InputDecoration(
                labelText: 'Evidence Links (comma separated)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit Complaint'),
            ),
          ],
        ),
      ),
    );
  }
}
