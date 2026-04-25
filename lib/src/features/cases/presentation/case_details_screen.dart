import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/case_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/case_timeline.dart';
import '../../../shared/widgets/status_chip.dart';

class CaseDetailsScreen extends ConsumerWidget {
  const CaseDetailsScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseByIdProvider(caseId));

    return Scaffold(
      appBar: AppBar(title: Text('Case $caseId')),
      body: caseAsync.when(
        data: (caseData) {
          if (caseData == null) {
            return const Center(child: Text('Case not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      caseData.id,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    StatusChip(status: caseData.status),
                    const SizedBox(height: 8),
                    Text('Complainant: ${caseData.complainantName}'),
                    const SizedBox(height: 4),
                    Text('Respondent: ${caseData.respondentName}'),
                    const SizedBox(height: 8),
                    Text(caseData.description),
                    const SizedBox(height: 8),
                    Text(
                      'Incident Date: ${DateFormat.yMMMd().format(caseData.incidentDate)}',
                    ),
                    const SizedBox(height: 4),
                    Text('No-Show Count: ${caseData.noShowCount}'),
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => context.push('/hearing/${caseData.id}'),
                    child: const Text('Schedule Hearing'),
                  ),
                  OutlinedButton(
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
                    child: const Text('Log No-Show'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(caseRepositoryProvider)
                          .generateCfa(caseData.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mock CFA generated with QR metadata.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Generate CFA'),
                  ),
                  if (caseData.cfaRecord != null)
                    OutlinedButton(
                      onPressed: () => context.push('/cfa/${caseData.id}'),
                      child: const Text('View CFA'),
                    ),
                  TextButton(
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
                    child: const Text('QR Verify'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
