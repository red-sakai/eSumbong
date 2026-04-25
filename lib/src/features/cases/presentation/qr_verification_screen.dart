import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/case_providers.dart';

class QrVerificationScreen extends ConsumerStatefulWidget {
  const QrVerificationScreen({super.key, this.initialPayload});

  final String? initialPayload;

  @override
  ConsumerState<QrVerificationScreen> createState() =>
      _QrVerificationScreenState();
}

class _QrVerificationScreenState extends ConsumerState<QrVerificationScreen> {
  final _controller = TextEditingController();
  String? _result;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPayload;
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final casesValue = ref.read(casesStreamProvider);
    final cases = casesValue.value;
    if (cases == null) {
      setState(() {
        _result = 'Case data is still loading. Please try again.';
      });
      return;
    }

    final value = _controller.text.trim();
    final parts = value.split('|');
    if (parts.length < 6 || parts.first != 'CFA') {
      setState(() {
        _result = 'Invalid QR payload format.';
      });
      return;
    }

    final map = <String, String>{};
    for (final part in parts.skip(1)) {
      final index = part.indexOf('=');
      if (index <= 0 || index == part.length - 1) {
        continue;
      }
      map[part.substring(0, index)] = part.substring(index + 1);
    }

    final caseId = map['case'];
    final cert = map['cert'];
    final issued = map['issued'];
    final signatory = map['signatory'];
    final hash = map['hash'];

    if (caseId == null ||
        cert == null ||
        issued == null ||
        signatory == null ||
        hash == null) {
      setState(() {
        _result = 'Invalid QR payload fields.';
      });
      return;
    }

    final matchedCase = cases.where((item) => item.id == caseId).firstOrNull;
    final cfa = matchedCase?.cfaRecord;
    if (matchedCase == null || cfa == null) {
      setState(() {
        _result = 'No generated CFA found for case $caseId.';
      });
      return;
    }

    final isValid = value == cfa.qrPayload && hash == cfa.verificationHash;
    if (isValid) {
      setState(() {
        _result =
            'Verified: Authentic CFA for case $caseId. Certificate ${cfa.certificateNumber}.';
      });
      return;
    }

    setState(() {
      _result = 'Invalid or tampered CFA payload.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Paste QR payload from generated CFA record'),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'QR Payload'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _verify, child: const Text('Verify')),
            if (_result != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(_result!),
            ],
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
