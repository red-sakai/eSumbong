import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../domain/case_event.dart';
import '../domain/case_status.dart';
import '../domain/cfa_record.dart';
import '../domain/complaint_case.dart';
import 'case_repository.dart';

/// Real Firestore implementation of [CaseRepository].
/// Collection: `cases` — each document ID is the case ID (e.g. `KP-2026-0001`).
class FirestoreCaseRepository implements CaseRepository {
  FirestoreCaseRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('cases');

  @override
  Stream<List<ComplaintCase>> watchCases() {
    return _col
        .orderBy('incidentDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ComplaintCase.fromJson(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> createCase(ComplaintCase c) async {
    await _col.doc(c.id).set(c.toJson());
  }

  @override
  Future<ComplaintCase?> getCaseById(String caseId) async {
    final doc = await _col.doc(caseId).get();
    if (!doc.exists) return null;
    return ComplaintCase.fromJson(doc.id, doc.data()!);
  }

  @override
  Future<void> scheduleHearing({
    required String caseId,
    required DateTime hearingDate,
  }) async {
    final event = CaseEvent(
      title: 'Hearing Scheduled',
      description:
          'Set for ${DateFormat.yMMMMd().add_jm().format(hearingDate)}',
      timestamp: DateTime.now(),
    );
    await _col.doc(caseId).update(<String, dynamic>{
      'status': CaseStatus.hearingScheduled.name,
      'events': FieldValue.arrayUnion(<Map<String, dynamic>>[event.toJson()]),
    });
  }

  @override
  Future<void> logNoShow(String caseId) async {
    final doc = await _col.doc(caseId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final count = (data['noShowCount'] as int? ?? 0) + 1;
    final shouldFail = count >= 3;
    final event = CaseEvent(
      title: 'No Show Logged',
      description: 'Respondent no-show count updated to $count.',
      timestamp: DateTime.now(),
    );

    if (shouldFail) {
      // Re-fetch or reconstruct the case to use generateCfa
      final complaintCase = ComplaintCase.fromJson(doc.id, data).copyWith(
        noShowCount: count,
        events: <CaseEvent>[
          ...ComplaintCase.fromJson(doc.id, data).events,
          event,
        ],
      );
      final cfaRecord = _buildCfaRecord(complaintCase);
      final cfaEvent = CaseEvent(
        title: 'Certificate to File Action Generated',
        description:
            'Auto-generated due to 3 no-shows. Certificate ${cfaRecord.certificateNumber} issued.',
        timestamp: DateTime.now(),
      );
      await _col.doc(caseId).update(<String, dynamic>{
        'noShowCount': count,
        'cfaGenerated': true,
        'cfaRecord': cfaRecord.toJson(),
        'status': CaseStatus.completed.name,
        'events': FieldValue.arrayUnion(<Map<String, dynamic>>[
          event.toJson(),
          cfaEvent.toJson(),
        ]),
      });
    } else {
      await _col.doc(caseId).update(<String, dynamic>{
        'noShowCount': count,
        'events': FieldValue.arrayUnion(<Map<String, dynamic>>[event.toJson()]),
      });
    }
  }

  @override
  Future<void> generateCfa(String caseId) async {
    final doc = await _col.doc(caseId).get();
    if (!doc.exists) return;
    final complaintCase = ComplaintCase.fromJson(doc.id, doc.data()!);
    if (complaintCase.cfaGenerated) return;
    final cfaRecord = _buildCfaRecord(complaintCase);
    final event = CaseEvent(
      title: 'Certificate to File Action Generated',
      description:
          'Certificate ${cfaRecord.certificateNumber} issued and signed by ${cfaRecord.signatoryName}.',
      timestamp: DateTime.now(),
    );
    await _col.doc(caseId).update(<String, dynamic>{
      'cfaGenerated': true,
      'cfaRecord': cfaRecord.toJson(),
      'status': CaseStatus.completed.name,
      'events': FieldValue.arrayUnion(<Map<String, dynamic>>[event.toJson()]),
    });
  }

  @override
  Future<void> dismissCase(String caseId) async {
    final event = CaseEvent(
      title: 'Case Dismissed',
      description: 'This case has been dismissed by the Barangay Staff.',
      timestamp: DateTime.now(),
    );
    await _col.doc(caseId).update(<String, dynamic>{
      'status': CaseStatus.dismissed.name,
      'events': FieldValue.arrayUnion(<Map<String, dynamic>>[event.toJson()]),
    });
  }

  @override
  Future<void> declineCfa(String caseId) async {
    final event = CaseEvent(
      title: 'CFA Generation Declined',
      description:
          'The Barangay Staff declined to generate a CFA after the 30-day period.',
      timestamp: DateTime.now(),
    );
    await _col.doc(caseId).update(<String, dynamic>{
      'cfaDeclined': true,
      'events': FieldValue.arrayUnion(<Map<String, dynamic>>[event.toJson()]),
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  CfaRecord _buildCfaRecord(ComplaintCase item) {
    final issuedAt = DateTime.now();
    final year = DateFormat('yyyy').format(issuedAt);
    final certificateNumber = 'CFA-$year-${item.id.replaceAll('KP-', '')}';
    const signatoryName = 'Lupon Secretary Maria Dela Cruz';
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
}
