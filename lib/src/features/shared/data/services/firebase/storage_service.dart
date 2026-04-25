abstract class StorageService {
  Future<String> uploadEvidence({
    required String caseId,
    required String localPath,
  });
}

class StorageServiceStub implements StorageService {
  @override
  Future<String> uploadEvidence({
    required String caseId,
    required String localPath,
  }) async {
    // TODO: Upload files to Firebase Storage with validation.
    return 'stub://$caseId/$localPath';
  }
}
