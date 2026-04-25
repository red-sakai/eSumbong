import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [MOCK] Evidence upload service.
///
/// Simulates uploading a file to Firebase Storage without making any real
/// network call. Returns a fake download URL.
///
/// Replace with the real [FirebaseStorage] implementation when you upgrade
/// to a Firebase Blaze (pay-as-you-go) plan.
class StorageService {
  static const int _maxBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> _allowedExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'pdf',
  ];

  /// Simulates uploading [file] and returns a fake download URL.
  ///
  /// Validation is still enforced (file size and allowed types) so the UI
  /// behaves realistically.
  Future<String> uploadEvidence({
    required String caseId,
    required String userId,
    required File file,
  }) async {
    // ── Validate ─────────────────────────────────────────────────────────
    final fileSize = await file.length();
    if (fileSize > _maxBytes) {
      throw ArgumentError(
        'File too large (max 10 MB). '
        'Got ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB.',
      );
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw ArgumentError(
        'File type .$ext is not allowed. '
        'Use: ${_allowedExtensions.join(', ')}.',
      );
    }

    // ── Simulate upload delay ─────────────────────────────────────────────
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final filename = file.uri.pathSegments.last;
    final fakeUrl =
        'https://mock-storage.example.com/evidence/$caseId/$userId/$filename';

    debugPrint('[StorageService] [MOCK] Uploaded $filename → $fakeUrl');
    return fakeUrl;
  }
}

final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);
