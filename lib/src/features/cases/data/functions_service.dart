import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [MOCK] Cloud Functions service.
///
/// Both SMS summons and PDF/QR generation are simulated locally.
/// No Firebase Cloud Functions are called.
///
/// Replace each method body with a real `FirebaseFunctions.httpsCallable(...)`
/// call when you deploy the Cloud Functions and upgrade to a Blaze plan.
class FunctionsService {
  /// [MOCK] Simulates sending an SMS summons to the respondent.
  Future<void> sendSummons({
    required String caseId,
    required String respondentPhone,
    required DateTime hearingDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    debugPrint(
      '[FunctionsService] [MOCK] sendSummons → '
      'caseId=$caseId, phone=$respondentPhone, hearing=$hearingDate',
    );
    // TODO(deploy): replace with real callable when Cloud Function is deployed:
    // await FirebaseFunctions.instance
    //     .httpsCallable('sendSummonsNotification')
    //     .call(<String, dynamic>{
    //       'caseId': caseId,
    //       'respondentPhone': respondentPhone,
    //       'hearingDate': hearingDate.toIso8601String(),
    //     });
  }

  /// [MOCK] Simulates triggering PDF and QR code generation for a CFA.
  /// Returns a fake PDF download URL.
  Future<String?> generatePdfAndQr(String caseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final fakePdfUrl =
        'https://mock-functions.example.com/cfa/$caseId/certificate.pdf';
    debugPrint(
      '[FunctionsService] [MOCK] generatePdfAndQr → caseId=$caseId, url=$fakePdfUrl',
    );
    // TODO(deploy): replace with real callable when Cloud Function is deployed:
    // final result = await FirebaseFunctions.instance
    //     .httpsCallable('generateCfaPdf')
    //     .call<Map<String, dynamic>>(<String, dynamic>{'caseId': caseId});
    // return result.data['pdfUrl'] as String?;
    return fakePdfUrl;
  }
}

final functionsServiceProvider = Provider<FunctionsService>(
  (_) => FunctionsService(),
);
