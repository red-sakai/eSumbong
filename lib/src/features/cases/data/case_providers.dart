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
  final currentUser = ref.watch(authControllerProvider);

  if (currentUser == null) {
    return Stream<List<ComplaintCase>>.value(const <ComplaintCase>[]);
  }

  if (currentUser.role == UserRole.barangayStaff) {
    return repository.watchCases();
  }

  final normalizedName = currentUser.fullName.trim().toLowerCase();
  return repository.watchCases().map(
    (cases) => cases
        .where((item) {
          final matchesOwner = item.createdByUserId == currentUser.id;
          final matchesComplainantName =
              item.complainantName.trim().toLowerCase() == normalizedName;
          return matchesOwner || matchesComplainantName;
        })
        .toList(growable: false),
  );
});

final caseByIdProvider = StreamProvider.family<ComplaintCase?, String>((
  ref,
  caseId,
) {
  final repository = ref.watch(caseRepositoryProvider);
  final currentUser = ref.watch(authControllerProvider);

  if (currentUser == null) {
    return Stream<ComplaintCase?>.value(null);
  }

  final normalizedName = currentUser.fullName.trim().toLowerCase();

  return repository.watchCases().map((cases) {
    for (final item in cases) {
      if (item.id != caseId) {
        continue;
      }
      if (currentUser.role == UserRole.barangayStaff) {
        return item;
      }

      final matchesOwner = item.createdByUserId == currentUser.id;
      final matchesComplainantName =
          item.complainantName.trim().toLowerCase() == normalizedName;

      if (matchesOwner || matchesComplainantName) {
        return item;
      }
      return null;
    }
    return null;
  });
});
