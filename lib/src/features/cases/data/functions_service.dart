import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/data/services/unisms/unisms_service.dart';

class FunctionsService {
  FunctionsService(this._uniSmsService);

  final UniSmsService _uniSmsService;

  /// Sends a realistic UniSMS summons message into the demo activity log.
  Future<UniSmsMessage> sendSummons({
    required String caseId,
    required String respondentPhone,
    required DateTime hearingDate,
  }) async {
    final formattedDate = DateFormat.yMMMd().add_jm().format(hearingDate);
    final content =
        'eSumbong notice: Case $caseId hearing is on $formattedDate. Please attend.';
    debugPrint(
      '[FunctionsService] sendSummons → caseId=$caseId recipient=$respondentPhone',
    );
    return _uniSmsService.sendSms(
      recipient: respondentPhone,
      content: content,
      senderId: 'eSumbong',
      metadata: <String, dynamic>{
        'case_id': caseId,
        'hearing_date': hearingDate.toIso8601String(),
        'template': 'summons_notice',
      },
    );
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
    return fakePdfUrl;
  }
}

final functionsServiceProvider = Provider<FunctionsService>(
  (ref) => FunctionsService(ref.read(uniSmsServiceProvider)),
);
