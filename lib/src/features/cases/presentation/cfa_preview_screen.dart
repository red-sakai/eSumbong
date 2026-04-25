import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/case_providers.dart';
import '../../../shared/widgets/app_card.dart';

class CfaPreviewScreen extends ConsumerWidget {
  const CfaPreviewScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseByIdProvider(caseId));

    return Scaffold(
      appBar: AppBar(title: const Text('CFA Preview')),
      body: caseAsync.when(
        data: (caseData) {
          if (caseData == null || caseData.cfaRecord == null) {
            return const Center(
              child: Text('No CFA record found for this case.'),
            );
          }

          final cfa = caseData.cfaRecord!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Certificate to File Action',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text('Case ID: ${caseData.id}'),
                    const SizedBox(height: 4),
                    Text('Certificate No.: ${cfa.certificateNumber}'),
                    const SizedBox(height: 4),
                    Text(
                      'Issued: ${DateFormat.yMMMMd().add_jm().format(cfa.issuedAt)}',
                    ),
                    const SizedBox(height: 4),
                    Text('Signatory: ${cfa.signatoryName}'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Verification Hash',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(cfa.verificationHash),
                    const SizedBox(height: 10),
                    Text(
                      'QR Payload',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(cfa.qrPayload),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
