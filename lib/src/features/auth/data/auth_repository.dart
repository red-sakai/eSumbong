import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../cases/domain/user_role.dart';
import '../domain/app_user.dart';
import 'package:esumbong/src/shared/utils/input_sanitizer.dart';

/// Thin wrapper around FirebaseAuth + the `users` Firestore collection.
/// Phone OTP is **mocked**: accepts any 6-digit code and signs in anonymously.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Live stream of the currently signed-in [AppUser], or null when signed out.
  Stream<AppUser?> watchAuthState() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _buildAppUser(user);
    });
  }

  Future<AppUser> _buildAppUser(User user) async {
    final doc = await _users.doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    final roleStr = data['role'] as String? ?? 'citizen';
    final role = UserRole.values.byName(roleStr);
    return AppUser(
      id: user.uid,
      fullName: data['fullName'] as String? ??
          user.displayName ??
          user.email?.split('@').first ??
          'User',
      phoneOrEmail: data['phoneOrEmail'] as String? ??
          user.email ??
          user.phoneNumber ??
          '',
      role: role,
    );
  }

  /// [MOCK] Simulates sending an OTP. In production this would call
  /// `FirebaseAuth.verifyPhoneNumber`. Here it's a no-op delay.
  Future<void> sendMockOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  /// [MOCK] Accepts any 6-digit code and signs in via `signInAnonymously`.
  Future<void> verifyMockOtp({
    required String phone,
    required String code,
    required UserRole role,
    required String fullName,
  }) async {
    if (code.trim().length != 6 ||
        int.tryParse(code.trim()) == null) {
      throw Exception('Enter the 6-digit OTP sent to your phone.');
    }
    final cred = await _auth.signInAnonymously();
    final sanitizedName = InputSanitizer.titleCase(fullName);
    final name = sanitizedName.isEmpty ? 'Citizen' : sanitizedName;
    await cred.user?.updateDisplayName(name);
    await _users.doc(cred.user!.uid).set(<String, dynamic>{
      'fullName': name,
      'phoneOrEmail': phone.trim(),
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Real email + password auth. Tries sign-in; falls back to registration
  /// if the account doesn't exist yet.
  Future<void> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
    required String fullName,
  }) async {
    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        cred = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        final sanitizedName = InputSanitizer.titleCase(fullName);
        final name = sanitizedName.isEmpty
            ? email.split('@').first
            : sanitizedName;
        await cred.user?.updateDisplayName(name);
      } else {
        rethrow;
      }
    }
    await _users.doc(cred.user!.uid).set(<String, dynamic>{
      'fullName': InputSanitizer.titleCase(fullName).isEmpty
          ? cred.user!.displayName ?? email.split('@').first
          : InputSanitizer.titleCase(fullName),
      'phoneOrEmail': email.trim(),
      'role': role.name,
    }, SetOptions(merge: true));
  }

  Future<void> signOut() => _auth.signOut();
}
