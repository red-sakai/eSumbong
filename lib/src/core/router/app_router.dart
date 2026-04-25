import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_panel_screen.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/cases/domain/user_role.dart';
import '../../features/cases/presentation/case_details_screen.dart';
import '../../features/cases/presentation/cfa_preview_screen.dart';
import '../../features/cases/presentation/file_complaint_screen.dart';
import '../../features/cases/presentation/hearing_schedule_screen.dart';
import '../../features/cases/presentation/qr_verification_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

/// Routes that don't require authentication.
const _publicRoutes = <String>['/', '/auth'];

/// Routes only barangay staff may access.
const _staffOnlyRoutes = <String>['/admin', '/qr-verify'];

/// Routes only citizens may access.
const _citizenOnlyRoutes = <String>['/file-complaint'];

final appRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild the router whenever the auth state changes.
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final signedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final goingToPublic = _publicRoutes.contains(location);

      // Unauthenticated guard
      if (!signedIn && !goingToPublic) return '/auth';
      if (signedIn && location == '/auth') return '/dashboard';

      // Role-based guards (only evaluated when signed in)
      if (signedIn) {
        final user = ref.read(currentUserProvider);
        final role = user?.role;

        // Staff trying to file a complaint → dashboard
        if (role == UserRole.barangayStaff &&
            _citizenOnlyRoutes.contains(location)) {
          return '/dashboard';
        }

        // Citizen trying to access staff-only routes → dashboard
        // Also guard /hearing/:caseId which starts with /hearing/
        if (role == UserRole.citizen) {
          if (_staffOnlyRoutes.contains(location) ||
              location.startsWith('/hearing/')) {
            return '/dashboard';
          }
        }
      }

      return null;
    },
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

/// Listens to Firebase auth state and notifies GoRouter to re-evaluate redirects.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    // Watch the Riverpod auth stream and notify on every change.
    ref.listen<AsyncValue<AppUser?>>(authStateChangesProvider, (prev, next) {
      notifyListeners();
    });
  }
}
