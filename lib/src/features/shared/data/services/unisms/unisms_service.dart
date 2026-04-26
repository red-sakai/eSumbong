import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UniSmsMessageStatus { pending, retrying, sent, failed }

enum UniSmsMessageKind { sms, otp, blast, bulk }

class UniSmsMessage {
  const UniSmsMessage({
    required this.kind,
    required this.referenceId,
    required this.recipient,
    required this.content,
    required this.createdAt,
    required this.status,
    required this.senderId,
    required this.metadata,
    this.failReason,
    this.relatedId,
  });

  final UniSmsMessageKind kind;
  final String referenceId;
  final String recipient;
  final String content;
  final DateTime createdAt;
  final UniSmsMessageStatus status;
  final String senderId;
  final Map<String, dynamic> metadata;
  final String? failReason;
  final String? relatedId;

  UniSmsMessage copyWith({
    UniSmsMessageStatus? status,
    String? failReason,
  }) {
    return UniSmsMessage(
      kind: kind,
      referenceId: referenceId,
      recipient: recipient,
      content: content,
      createdAt: createdAt,
      status: status ?? this.status,
      senderId: senderId,
      metadata: metadata,
      failReason: failReason ?? this.failReason,
      relatedId: relatedId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status.name,
        'metadata': metadata,
        'content': content,
        'created': createdAt.toUtc().toIso8601String(),
        'reference_id': referenceId,
        'recipient': recipient,
        'fail_reason': failReason,
        'sender_id': senderId,
        'kind': kind.name,
        if (relatedId != null) 'related_id': relatedId,
      };
}

class UniSmsDeliveryController extends StateNotifier<List<UniSmsMessage>> {
  UniSmsDeliveryController() : super(const <UniSmsMessage>[]);

  void _push(UniSmsMessage message) {
    state = <UniSmsMessage>[message, ...state].take(20).toList(growable: false);
  }

  void _replace(UniSmsMessage message) {
    state = state.map((item) => item.referenceId == message.referenceId ? message : item).toList(growable: false);
  }

  void record(UniSmsMessage message) => _push(message);

  void update(UniSmsMessage message) => _replace(message);
}

final uniSmsDeliveryProvider =
    StateNotifierProvider<UniSmsDeliveryController, List<UniSmsMessage>>(
  (_) => UniSmsDeliveryController(),
);

class UniSmsService {
  UniSmsService(this._ref, {http.Client? client})
      : _apiSecretKey = const String.fromEnvironment('UNISMS_API_KEY'),
        _baseUrl = const String.fromEnvironment(
          'UNISMS_BASE_URL',
          defaultValue: 'https://unismsapi.com/api',
        ),
        _client = client ?? http.Client();

  final Ref _ref;
  final String _baseUrl;
  final String _apiSecretKey;
  final http.Client _client;
  final Random _random = _createRandom();
  final Map<String, UniSmsMessage> _messagesByReference = <String, UniSmsMessage>{};
  final Map<String, _OtpChallenge> _otpChallenges = <String, _OtpChallenge>{};
  final Map<String, List<String>> _collectionReferences = <String, List<String>>{};

  static Random _createRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  bool get isConfigured => _apiSecretKey.isNotEmpty;

  String get baseUrl => _baseUrl;

  String get authHeader => 'Basic ${base64Encode(utf8.encode('$_apiSecretKey:'))}';

  Map<String, String> get _jsonHeaders => <String, String>{
        'Authorization': authHeader,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  bool _isValidRecipient(String value) {
    return RegExp(r'^\+63\d{10}$').hasMatch(value);
  }

  String _normalizeContent(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _referenceToken([int length = 12]) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List<String>.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  String _referenceId(String prefix) {
    return '${prefix}_${_referenceToken()}';
  }

  String _generatePin() {
    return List<String>.generate(6, (_) => _random.nextInt(10).toString()).join();
  }

  String _hashPin(String salt, String pin) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );
    return _decodeJsonResponse(response, path);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: _jsonHeaders,
    );
    return _decodeJsonResponse(response, path);
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response, String path) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'UniSMS request failed for $path (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw StateError('Unexpected UniSMS response for $path.');
  }

  Map<String, dynamic> _messageEnvelope(Map<String, dynamic> payload) {
    final message = payload['message'];
    if (message is Map<String, dynamic>) {
      return message;
    }
    return payload;
  }

  UniSmsMessage _messageFromPayload(
    Map<String, dynamic> payload, {
    required UniSmsMessageKind kind,
    required String recipient,
    required String content,
    required String senderId,
    required Map<String, dynamic> metadata,
    String? relatedId,
  }) {
    final statusName = payload['status']?.toString() ?? UniSmsMessageStatus.sent.name;
    final status = UniSmsMessageStatus.values.firstWhere(
      (candidate) => candidate.name == statusName,
      orElse: () => UniSmsMessageStatus.sent,
    );
    final createdRaw = payload['created']?.toString();
    final createdAt = createdRaw == null
        ? DateTime.now().toUtc()
        : DateTime.tryParse(createdRaw)?.toUtc() ?? DateTime.now().toUtc();

    return UniSmsMessage(
      kind: kind,
      referenceId: payload['reference_id']?.toString() ?? _referenceId(kind.name),
      recipient: payload['recipient']?.toString() ?? recipient,
      content: payload['content']?.toString() ?? content,
      createdAt: createdAt,
      status: status,
      senderId: payload['sender_id']?.toString() ?? senderId,
      metadata: <String, dynamic>{
        ...metadata,
        if (payload['metadata'] is Map<String, dynamic>)
          ...payload['metadata'] as Map<String, dynamic>,
      },
      failReason: payload['fail_reason']?.toString(),
      relatedId: relatedId ?? payload['related_id']?.toString(),
    );
  }

  Future<UniSmsMessage?> _pollStatus({
    required String referenceId,
    required UniSmsMessageKind kind,
    required String recipient,
    required String content,
    required String senderId,
    required Map<String, dynamic> metadata,
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().toUtc().add(timeout);
    while (DateTime.now().toUtc().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final payload = _messageEnvelope(await _getJson('/sms/$referenceId'));
      final message = _messageFromPayload(
        payload,
        kind: kind,
        recipient: recipient,
        content: content,
        senderId: senderId,
        metadata: metadata,
      );
      _update(message);
      if (message.status == UniSmsMessageStatus.sent || message.status == UniSmsMessageStatus.failed) {
        return message;
      }
    }
    return null;
  }

  void _record(UniSmsMessage message) {
    _messagesByReference[message.referenceId] = message;
    _ref.read(uniSmsDeliveryProvider.notifier).record(message);
  }

  void _update(UniSmsMessage message) {
    _messagesByReference[message.referenceId] = message;
    _ref.read(uniSmsDeliveryProvider.notifier).update(message);
  }

  Future<UniSmsMessage> _sendLocalSms({
    required String recipient,
    required String content,
    String? senderId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isValidRecipient(recipient)) {
      throw ArgumentError('Recipient must be a valid Philippine E.164 number.');
    }
    final normalizedContent = _normalizeContent(content);
    if (normalizedContent.isEmpty || normalizedContent.length > 160) {
      throw ArgumentError('SMS content must be between 1 and 160 characters.');
    }

    final referenceId = _referenceId('msg');
    final message = UniSmsMessage(
      kind: UniSmsMessageKind.sms,
      referenceId: referenceId,
      recipient: recipient,
      content: normalizedContent,
      createdAt: DateTime.now().toUtc(),
      status: UniSmsMessageStatus.pending,
      senderId: senderId?.trim().isNotEmpty == true ? senderId!.trim() : 'UniSMS',
      metadata: metadata ?? <String, dynamic>{},
    );

    _record(message);

    await Future<void>.delayed(const Duration(milliseconds: 350));
    final sent = message.copyWith(status: UniSmsMessageStatus.sent);
    _update(sent);
    return sent;
  }

  Future<UniSmsMessage> _sendLiveSms({
    required String recipient,
    required String content,
    String? senderId,
    Map<String, dynamic>? metadata,
  }) async {
    final normalizedContent = _normalizeContent(content);
    final response = await _postJson(
      '/sms',
      <String, dynamic>{
        'recipient': recipient,
        'content': normalizedContent,
        if (senderId != null && senderId.trim().isNotEmpty) 'sender_id': senderId.trim(),
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      },
    );
    final payload = _messageEnvelope(response);
    final message = _messageFromPayload(
      payload,
      kind: UniSmsMessageKind.sms,
      recipient: recipient,
      content: normalizedContent,
      senderId: senderId?.trim().isNotEmpty == true ? senderId!.trim() : 'UniSMS',
      metadata: metadata ?? <String, dynamic>{},
    );
    _record(message);

    if (message.status == UniSmsMessageStatus.sent || message.status == UniSmsMessageStatus.failed) {
      return message;
    }

    final settled = await _pollStatus(
      referenceId: message.referenceId,
      kind: UniSmsMessageKind.sms,
      recipient: recipient,
      content: normalizedContent,
      senderId: message.senderId,
      metadata: message.metadata,
      timeout: const Duration(seconds: 8),
    );
    return settled ?? message;
  }

  Future<UniSmsMessage> sendSms({
    required String recipient,
    required String content,
    String? senderId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isValidRecipient(recipient)) {
      throw ArgumentError('Recipient must be a valid Philippine E.164 number.');
    }
    if (isConfigured) {
      return _sendLiveSms(
        recipient: recipient,
        content: content,
        senderId: senderId,
        metadata: metadata,
      );
    }
    return _sendLocalSms(
      recipient: recipient,
      content: content,
      senderId: senderId,
      metadata: metadata,
    );
  }

  Future<UniSmsMessage> getSmsStatus(String referenceId) async {
    final message = _messagesByReference[referenceId];
    if (message == null) {
      if (!isConfigured) {
        throw ArgumentError('Reference ID not found.');
      }
      final response = await _getJson('/sms/$referenceId');
      final payload = _messageEnvelope(response);
      final liveMessage = _messageFromPayload(
        payload,
        kind: UniSmsMessageKind.sms,
        recipient: payload['recipient']?.toString() ?? '',
        content: payload['content']?.toString() ?? '',
        senderId: payload['sender_id']?.toString() ?? 'UniSMS',
        metadata: payload['metadata'] is Map<String, dynamic>
            ? payload['metadata'] as Map<String, dynamic>
            : <String, dynamic>{},
      );
      _update(liveMessage);
      return liveMessage;
    }
    return message;
  }

  Future<Map<String, Object?>> sendBlast({
    required List<String> recipients,
    required String content,
    String? senderId,
    Map<String, dynamic>? metadata,
  }) async {
    if (recipients.isEmpty) {
      throw ArgumentError('Blast requires at least one recipient.');
    }
    if (content.trim().isEmpty || content.length > 160) {
      throw ArgumentError('Blast content must be between 1 and 160 characters.');
    }

    final blastId = _referenceId('blast');
    final refs = <String>[];
    for (final recipient in recipients) {
      final item = await sendSms(
        recipient: recipient,
        content: content,
        senderId: senderId,
        metadata: <String, dynamic>{...?metadata, 'blast_id': blastId},
      );
      refs.add(item.referenceId);
    }
    _collectionReferences[blastId] = refs;
    return <String, Object?>{'total': recipients.length, 'blast_id': blastId};
  }

  Future<Map<String, Object?>> getBlastStatus(String blastId) async {
    final refs = _collectionReferences[blastId];
    if (refs == null) {
      throw ArgumentError('Blast ID not found.');
    }
    return <String, Object?>{
      'messages': refs
          .map((ref) => _messagesByReference[ref]!.toJson())
          .toList(growable: false),
      'total': refs.length,
    };
  }

  Future<Map<String, Object?>> sendBulk({
    required List<Map<String, Object?>> messages,
  }) async {
    if (messages.isEmpty) {
      throw ArgumentError('Bulk request requires at least one message.');
    }

    final bulkId = _referenceId('bulk');
    final refs = <String>[];
    for (final item in messages) {
      final recipient = item['recipient']?.toString() ?? '';
      final content = item['content']?.toString() ?? '';
      final metadata = item['metadata'] as Map<String, dynamic>?;
      final result = await sendSms(
        recipient: recipient,
        content: content,
        senderId: item['sender_id']?.toString(),
        metadata: <String, dynamic>{...?metadata, 'bulk_id': bulkId},
      );
      refs.add(result.referenceId);
    }
    _collectionReferences[bulkId] = refs;
    return <String, Object?>{'total': messages.length, 'bulk_id': bulkId};
  }

  Future<Map<String, Object?>> getBulkStatus(String bulkId) async {
    final refs = _collectionReferences[bulkId];
    if (refs == null) {
      throw ArgumentError('Bulk ID not found.');
    }
    return <String, Object?>{
      'messages': refs
          .map((ref) => _messagesByReference[ref]!.toJson())
          .toList(growable: false),
      'total': refs.length,
    };
  }

  Future<UniSmsMessage> sendOtp({
    required String recipient,
    required String content,
    String? senderId,
  }) async {
    final pin = _generatePin();
    final normalizedContent = content.replaceAll('#{PIN}', pin);
    final message = await sendSms(
      recipient: recipient,
      content: normalizedContent,
      senderId: senderId,
      metadata: <String, dynamic>{'channel': 'otp', 'otp_ttl_seconds': 300},
    );
    final salt = _referenceToken(8);
    _otpChallenges[message.referenceId] = _OtpChallenge(
      pinHash: _hashPin(salt, pin),
      salt: salt,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      attemptsRemaining: 3,
    );
    return message.copyWith(status: UniSmsMessageStatus.sent);
  }

  Future<Map<String, Object?>> verifyOtp({
    required String referenceId,
    required String pin,
  }) async {
    final challenge = _otpChallenges[referenceId];
    if (challenge == null) {
      return <String, Object?>{'code': 404, 'message': 'Reference ID not found.'};
    }
    if (DateTime.now().toUtc().isAfter(challenge.expiresAt)) {
      _otpChallenges.remove(referenceId);
      return <String, Object?>{'code': 410, 'message': 'OTP expired.'};
    }
    final hashedPin = _hashPin(challenge.salt, pin.trim());
    if (hashedPin != challenge.pinHash) {
      final remaining = challenge.attemptsRemaining - 1;
      if (remaining <= 0) {
        _otpChallenges.remove(referenceId);
      } else {
        _otpChallenges[referenceId] = challenge.copyWith(attemptsRemaining: remaining);
      }
      return <String, Object?>{'code': 406, 'message': 'Incorrect Pin.'};
    }
    _otpChallenges.remove(referenceId);
    return <String, Object?>{'code': 200, 'message': 'Success'};
  }

  void close() {
    _client.close();
  }
}

final uniSmsServiceProvider = Provider<UniSmsService>((ref) {
  final service = UniSmsService(ref);
  ref.onDispose(service.close);
  return service;
});

class _OtpChallenge {
  const _OtpChallenge({
    required this.pinHash,
    required this.salt,
    required this.expiresAt,
    required this.attemptsRemaining,
  });

  final String pinHash;
  final String salt;
  final DateTime expiresAt;
  final int attemptsRemaining;

  _OtpChallenge copyWith({int? attemptsRemaining}) {
    return _OtpChallenge(
      pinHash: pinHash,
      salt: salt,
      expiresAt: expiresAt,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
    );
  }
}