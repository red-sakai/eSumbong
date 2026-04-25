abstract class FirebaseAuthService {
  Future<void> signInWithPhoneOtp(String phoneNumber);
  Future<void> signInWithEmail(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthServiceStub implements FirebaseAuthService {
  @override
  Future<void> signInWithPhoneOtp(String phoneNumber) async {
    // TODO: Wire with Firebase Auth phone OTP.
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    // TODO: Wire with Firebase Auth email/password.
  }

  @override
  Future<void> signOut() async {}
}
