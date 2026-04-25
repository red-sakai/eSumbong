import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cases/domain/user_role.dart';
import '../domain/app_user.dart';

class AuthController extends StateNotifier<AppUser?> {
  AuthController() : super(null);

  void signIn({
    required String identity,
    required UserRole role,
    required bool usePhoneOtp,
  }) {
    state = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: role == UserRole.barangayStaff ? 'Barangay Staff' : 'Juan Dela Cruz',
      phoneOrEmail: identity,
      role: role,
    );
  }

  void signOut() {
    state = null;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AppUser?>(
  (ref) => AuthController(),
);
