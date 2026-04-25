import 'package:flutter/foundation.dart';

/// [MOCK] Firebase Cloud Messaging service.
///
/// All methods are silent no-ops — no real FCM calls are made.
/// This avoids any platform permission dialogs or dependency on the
/// Firebase Messaging SDK at runtime.
///
/// To enable real FCM:
/// 1. Uncomment the imports and SDK calls below.
/// 2. Add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).
/// 3. Register the background handler in main.dart.

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint('[FCM] Background: ${message.messageId}');
// }

/// Placeholder so main.dart can still reference this symbol.
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  debugPrint('[FCM] [MOCK] Background message received (no-op).');
}

class FcmService {
  /// Initialises FCM. Currently a no-op mock.
  Future<void> init() async {
    debugPrint('[FCM] [MOCK] init() — skipped (Spark plan).');

    // TODO(upgrade): uncomment when on Blaze plan:
    // final settings = await FirebaseMessaging.instance.requestPermission(...);
    // await _refreshAndSaveToken();
    // FirebaseMessaging.onMessage.listen(...);
    // FirebaseMessaging.onMessageOpenedApp.listen(...);
  }

  /// Subscribes to push updates for a specific case. Currently a no-op mock.
  Future<void> subscribeToCase(String caseId) async {
    debugPrint('[FCM] [MOCK] subscribeToCase(case_$caseId) — skipped.');
    // TODO(upgrade): await FirebaseMessaging.instance.subscribeToTopic('case_$caseId');
  }

  /// Unsubscribes from push updates for a specific case. Currently a no-op mock.
  Future<void> unsubscribeFromCase(String caseId) async {
    debugPrint('[FCM] [MOCK] unsubscribeFromCase(case_$caseId) — skipped.');
    // TODO(upgrade): await FirebaseMessaging.instance.unsubscribeFromTopic('case_$caseId');
  }
}
