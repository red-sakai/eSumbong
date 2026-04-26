import 'dart:async';

import 'package:intl/intl.dart';

import '../domain/case_event.dart';
import '../domain/case_status.dart';
import '../domain/cfa_record.dart';
import '../domain/complaint_case.dart';
import 'case_repository.dart';

class MockCaseRepository implements CaseRepository {
  MockCaseRepository() {
    _cases = <ComplaintCase>[
      ComplaintCase(
        id: 'KP-2026-0001',
        createdByUserId: 'seed-user-ana',
        createdByPhone: '+639111111111',
        complainantName: 'Ana Santos',
        respondentName: 'Pedro Reyes',
        respondentPhone: '+639171234567',
        description: 'Noise complaint and recurring disturbance at night.',
        incidentDate: DateTime.now().subtract(const Duration(days: 9)),
        status: CaseStatus.summonsSent,
        noShowCount: 1,
        events: <CaseEvent>[
          CaseEvent(
            title: 'Case Filed',
            description: 'Complaint submitted through eSumbong app.',
            timestamp: DateTime.now().subtract(const Duration(days: 9)),
          ),
          CaseEvent(
            title: 'Summons Sent',
            description: 'Summons sent to respondent via SMS and app.',
            timestamp: DateTime.now().subtract(const Duration(days: 6)),
          ),
        ],
      ),
      ComplaintCase(
        id: 'KP-2026-0002',
        createdByUserId: 'seed-user-maria',
        createdByPhone: '+639222222222',
        complainantName: 'Maria Lopez',
        respondentName: 'Jose Garcia',
        respondentPhone: '+639181234567',
        description: 'Boundary dispute requiring mediation hearing.',
        incidentDate: DateTime.now().subtract(const Duration(days: 15)),
        status: CaseStatus.hearingScheduled,
        events: <CaseEvent>[
          CaseEvent(
            title: 'Case Filed',
            description: 'Supporting photos attached by complainant.',
            timestamp: DateTime.now().subtract(const Duration(days: 15)),
          ),
          CaseEvent(
            title: 'Hearing Scheduled',
            description: 'Hearing set for next barangay mediation session.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ];
  }

  final StreamController<List<ComplaintCase>> _controller =
      StreamController<List<ComplaintCase>>.broadcast();
  late List<ComplaintCase> _cases;

  @override
  Stream<List<ComplaintCase>> watchCases() async* {
    yield List<ComplaintCase>.unmodifiable(_cases);
    yield* _controller.stream;
  }

  @override
  Future<void> createCase(ComplaintCase complaintCase) async {
    _cases = <ComplaintCase>[complaintCase, ..._cases];
    _emit();
  }

  @override
  Future<ComplaintCase?> getCaseById(String caseId) async {
    for (final item in _cases) {
      if (item.id == caseId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> scheduleHearing({
    required String caseId,
    required DateTime hearingDate,
  }) async {
    _cases = _cases.map((item) {
      if (item.id != caseId) {
        return item;
      }
      final event = CaseEvent(
        title: 'Hearing Scheduled',
        description:
            'Set for ${DateFormat.yMMMMd().add_jm().format(hearingDate)}',
        timestamp: DateTime.now(),
      );
      return item.copyWith(
        status: CaseStatus.hearingScheduled,
        events: <CaseEvent>[...item.events, event],
      );
    }).toList();
    _emit();
  }

  @override
  Future<void> logNoShow(String caseId) async {
    _cases = _cases.map((item) {
      if (item.id != caseId) {
        return item;
      }
      final count = item.noShowCount + 1;
      final shouldGenerateCfa = count >= 3;
      
      var updated = item.copyWith(
        noShowCount: count,
        status: shouldGenerateCfa ? CaseStatus.failedMediation : item.status,
        events: <CaseEvent>[
          ...item.events,
          CaseEvent(
            title: 'No Show Logged',
            description: 'Respondent no-show count updated to $count.',
            timestamp: DateTime.now(),
          ),
        ],
      );

      if (shouldGenerateCfa) {
        final cfaRecord = _buildCfaRecord(updated);
        updated = updated.copyWith(
          cfaGenerated: true,
          cfaRecord: cfaRecord,
          status: CaseStatus.completed,
          events: <CaseEvent>[
            ...updated.events,
            CaseEvent(
              title: 'Certificate to File Action Generated',
              description:
                  'Auto-generated due to 3 no-shows. Certificate ${cfaRecord.certificateNumber} issued.',
              timestamp: DateTime.now(),
            ),
          ],
        );
      }
      return updated;
    }).toList();
    _emit();
  }

  @override
  Future<void> generateCfa(String caseId) async {
    _cases = _cases.map((item) {
      if (item.id != caseId || item.cfaGenerated) {
        return item;
      }
      final cfaRecord = _buildCfaRecord(item);

      return item.copyWith(
        cfaGenerated: true,
        cfaRecord: cfaRecord,
        status: CaseStatus.completed,
        events: <CaseEvent>[
          ...item.events,
          CaseEvent(
            title: 'Certificate to File Action Generated',
            description:
                'Certificate ${cfaRecord.certificateNumber} issued and signed by ${cfaRecord.signatoryName}.',
            timestamp: DateTime.now(),
          ),
        ],
      );
    }).toList();
    _emit();
  }

  @override
  Future<void> dismissCase(String caseId) async {
    _cases = _cases.map((item) {
      if (item.id != caseId) {
        return item;
      }
      return item.copyWith(
        status: CaseStatus.dismissed,
        events: <CaseEvent>[
          ...item.events,
          CaseEvent(
            title: 'Case Dismissed',
            description: 'This case has been dismissed by the Barangay Staff.',
            timestamp: DateTime.now(),
          ),
        ],
      );
    }).toList();
    _emit();
  }

  @override
  Future<void> declineCfa(String caseId) async {
    _cases = _cases.map((item) {
      if (item.id != caseId) {
        return item;
      }
      return item.copyWith(
        cfaDeclined: true,
        events: <CaseEvent>[
          ...item.events,
          CaseEvent(
            title: 'CFA Generation Declined',
            description:
                'The Barangay Staff declined to generate a CFA after the 30-day period.',
            timestamp: DateTime.now(),
          ),
        ],
      );
    }).toList();
    _emit();
  }

  CfaRecord _buildCfaRecord(ComplaintCase item) {
    final issuedAt = DateTime.now();
    final year = DateFormat('yyyy').format(issuedAt);
    final certificateNumber = 'CFA-$year-${item.id.replaceAll('KP-', '')}';
    final signatoryName = 'Lupon Secretary Maria Dela Cruz';
    final issuedIso = issuedAt.toIso8601String();
    final basePayload =
        'CFA|case=${item.id}|cert=$certificateNumber|issued=$issuedIso|signatory=$signatoryName';
    final verificationHash = _hashText(basePayload);
    final qrPayload = '$basePayload|hash=$verificationHash';

    return CfaRecord(
      certificateNumber: certificateNumber,
      issuedAt: issuedAt,
      signatoryName: signatoryName,
      qrPayload: qrPayload,
      verificationHash: verificationHash,
    );
  }

  String _hashText(String input) {
    int hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  void _emit() {
    _controller.add(List<ComplaintCase>.unmodifiable(_cases));
  }
}
