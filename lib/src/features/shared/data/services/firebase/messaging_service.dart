abstract class MessagingService {
  Future<void> initialize();
  Future<void> subscribeToCase(String caseId);
}

class MessagingServiceStub implements MessagingService {
  @override
  Future<void> initialize() async {
    // TODO: Initialize Firebase Cloud Messaging.
  }

  @override
  Future<void> subscribeToCase(String caseId) async {
    // TODO: Subscribe user to case-specific topic updates.
  }
}
