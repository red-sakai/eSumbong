import 'package:flutter_test/flutter_test.dart';

import 'package:esumbong/src/features/cases/data/mock_case_repository.dart';
import 'package:esumbong/src/features/cases/domain/case_status.dart';

void main() {
  group('MockCaseRepository', () {
    test('generateCfa creates signed record with strong hash', () async {
      final repository = MockCaseRepository();

      await repository.generateCfa('KP-2026-0001');
      final updatedCase = await repository.getCaseById('KP-2026-0001');

      expect(updatedCase, isNotNull);
      expect(updatedCase!.cfaGenerated, isTrue);
      expect(updatedCase.cfaRecord, isNotNull);
      expect(updatedCase.cfaRecord!.verificationHash.length, equals(64));
      expect(updatedCase.status, equals(CaseStatus.completed));
    });

    test('logNoShow transitions case to failed mediation at threshold', () async {
      final repository = MockCaseRepository();

      await repository.logNoShow('KP-2026-0001');
      await repository.logNoShow('KP-2026-0001');
      final updatedCase = await repository.getCaseById('KP-2026-0001');

      expect(updatedCase, isNotNull);
      expect(updatedCase!.noShowCount, equals(3));
      expect(updatedCase.status, equals(CaseStatus.failedMediation));
    });
  });
}
