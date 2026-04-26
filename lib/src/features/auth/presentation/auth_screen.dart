import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../cases/domain/user_role.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();

  bool _usePhoneOtp = true;
  bool _otpSent = false;
  bool _obscurePassword = true;
  UserRole _role = UserRole.citizen;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  // ── Phone OTP helpers ───────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _snack('Enter your phone number first.');
      return;
    }
    await ref.read(authControllerProvider.notifier).sendMockOtp(phone);
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState is AsyncError) {
      _snack(authState.error.toString());
      return;
    }
    setState(() => _otpSent = true);
  }

  Future<void> _verifyOtp() async {
    final name = _fullNameCtrl.text.trim();
    if (name.isEmpty) { _snack('Enter your full name.'); return; }
    await ref.read(authControllerProvider.notifier).verifyMockOtp(
          phone: _phoneCtrl.text.trim(),
          code: _otpCtrl.text.trim(),
          role: _role,
          fullName: name,
        );
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState is AsyncError) {
      _snack(authState.error.toString());
    } else if (authState is AsyncData) {
      context.go('/dashboard');
    }
  }

  // ── Email helpers ────────────────────────────────────────────────────────

  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    final name = _fullNameCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack('Enter email and password.');
      return;
    }
    await ref.read(authControllerProvider.notifier).signInWithEmail(
          email: email,
          password: pass,
          role: _role,
          fullName: name,
        );
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState is AsyncError) {
      _snack(_friendlyError(authState.error));
    } else if (authState is AsyncData) {
      context.go('/dashboard');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _friendlyError(Object? e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect password. Try again.';
    }
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    return msg;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

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
                    // ── Header card ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                            colors: <Color>[
                            AppTheme.primary,
                            AppTheme.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color:
                                AppTheme.primary.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Image.asset(
                            'lib/src/assets/esumbong_logo.png',
                            width: 52,
                            height: 52,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Image.asset(
                                  'lib/src/assets/esumbong_text.png',
                                  height: 22,
                                  alignment: Alignment.centerLeft,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Secure access for citizens and barangay staff',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Auth method card ──────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text('Authentication Method',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 10),
                            SegmentedButton<bool>(
                              segments: const <ButtonSegment<bool>>[
                                ButtonSegment<bool>(
                                    value: true, label: Text('Phone OTP')),
                                ButtonSegment<bool>(
                                    value: false, label: Text('Email Auth')),
                              ],
                              selected: <bool>{_usePhoneOtp},
                              onSelectionChanged: (v) => setState(() {
                                _usePhoneOtp = v.first;
                                _otpSent = false;
                              }),
                            ),
                            const SizedBox(height: 16),

                            // ── Full name ─────────────────────────────────
                            TextField(
                              controller: _fullNameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'e.g. Juan Dela Cruz',
                                prefixIcon:
                                    Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Phone / Email fields ──────────────────────
                            if (_usePhoneOtp) ...<Widget>[
                              TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                enabled: !_otpSent,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g. 09171234567',
                                  prefixIcon:
                                      Icon(Icons.phone_android_rounded),
                                ),
                              ),
                              if (_otpSent) ...<Widget>[
                                const SizedBox(height: 12),
                                // OTP banner
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(Icons.info_outline_rounded,
                                          size: 18,
                                          color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Mock OTP sent — enter any 6 digits to continue.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _otpCtrl,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'OTP Code',
                                    hintText: '6-digit code',
                                    prefixIcon:
                                        Icon(Icons.lock_outline_rounded),
                                    counterText: '',
                                  ),
                                ),
                              ],
                            ] else ...<Widget>[
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'e.g. juan@email.com',
                                  prefixIcon: Icon(
                                      Icons.alternate_email_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Min. 6 characters',
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    onPressed: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // ── Role selection ───────────────────────────
                            Text('Continue As',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 10),
                            SegmentedButton<UserRole>(
                              segments: const <ButtonSegment<UserRole>>[
                                ButtonSegment<UserRole>(
                                  value: UserRole.citizen,
                                  label: Text('Citizen'),
                                  icon:
                                      Icon(Icons.person_outline_rounded),
                                ),
                                ButtonSegment<UserRole>(
                                  value: UserRole.barangayStaff,
                                  label: Text('Barangay Staff'),
                                  icon: Icon(Icons.badge_outlined),
                                ),
                              ],
                              selected: <UserRole>{_role},
                              onSelectionChanged: (v) =>
                                  setState(() => _role = v.first),
                            ),
                            const SizedBox(height: 18),

                            // ── Action buttons ───────────────────────────
                            if (isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (_usePhoneOtp)
                              _otpSent
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        ElevatedButton.icon(
                                          onPressed: _verifyOtp,
                                          icon: const Icon(
                                              Icons.verified_outlined),
                                          label:
                                              const Text('Verify & Sign In'),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => setState(
                                              () => _otpSent = false),
                                          child: const Text(
                                              'Change phone number'),
                                        ),
                                      ],
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _sendOtp,
                                      icon: const Icon(
                                          Icons.send_to_mobile_rounded),
                                      label:
                                          const Text('Send OTP Code'),
                                    )
                            else
                              ElevatedButton.icon(
                                onPressed: _signInWithEmail,
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Sign In / Register'),
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
