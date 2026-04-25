import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_panel_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/cases/presentation/case_details_screen.dart';
import '../../features/cases/presentation/cfa_preview_screen.dart';
import '../../features/cases/presentation/file_complaint_screen.dart';
import '../../features/cases/presentation/hearing_schedule_screen.dart';
import '../../features/cases/presentation/qr_verification_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, state) => const AuthScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/file-complaint',
        builder: (_, state) => const FileComplaintScreen(),
      ),
      GoRoute(
        path: '/case/:caseId',
        builder: (_, state) {
          final caseId = state.pathParameters['caseId'] ?? '';
          return CaseDetailsScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/hearing/:caseId',
        builder: (_, state) {
          final caseId = state.pathParameters['caseId'] ?? '';
          return HearingScheduleScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/cfa/:caseId',
        builder: (_, state) {
          final caseId = state.pathParameters['caseId'] ?? '';
          return CfaPreviewScreen(caseId: caseId);
        },
      ),
      GoRoute(path: '/admin', builder: (_, state) => const AdminPanelScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, state) => const NotificationsScreen(showAppBar: true),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, state) => const ProfileScreen(showAppBar: true),
      ),
      GoRoute(
        path: '/qr-verify',
        builder: (_, state) => QrVerificationScreen(
          initialPayload: state.uri.queryParameters['payload'],
        ),
      ),
    ],
  );
});
