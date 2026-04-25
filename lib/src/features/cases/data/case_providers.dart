import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/user_role.dart';
import '../domain/complaint_case.dart';
import 'case_repository.dart';
import 'mock_case_repository.dart';

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  return MockCaseRepository();
});

final casesStreamProvider = StreamProvider<List<ComplaintCase>>((ref) {
  final repository = ref.watch(caseRepositoryProvider);
  return repository.watchCases();
});

final visibleCasesStreamProvider = StreamProvider<List<ComplaintCase>>((ref) {
  final repository = ref.watch(caseRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return Stream<List<ComplaintCase>>.value(const <ComplaintCase>[]);
  }

  if (currentUser.role == UserRole.barangayStaff) {
    return repository.watchCases();
  }

  final normalizedName = currentUser.fullName.trim().toLowerCase();
  final normalizedPhone = currentUser.phoneOrEmail.trim().toLowerCase();

  return repository.watchCases().map(
    (cases) => cases
        .where((item) {
          final matchesOwner = item.createdByUserId == currentUser.id;
          final matchesPhone = normalizedPhone.isNotEmpty &&
              item.createdByPhone.trim().toLowerCase() == normalizedPhone;
          final matchesComplainantName =
              item.complainantName.trim().toLowerCase() == normalizedName;
          return matchesOwner || matchesPhone || matchesComplainantName;
        })
        .toList(growable: false),
  );
});

final caseByIdProvider = StreamProvider.family<ComplaintCase?, String>((
  ref,
  caseId,
) {
  final repository = ref.watch(caseRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return Stream<ComplaintCase?>.value(null);
  }

  final normalizedName = currentUser.fullName.trim().toLowerCase();
  final normalizedPhone = currentUser.phoneOrEmail.trim().toLowerCase();

  return repository.watchCases().map((cases) {
    for (final item in cases) {
      if (item.id != caseId) {
        continue;
      }
      if (currentUser.role == UserRole.barangayStaff) {
        return item;
      }

      final matchesOwner = item.createdByUserId == currentUser.id;
      final matchesPhone = normalizedPhone.isNotEmpty &&
          item.createdByPhone.trim().toLowerCase() == normalizedPhone;
      final matchesComplainantName =
          item.complainantName.trim().toLowerCase() == normalizedName;

      if (matchesOwner || matchesPhone || matchesComplainantName) {
        return item;
      }
      return null;
    }
    return null;
  });
});

/// Total number of case-event notifications visible to the current user.
/// Mirrors what [NotificationsScreen] shows so the badge is always in sync.
final notificationCountProvider = Provider<int>((ref) {
  final cases = ref.watch(visibleCasesStreamProvider).valueOrNull;
  if (cases == null) return 0;
  return cases.fold<int>(0, (sum, c) => sum + c.events.length);
});

/// Stores the total notification count at the time the user last
/// opened the Notifications screen. Used to compute the unread count.
final notificationLastSeenProvider = StateProvider<int>((_) => 0);

/// Number of notifications the user has NOT yet seen.
/// Shown on the badge; resets to 0 when [markNotificationsRead] is called.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final total = ref.watch(notificationCountProvider);
  final lastSeen = ref.watch(notificationLastSeenProvider);
  return (total - lastSeen).clamp(0, 999);
});
