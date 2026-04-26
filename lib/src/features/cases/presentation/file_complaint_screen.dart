import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/case_providers.dart';
import '../domain/case_event.dart';
import '../domain/case_status.dart';
import '../domain/complaint_case.dart';
import 'package:esumbong/src/shared/utils/input_sanitizer.dart';

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
  final _respondentPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _evidenceController = TextEditingController();

  DateTime _incidentDate = DateTime.now();
  bool _isUploading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _complainantController.dispose();
    _respondentController.dispose();
    _respondentPhoneController.dispose();
    _descriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  /// Pre-fills the complainant name once from the signed-in user's profile.
  void _initComplainantName() {
    if (_initialized) return;
    final user = ref.read(currentUserProvider);
    if (user != null && user.fullName.isNotEmpty) {
      _complainantController.text = InputSanitizer.titleCase(user.fullName);
    }
    _initialized = true;
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

      final evidenceUrls = _evidenceController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);

      // Create case in Firestore — bind to both userId and phone number.
      final complaintCase = ComplaintCase(
        id: caseId,
        createdByUserId: uid,
        createdByPhone: userPhone,
        complainantName: InputSanitizer.titleCase(_complainantController.text),
        respondentName: InputSanitizer.titleCase(_respondentController.text),
        respondentPhone: InputSanitizer.normalizePhone(_respondentPhoneController.text),
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
            '${evidenceUrls.isNotEmpty ? ' (${evidenceUrls.length} evidence link(s))' : ''}',
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
              textCapitalization: TextCapitalization.words,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÿ\s'\-.]")),
              ],
              decoration: const InputDecoration(
                labelText: "Respondent's Full Name",
                helperText: 'Person being complained against',
              ),
              validator: (v) {
                final sanitized = InputSanitizer.cleanNamePart(v ?? '');
                if (sanitized.isEmpty) return 'Required field';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _respondentPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Respondent's Mobile Number",
                helperText: 'E.164 preferred, e.g. +639171234567',
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Required field';
                if (!RegExp(r'^\+63\d{10}$').hasMatch(value)) {
                  return 'Use a valid PH number like +639171234567';
                }
                return null;
              },
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

            // ── Evidence URLs ─────────────────────────────────────────────
            TextFormField(
              controller: _evidenceController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Evidence Links',
                helperText:
                    'Paste comma-separated URLs to photos, videos, or documents',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Web demo mode keeps evidence as links so the flow stays fast and cross-platform.',
              style: Theme.of(context).textTheme.bodySmall,
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
