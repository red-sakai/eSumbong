import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/case_providers.dart';
import '../data/functions_service.dart';
import '../domain/user_role.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/case_timeline.dart';
import '../../../shared/widgets/status_chip.dart';

class CaseDetailsScreen extends ConsumerWidget {
  const CaseDetailsScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseByIdProvider(caseId));
    final isStaff =
        ref.watch(currentUserProvider)?.role == UserRole.barangayStaff;

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: caseAsync.when(
        data: (caseData) {
          if (caseData == null) {
            return const Center(child: Text('Case not found.'));
          }

          // ── Automation trigger (3 No-Shows only) ───────────────────────────
          if (isStaff && caseData.shouldAutoGenerateCfa) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auto-generating CFA (3 No-Shows)...'),
                  duration: Duration(seconds: 2),
                ),
              );
              
              await ref
                  .read(caseRepositoryProvider)
                  .generateCfa(caseData.id);
              
              await ref
                  .read(functionsServiceProvider)
                  .generatePdfAndQr(caseData.id);
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // ── Case info card ─────────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Case title — formal docket style
                    Text(
                      'Case No. ${caseData.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusChip(status: caseData.status),
                    const Divider(height: 24),
                    // Party rows
                    _PartyRow(
                      icon: Icons.person_outline,
                      role: 'Complainant',
                      name: caseData.complainantName,
                    ),
                    const SizedBox(height: 6),
                    _PartyRow(
                      icon: Icons.person_outline,
                      role: 'Respondent',
                      name: caseData.respondentName,
                      secondary: caseData.respondentPhone.isNotEmpty
                          ? caseData.respondentPhone
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(caseData.description),
                    const SizedBox(height: 8),
                    Text(
                      'Incident Date: ${DateFormat.yMMMd().format(caseData.incidentDate)}',
                    ),
                    // Staff-only fields
                    if (isStaff) ...<Widget>[
                      const SizedBox(height: 4),
                      Text('No-Show Count: ${caseData.noShowCount}'),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      caseData.cfaGenerated
                          ? 'CFA: Generated'
                          : 'CFA: Not generated',
                    ),
                    if (caseData.cfaRecord != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Certificate No.: ${caseData.cfaRecord!.certificateNumber}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Issued: ${DateFormat.yMMMMd().add_jm().format(caseData.cfaRecord!.issuedAt)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Action buttons ─────────────────────────────────────────────
              if (isStaff)
                // Staff can schedule, log no-show, generate CFA, and QR verify
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: () =>
                          context.push('/hearing/${caseData.id}'),
                      label: const Text('Schedule Hearing'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_off_outlined),
                      onPressed: () async {
                        await ref
                            .read(caseRepositoryProvider)
                            .logNoShow(caseData.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No-show logged.')),
                          );
                        }
                      },
                      label: const Text('Log No-Show'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.description_outlined),
                      onPressed: () async {
                        await ref
                            .read(caseRepositoryProvider)
                            .generateCfa(caseData.id);
                        // Trigger Cloud Function for PDF + QR generation
                        await ref
                            .read(functionsServiceProvider)
                            .generatePdfAndQr(caseData.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'CFA generated. PDF/QR generation triggered.',
                              ),
                            ),
                          );
                        }
                      },
                      label: const Text('Generate CFA'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      onPressed: () {
                        final payload = caseData.cfaRecord?.qrPayload;
                        if (payload == null) {
                          context.push('/qr-verify');
                          return;
                        }
                        context.push(
                          '/qr-verify?payload=${Uri.encodeComponent(payload)}',
                        );
                      },
                      label: const Text('QR Verify'),
                    ),
                    if (caseData.cfaRecord != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded),
                        onPressed: () =>
                            context.push('/cfa/${caseData.id}'),
                        label: const Text('View CFA'),
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Dismiss Case?'),
                            content: const Text(
                                'Are you sure you want to dismiss this complaint? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Dismiss',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await ref
                              .read(caseRepositoryProvider)
                              .dismissCase(caseData.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Case has been dismissed.')),
                            );
                          }
                        }
                      },
                      label: const Text('Dismiss Case'),
                    ),
                  ],
                )
              // Citizens can only view the CFA if one has been generated
              else if (caseData.cfaRecord != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () => context.push('/cfa/${caseData.id}'),
                  label: const Text('View CFA'),
                ),

              const SizedBox(height: 12),
              // ── Timeline ───────────────────────────────────────────────────
              AppCard(child: CaseTimeline(events: caseData.events)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// ── Party row widget ──────────────────────────────────────────────────────────

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.icon,
    required this.role,
    required this.name,
    this.secondary,
  });

  final IconData icon;
  final String role;
  final String name;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              role.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.0,
                fontSize: 10,
              ),
            ),
            Text(
              name,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            if (secondary != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                secondary!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
