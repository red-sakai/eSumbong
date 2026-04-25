import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cases/data/case_providers.dart';
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

  static const _titles = <String>[
    'Overview',
    'Ezu',
    'Notifications',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _DashboardHomeTab(),
      const EzuChatbotScreen(),
      const NotificationsScreen(),
      ProfileScreen(onLogout: () => context.go('/auth')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'View notifications',
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/file-complaint'),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('File Complaint'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'Ezu',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardHomeTab extends ConsumerWidget {
  const _DashboardHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(visibleCasesStreamProvider);
    final theme = Theme.of(context);

    return casesAsync.when(
      data: (cases) {
        final noShows = cases.fold<int>(
          0,
          (sum, item) => sum + item.noShowCount,
        );
        final cfaReady = cases.where((c) => c.noShowCount >= 3).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: <Widget>[
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
                    'Community Mediation Monitor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track cases and hearings in one place.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          label: 'Open',
                          value: '${cases.length}',
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: 'No-Shows',
                          value: '$noShows',
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: 'CFA Ready',
                          value: '$cfaReady',
                          dark: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text('Recent Cases', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            ...cases
                .take(4)
                .map(
                  (item) => AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.id),
                      subtitle: Text(
                        'Complainant: ${item.complainantName}\nRespondent: ${item.respondentName}',
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
    final valueColor = dark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final labelColor = dark
        ? Colors.white.withValues(alpha: 0.84)
        : Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      children: <Widget>[
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: labelColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
