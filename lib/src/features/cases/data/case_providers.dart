import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final caseByIdProvider = FutureProvider.family<ComplaintCase?, String>((
  ref,
  caseId,
) {
  final repository = ref.watch(caseRepositoryProvider);
  return repository.getCaseById(caseId);
});
