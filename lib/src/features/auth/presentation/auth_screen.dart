import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cases/domain/user_role.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _identityController = TextEditingController();
  bool _usePhoneOtp = true;

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  void _login(UserRole role) {
    final identity = _identityController.text.trim();
    if (identity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter phone number or email first.')),
      );
      return;
    }

    ref
        .read(authControllerProvider.notifier)
        .signIn(identity: identity, role: role, usePhoneOtp: _usePhoneOtp);

    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF6F8FC), Color(0xFFE6EEF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            color: const Color(
                              0xFF0F766E,
                            ).withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Welcome to e-Lupon',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Secure access for citizens and barangay staff',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Authentication Method',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            SegmentedButton<bool>(
                              segments: const <ButtonSegment<bool>>[
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text('Phone OTP'),
                                ),
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('Email Auth'),
                                ),
                              ],
                              selected: <bool>{_usePhoneOtp},
                              onSelectionChanged: (value) {
                                setState(() => _usePhoneOtp = value.first);
                              },
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _identityController,
                              keyboardType: _usePhoneOtp
                                  ? TextInputType.phone
                                  : TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: _usePhoneOtp
                                    ? 'Phone Number'
                                    : 'Email Address',
                                hintText: _usePhoneOtp
                                    ? 'e.g. 09171234567'
                                    : 'e.g. juan@email.com',
                                prefixIcon: Icon(
                                  _usePhoneOtp
                                      ? Icons.phone_android_rounded
                                      : Icons.alternate_email_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Continue As',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () => _login(UserRole.citizen),
                              icon: const Icon(Icons.person_outline_rounded),
                              label: const Text('Citizen Access'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => _login(UserRole.barangayStaff),
                              icon: const Icon(Icons.badge_outlined),
                              label: const Text('Barangay Staff Access'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
