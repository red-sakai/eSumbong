import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esumbong/src/features/shared/data/services/unisms/unisms_service.dart';

void main() {
  test('sendSms records a sent message in the UniSMS activity log', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(uniSmsServiceProvider);
    final message = await service.sendSms(
      recipient: '+639171234567',
      content: 'Barangay hearing notice: Case KP-2026-0001 is scheduled tomorrow.',
      senderId: 'eSumbong',
      metadata: <String, dynamic>{'case_id': 'KP-2026-0001'},
    );

    expect(message.status, UniSmsMessageStatus.sent);
    expect(message.referenceId, isNotEmpty);
    expect(container.read(uniSmsDeliveryProvider), hasLength(1));
    expect(container.read(uniSmsDeliveryProvider).first.recipient, '+639171234567');
  });

  test('verifyOtp returns an incorrect-pin response for a bad pin', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(uniSmsServiceProvider);
    final otpMessage = await service.sendOtp(
      recipient: '+639181234567',
      content: 'Hi, Your One-Time-Pin is #{PIN} and valid for 5 minutes.',
      senderId: 'eSumbong',
    );

    final verifyResult = await service.verifyOtp(
      referenceId: otpMessage.referenceId,
      pin: '000000',
    );

    expect(verifyResult['code'], equals(406));
  });
}
