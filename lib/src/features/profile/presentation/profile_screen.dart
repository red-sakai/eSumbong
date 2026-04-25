import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../cases/domain/user_role.dart';
import '../../../shared/widgets/app_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.showAppBar = false,
    this.onLogout,
  });

  final bool showAppBar;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(user?.fullName ?? 'Guest User'),
              const SizedBox(height: 4),
              Text(user?.phoneOrEmail ?? 'No identity set'),
              const SizedBox(height: 8),
              Text(
                user?.role == UserRole.barangayStaff ? 'Barangay Staff' : 'Citizen',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (user?.role == UserRole.barangayStaff)
          ElevatedButton.icon(
            onPressed: () => context.push('/admin'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Open Admin Panel'),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            ref.read(authControllerProvider.notifier).signOut();
            onLogout?.call();
          },
          child: const Text('Logout'),
        ),
      ],
    );

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: body,
    );
  }
}
