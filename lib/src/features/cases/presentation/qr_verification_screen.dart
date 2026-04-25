import 'package:flutter/material.dart';

class QrVerificationScreen extends StatefulWidget {
  const QrVerificationScreen({super.key});

  @override
  State<QrVerificationScreen> createState() => _QrVerificationScreenState();
}

class _QrVerificationScreenState extends State<QrVerificationScreen> {
  final _controller = TextEditingController();
  String? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final value = _controller.text.trim();
    if (value.startsWith('KP-')) {
      setState(() {
        _result = 'Verified: Authentic mock CFA for case $value.';
      });
      return;
    }

    setState(() {
      _result = 'Invalid QR payload in this mock implementation.';
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
            const Text('Paste QR payload (sample: KP-2026-0001)'),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'QR Payload'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _verify,
              child: const Text('Verify'),
            ),
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
