import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cases/domain/user_role.dart';

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
    final user = ref.watch(currentUserProvider);
    final isStaff = user?.role == UserRole.barangayStaff;
    final name = user?.fullName ?? 'Guest User';
    final contact = user?.phoneOrEmail ?? '—';
    final initials = _initials(name);

    final body = ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        // ── Hero header ────────────────────────────────────────────────────
        _ProfileHeader(
          initials: initials,
          name: name,
          contact: contact,
          isStaff: isStaff,
        ),

        const SizedBox(height: 24),

        // ── Account section ────────────────────────────────────────────────
        _SectionLabel(label: 'Account'),
        _MenuTile(
          icon: Icons.person_outline_rounded,
          title: 'Full Name',
          trailing: name,
        ),
        _MenuTile(
          icon: isStaff
              ? Icons.email_outlined
              : Icons.phone_outlined,
          title: isStaff ? 'Email Address' : 'Phone Number',
          trailing: contact,
        ),
        _MenuTile(
          icon: isStaff
              ? Icons.admin_panel_settings_outlined
              : Icons.people_outline_rounded,
          title: 'Account Type',
          trailing: isStaff ? 'Barangay Staff' : 'Citizen',
          trailingColor: isStaff
              ? const Color(0xFF0F766E)
              : const Color(0xFF4A5A70),
        ),

        // ── Staff quick access ─────────────────────────────────────────────
        if (isStaff) ...<Widget>[
          const SizedBox(height: 20),
          _SectionLabel(label: 'Management'),
          _MenuTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Panel',
            subtitle: 'View and manage all cases',
            showChevron: true,
            onTap: () => context.push('/admin'),
          ),
          _MenuTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'QR Verify CFA',
            subtitle: 'Scan and verify a Certificate to File Action',
            showChevron: true,
            onTap: () => context.push('/qr-verify'),
          ),
        ],

        // ── App info section ───────────────────────────────────────────────
        const SizedBox(height: 20),
        _SectionLabel(label: 'About'),
        _MenuTile(
          icon: Icons.info_outline_rounded,
          title: 'eSumbong',
          trailing: 'v0.1.0',
        ),
        _MenuTile(
          icon: Icons.balance_rounded,
          title: 'Katarungang Pambarangay',
          subtitle: 'Powered by RA 7160',
        ),

        // ── Danger zone ────────────────────────────────────────────────────
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LogoutButton(
            onLogout: () {
              ref.read(authControllerProvider.notifier).signOut();
              onLogout?.call();
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );

    if (!showAppBar) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: body,
    );
  }

  /// Returns up to 2 initials from the user's name.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ── Profile header ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.contact,
    required this.isStaff,
  });

  final String initials;
  final String name;
  final String contact;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 32),
            // Avatar circle
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 2.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 14),
            // Role badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isStaff
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isStaff ? 'Barangay Staff' : 'Citizen',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Curved bottom clip
            ClipPath(
              clipper: _BottomCurveClipper(),
              child: Container(
                height: 24,
                color: const Color(0xFFF5F7FB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
        size.width / 2, 0, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BottomCurveClipper oldClipper) => false;
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ── Menu tile ──────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingColor,
    this.showChevron = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Color? trailingColor;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = onTap != null || showChevron;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                // Icon container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF10243E),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4A5A70),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing value or chevron
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: trailingColor ?? const Color(0xFF4A5A70),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  )
                else if (isInteractive)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: const Color(0xFF4A5A70).withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logout button ──────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onLogout,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.logout_rounded,
                size: 20,
                color: Color(0xFFE11D48),
              ),
              const SizedBox(width: 10),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
