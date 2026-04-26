import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../cases/data/case_providers.dart';
import '../../cases/data/functions_service.dart';
import '../../cases/domain/complaint_case.dart';
import '../../cases/domain/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(visibleCasesStreamProvider);

    final body = updatesAsync.when(
      data: (cases) {
        final updates = _buildUpdates(ref, cases);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SectionHeader(title: 'Case Updates'),
            const SizedBox(height: 12),
            if (updates.isEmpty)
              const AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_none_rounded),
                  title: Text('No updates yet'),
                  subtitle: Text(
                    'Updates from your cases will appear here in real time.',
                  ),
                ),
              )
            else
              ...updates.map(
                (update) => AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => context.push('/case/${update.caseId}'),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: update.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(update.icon, size: 20, color: update.color),
                        ),
                        title: Text(update.title),
                        subtitle: Text(
                          '${update.description}\nCase ${update.caseId}',
                        ),
                        trailing: update.isAction
                            ? null
                            : Text(
                                _formatTime(update.timestamp),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                      ),
                      if (update.isAction) ...[
                        const Divider(indent: 52),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(52, 0, 8, 8),
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(caseRepositoryProvider)
                                      .declineCfa(update.caseId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('CFA Declined.')),
                                    );
                                  }
                                },
                                child: const Text('Reject',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await ref
                                      .read(caseRepositoryProvider)
                                      .generateCfa(update.caseId);
                                  await ref
                                      .read(functionsServiceProvider)
                                      .generatePdfAndQr(update.caseId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('CFA Generated.')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: body,
    );
  }

  List<_CaseUpdateItem> _buildUpdates(WidgetRef ref, List<ComplaintCase> cases) {
    final items = <_CaseUpdateItem>[];
    final isStaff =
        ref.watch(currentUserProvider)?.role == UserRole.barangayStaff;

    for (final complaintCase in cases) {
      // ── Injection: Action Required (Staff only) ─────────────────────────
      if (isStaff && complaintCase.isCfaApprovalPending) {
        items.add(
          _CaseUpdateItem(
            caseId: complaintCase.id,
            title: 'Action Required: Generate CFA?',
            description: 'Case has reached 30 days without resolution.',
            timestamp: DateTime.now(),
            icon: Icons.gavel_rounded,
            color: Colors.redAccent,
            isAction: true,
          ),
        );
      }

      for (final event in complaintCase.events) {
        final tone = _toneFor(event.title);
        items.add(
          _CaseUpdateItem(
            caseId: complaintCase.id,
            title: event.title,
            description: event.description,
            timestamp: event.timestamp,
            icon: tone.icon,
            color: tone.color,
          ),
        );
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  _UpdateTone _toneFor(String title) {
    final normalized = title.toLowerCase();

    if (normalized.contains('file')) {
      return const _UpdateTone(Icons.upload_file_rounded, Color(0xFF0369A1));
    }
    if (normalized.contains('summons')) {
      return const _UpdateTone(Icons.campaign_rounded, Color(0xFF4F46E5));
    }
    if (normalized.contains('hearing')) {
      return const _UpdateTone(
        Icons.event_available_rounded,
        Color(0xFF0F766E),
      );
    }
    if (normalized.contains('no show')) {
      return const _UpdateTone(Icons.person_off_rounded, Color(0xFFB45309));
    }
    if (normalized.contains('certificate') || normalized.contains('cfa')) {
      return const _UpdateTone(Icons.verified_rounded, Color(0xFF15803D));
    }

    return const _UpdateTone(
      Icons.notifications_active_outlined,
      Color(0xFF64748B),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final delta = now.difference(timestamp);

    if (delta.inMinutes < 1) {
      return 'Now';
    }
    if (delta.inHours < 1) {
      return '${delta.inMinutes}m';
    }
    if (delta.inDays < 1) {
      return '${delta.inHours}h';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays}d';
    }

    return DateFormat.yMMMd().format(timestamp);
  }
}

class _CaseUpdateItem {
  const _CaseUpdateItem({
    required this.caseId,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.isAction = false,
  });

  final String caseId;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final bool isAction;
}

class _UpdateTone {
  const _UpdateTone(this.icon, this.color);

  final IconData icon;
  final Color color;
}
