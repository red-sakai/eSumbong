import 'dart:async';

import 'package:intl/intl.dart';

import '../domain/case_event.dart';
import '../domain/case_status.dart';
import '../domain/complaint_case.dart';
import 'case_repository.dart';

class MockCaseRepository implements CaseRepository {
  MockCaseRepository() {
    _cases = <ComplaintCase>[
      ComplaintCase(
        id: 'KP-2026-0001',
        complainantName: 'Ana Santos',
        respondentName: 'Pedro Reyes',
        description: 'Noise complaint and recurring disturbance at night.',
        incidentDate: DateTime.now().subtract(const Duration(days: 9)),
        status: CaseStatus.summonsSent,
        noShowCount: 1,
        events: <CaseEvent>[
          CaseEvent(
            title: 'Case Filed',
            description: 'Complaint submitted through e-Lupon app.',
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
        complainantName: 'Maria Lopez',
        respondentName: 'Jose Garcia',
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
      return item.copyWith(
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
    }).toList();
    _emit();
  }

  @override
  Future<void> generateCfa(String caseId) async {
    _cases = _cases.map((item) {
      if (item.id != caseId) {
        return item;
      }
      return item.copyWith(
        cfaGenerated: true,
        status: CaseStatus.completed,
        events: <CaseEvent>[
          ...item.events,
          CaseEvent(
            title: 'Certificate to File Action Generated',
            description: 'Mock signed document generated with QR verification.',
            timestamp: DateTime.now(),
          ),
        ],
      );
    }).toList();
    _emit();
  }

  void _emit() {
    _controller.add(List<ComplaintCase>.unmodifiable(_cases));
  }
}
