import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../cases/data/case_providers.dart';
import '../../cases/domain/case_status.dart';
import '../../cases/domain/user_role.dart';
import '../../chatbot/presentation/ezu_chatbot_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_chip.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _index = 0;

  /// Marks all current notifications as seen, resetting the badge to 0.
  void _markRead() {
    final total = ref.read(notificationCountProvider);
    ref.read(notificationLastSeenProvider.notifier).state = total;
  }
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isStaff = user?.role == UserRole.barangayStaff;

    final titles = isStaff
        ? const <String>['Cases', 'Ezu', 'Notifications', 'Profile']
        : const <String>['My Complaints', 'Ezu', 'Notifications', 'Profile'];

    final pages = <Widget>[
      isStaff ? const _StaffHomeTab() : const _CitizenHomeTab(),
      const EzuChatbotScreen(),
      const NotificationsScreen(),
      ProfileScreen(onLogout: () => context.go('/auth')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: <Widget>[
          if (isStaff && _index == 0) ...<Widget>[
            IconButton(
              tooltip: 'Admin Panel',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push('/admin'),
            ),
            IconButton(
              tooltip: 'QR Verify CFA',
              icon: const Icon(Icons.qr_code_scanner_rounded),
              onPressed: () => context.push('/qr-verify'),
            ),
          ],
          IconButton(
            onPressed: () {
              _markRead();
              context.push('/notifications');
            },
            tooltip: 'View notifications',
            icon: Badge(
              isLabelVisible: ref.watch(unreadNotificationCountProvider) > 0,
              label: Text(
                '${ref.watch(unreadNotificationCountProvider) > 99 ? '99+' : ref.watch(unreadNotificationCountProvider)}',
              ),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      // Citizens: File Complaint FAB. Staff: no FAB (they manage, not file).
      floatingActionButton: (!isStaff && _index == 0)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/file-complaint'),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('File Complaint'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          if (value == 2) _markRead(); // Notifications tab
          setState(() => _index = value);
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Icon(isStaff
                ? Icons.folder_open_outlined
                : Icons.home_outlined),
            label: isStaff ? 'Cases' : 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'Ezu',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: ref.watch(unreadNotificationCountProvider) > 0,
              label: Text(
                '${ref.watch(unreadNotificationCountProvider) > 99 ? '99+' : ref.watch(unreadNotificationCountProvider)}',
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Staff Home Tab ────────────────────────────────────────────────────────────

/// Full case management view for barangay staff — all cases, KPIs, quick actions.
class _StaffHomeTab extends ConsumerWidget {
  const _StaffHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesStreamProvider);
    final theme = Theme.of(context);

    return casesAsync.when(
      data: (cases) {
        final pending =
            cases.where((e) => e.status == CaseStatus.pending).length;
        final hearings =
            cases.where((e) => e.status == CaseStatus.hearingScheduled).length;
        final cfaReady = cases.where((c) => c.noShowCount >= 3).length;
        final noShows =
            cases.fold<int>(0, (sum, item) => sum + item.noShowCount);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: <Widget>[
            // ── KPI banner ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF0F766E), Color(0xFF155E75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Barangay Case Management',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All active cases assigned to your barangay.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                            label: 'Total', value: '${cases.length}', dark: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                            label: 'Pending', value: '$pending', dark: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                            label: 'Hearings', value: '$hearings', dark: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                            label: 'No-Shows', value: '$noShows', dark: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                            label: 'CFA Ready', value: '$cfaReady', dark: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('All Cases', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...cases.map(
              (item) => AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Case No. ${item.id}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: StatusChip(status: item.status),
                  onTap: () => context.push('/case/${item.id}'),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

// ── Citizen Home Tab ──────────────────────────────────────────────────────────

/// Read-only complaint tracker for citizens — only their own cases, no KPIs.
class _CitizenHomeTab extends ConsumerWidget {
  const _CitizenHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(visibleCasesStreamProvider);
    final theme = Theme.of(context);

    return casesAsync.when(
      data: (cases) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: <Widget>[
            // ── Welcome banner ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF0F766E), Color(0xFF155E75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'My Complaints',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track the status of your submitted complaints.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          label: 'Active',
                          value: '${cases.length}',
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Hearings',
                          value: '${cases.where((c) => c.status == CaseStatus.hearingScheduled).length}',
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Resolved',
                          value: '${cases.where((c) => c.status == CaseStatus.completed).length}',
                          dark: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (cases.isEmpty) ...<Widget>[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: <Widget>[
                    Icon(Icons.inbox_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No complaints filed yet.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "File Complaint" below to get started.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...<Widget>[
              Text('Your Cases', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...cases.map(
                (item) => AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Case No. ${item.id}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: StatusChip(status: item.status),
                    onTap: () => context.push('/case/${item.id}'),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

// ── Shared metric card ────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.dark = false,
  });

  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final valueColor =
        dark ? Colors.white : Theme.of(context).colorScheme.primary;
    final labelColor = dark
        ? Colors.white.withValues(alpha: 0.84)
        : Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      children: <Widget>[
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: labelColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
