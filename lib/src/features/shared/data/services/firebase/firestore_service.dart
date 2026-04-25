abstract class FirestoreService {
  Future<void> createDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  });

  Future<Map<String, dynamic>?> readDocument({
    required String collection,
    required String id,
  });
}

class FirestoreServiceStub implements FirestoreService {
  @override
  Future<void> createDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    // TODO: Persist case and hearing documents in Firestore.
  }

  @override
  Future<Map<String, dynamic>?> readDocument({
    required String collection,
    required String id,
  }) async {
    return null;
  }
}
