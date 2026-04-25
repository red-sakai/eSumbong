import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/case_providers.dart';
import '../data/storage_service.dart';
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
  // complainantController is pre-filled from the user profile and read-only.
  final _complainantController = TextEditingController();
  final _respondentController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _incidentDate = DateTime.now();
  final List<PlatformFile> _pickedFiles = <PlatformFile>[];
  bool _isUploading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _complainantController.dispose();
    _respondentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Pre-fills the complainant name once from the signed-in user's profile.
  void _initComplainantName() {
    if (_initialized) return;
    final user = ref.read(currentUserProvider);
    if (user != null && user.fullName.isNotEmpty) {
      _complainantController.text = user.fullName;
    }
    _initialized = true;
  }

  // ── File picker ─────────────────────────────────────────────────────────

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        final alreadyAdded =
            _pickedFiles.any((p) => p.name == f.name);
        if (!alreadyAdded) _pickedFiles.add(f);
      }
    });
  }

  void _removeFile(PlatformFile file) {
    setState(() => _pickedFiles.remove(file));
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final uid = currentUser?.id ?? 'anonymous-user';
      // The phone/email is the stable cross-session identifier.
      final userPhone = currentUser?.phoneOrEmail.trim() ?? '';
      final caseId = 'KP-${DateTime.now().millisecondsSinceEpoch}';

      // Upload evidence files to Firebase Storage
      final evidenceUrls = <String>[];
      for (final pf in _pickedFiles) {
        if (pf.path == null) continue;
        try {
          final url = await ref.read(storageServiceProvider).uploadEvidence(
                caseId: caseId,
                userId: uid,
                file: File(pf.path!),
              );
          evidenceUrls.add(url);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed for ${pf.name}: $e')),
            );
          }
        }
      }

      // Create case in Firestore — bind to both userId and phone number.
      final complaintCase = ComplaintCase(
        id: caseId,
        createdByUserId: uid,
        createdByPhone: userPhone,
        complainantName: _complainantController.text.trim(),
        respondentName: _respondentController.text.trim(),
        description: _descriptionController.text.trim(),
        incidentDate: _incidentDate,
        status: CaseStatus.pending,
        evidenceUrls: evidenceUrls,
        events: <CaseEvent>[
          CaseEvent(
            title: 'Case Filed',
            description: 'Complaint submitted through eSumbong app.',
            timestamp: DateTime.now(),
          ),
        ],
      );

      await ref.read(caseRepositoryProvider).createCase(complaintCase);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complaint submitted — Case No. $caseId'
            '${evidenceUrls.isNotEmpty ? ' (${evidenceUrls.length} file(s) uploaded)' : ''}',
          ),
        ),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Pre-fill once when the widget is first built.
    _initComplainantName();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('File a Complaint')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // ── Info banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your name is automatically filled from your account. '
                      'This complaint will be linked to your profile.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0D6B64),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Complainant (read-only, from profile) ──────────────────────
            TextFormField(
              controller: _complainantController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Complainant's Full Name",
                helperText: 'Automatically filled from your account',
                suffixIcon: Icon(Icons.lock_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4)),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),

            // ── Respondent ─────────────────────────────────────────────────
            TextFormField(
              controller: _respondentController,
              decoration: const InputDecoration(
                labelText: "Respondent's Full Name",
                helperText: 'Person being complained against',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),

            // ── Description ────────────────────────────────────────────────
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration:
                  const InputDecoration(labelText: 'Incident Description'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),

            // ── Incident date ──────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Incident Date'),
              subtitle:
                  Text(_incidentDate.toIso8601String().split('T').first),
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
            const SizedBox(height: 4),

            // ── Evidence upload ────────────────────────────────────────────
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Evidence Files',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isUploading ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('Attach'),
                ),
              ],
            ),
            if (_pickedFiles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No files selected (jpg, png, pdf — max 10 MB each).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _pickedFiles.map((f) {
                  return Chip(
                    label: Text(
                      f.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: _isUploading ? null : () => _removeFile(f),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),
            _isUploading
                ? const Center(
                    child: Column(
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Uploading evidence…'),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Submit Complaint'),
                  ),
          ],
        ),
      ),
    );
  }
}
