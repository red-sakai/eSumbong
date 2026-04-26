import '../domain/complaint_case.dart';

abstract class CaseRepository {
  Stream<List<ComplaintCase>> watchCases();
  Future<void> createCase(ComplaintCase complaintCase);
  Future<ComplaintCase?> getCaseById(String caseId);
  Future<void> scheduleHearing({
    required String caseId,
    required DateTime hearingDate,
  });
  Future<void> logNoShow(String caseId);
  Future<void> generateCfa(String caseId);
  Future<void> dismissCase(String caseId);
  Future<void> declineCfa(String caseId);
}
