import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cases/domain/user_role.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

// ── Repository provider ────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

// ── Auth state stream (AppUser? from Firebase) ─────────────────────────────

/// Emits the signed-in [AppUser], or null when signed out.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

/// Synchronous convenience accessor used throughout the app.
/// Returns null while loading or when signed out.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateChangesProvider).valueOrNull;
});

// ── Auth actions controller ────────────────────────────────────────────────

/// Drives sign-in / sign-out actions. State tracks loading / error of the
/// last action — it is NOT the auth state itself (use [currentUserProvider]).
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// [MOCK] Simulates sending an SMS OTP (no real SMS).
  Future<void> sendMockOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.sendMockOtp(phone));
  }

  /// [MOCK] Accepts any 6-digit numeric code and signs in anonymously.
  Future<void> verifyMockOtp({
    required String phone,
    required String code,
    required UserRole role,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.verifyMockOtp(
          phone: phone, code: code, role: role, fullName: fullName),
    );
  }

  /// Real Firebase email + password sign-in / registration.
  Future<void> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(
          email: email, password: password, role: role, fullName: fullName),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signOut);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
