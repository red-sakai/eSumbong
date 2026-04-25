import '../../cases/domain/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.phoneOrEmail,
    required this.role,
  });

  final String id;
  final String fullName;
  final String phoneOrEmail;
  final UserRole role;
}
