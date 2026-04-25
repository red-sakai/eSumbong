abstract class FunctionsService {
  Future<void> sendSummonsNotification(String caseId);
  Future<void> generateCfaPdf(String caseId);
}

class FunctionsServiceStub implements FunctionsService {
  @override
  Future<void> sendSummonsNotification(String caseId) async {
    // TODO: Trigger Cloud Function for SMS and in-app summons notifications.
  }

  @override
  Future<void> generateCfaPdf(String caseId) async {
    // TODO: Trigger Cloud Function for PDF and QR generation.
  }
}
