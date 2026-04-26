import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cases/data/case_providers.dart';
import '../../cases/domain/case_status.dart';
import '../../shared/data/services/unisms/unisms_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_chip.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesStreamProvider);
    final smsActivity = ref.watch(uniSmsDeliveryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: casesAsync.when(
        data: (cases) {
          final pending = cases
              .where((e) => e.status == CaseStatus.pending)
              .length;
          final hearings = cases
              .where((e) => e.status == CaseStatus.hearingScheduled)
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'UniSMS Delivery Console',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (smsActivity.isEmpty)
                      Text(
                        'No UniSMS traffic yet. Schedule a hearing to simulate a summons.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      ...smsActivity.take(3).map(
                            (message) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    message.status == UniSmsMessageStatus.sent
                                        ? Icons.check_circle_rounded
                                        : message.status ==
                                                UniSmsMessageStatus.failed
                                            ? Icons.error_rounded
                                            : Icons.schedule_rounded,
                                    color: message.status ==
                                            UniSmsMessageStatus.sent
                                        ? const Color(0xFF15803D)
                                        : message.status ==
                                                UniSmsMessageStatus.failed
                                            ? const Color(0xFFB91C1C)
                                            : const Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          '${message.recipient} • ${message.status.name}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        Text(
                                          message.content,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _KpiTile(label: 'Total Cases', value: '${cases.length}'),
                    _KpiTile(label: 'Pending', value: '$pending'),
                    _KpiTile(label: 'Hearings', value: '$hearings'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...cases.map(
                (item) => AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Case No. ${item.id}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      if (item.respondentPhone.isNotEmpty) ...<Widget>[
                        Text(
                          'Respondent SMS: ${item.respondentPhone}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                      ],
                      StatusChip(status: item.status),
                    ],
                  ),
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

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
