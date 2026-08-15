import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class SignupVerificationScreen extends StatefulWidget {
  const SignupVerificationScreen({super.key});

  @override
  State<SignupVerificationScreen> createState() =>
      _SignupVerificationScreenState();
}

class _SignupVerificationScreenState extends State<SignupVerificationScreen> {
  static const _totalSeconds = 300;
  static const _pollSeconds = 3;
  static const _resendCooldownSeconds = 59;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  Timer? _resendTimer;
  int _secondsLeft = _totalSeconds;
  int _resendSeconds = 0;
  bool _expired = false;
  bool _initialized = false;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _isSaving = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimers());
  }

  void _startTimers() {
    if (!mounted || _initialized) return;
    _initialized = true;
    final provider = context.read<AppProvider>();
    _secondsLeft = provider.signupSecondsRemaining;
    if (_secondsLeft <= 0) {
      _expire();
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _expire();
      } else {
        setState(() => _secondsLeft--);
      }
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: _pollSeconds),
      (_) => context.read<AppProvider>().checkSignupVerification(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _resendTimer?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _expire() async {
    if (_expired) return;
    _expired = true;
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    await context.read<AppProvider>().expirePendingSignup();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _cancel() async {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    await context.read<AppProvider>().cancelPendingSignup();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    await context.read<AppProvider>().resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resendSeconds = _resendCooldownSeconds);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _finishPassword() async {
    FocusScope.of(context).unfocus();
    final password = _passwordController.text;
    final confirmation = _confirmController.text;
    setState(() => _localError = null);
    if (password.length < 6) {
      setState(() => _localError = 'Password must contain at least 6 characters.');
      return;
    }
    if (password != confirmation) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();
    provider.clearError();
    final completed = await provider.completeSignupPassword(password);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (completed) {
      Navigator.of(context).pushNamedAndRemoveUntil('/body-data-step1', (_) => false);
    }
  }

  String get _formattedTime {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (provider.signupRecoveryStage == SignupRecoveryStage.setPassword) {
      _countdownTimer?.cancel();
      _pollTimer?.cancel();
      return _buildPasswordScreen(context, provider);
    }
    return _buildVerificationScreen(context, provider);
  }

  Widget _buildVerificationScreen(BuildContext context, AppProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final timerColor = _secondsLeft > 120
        ? colors.primary
        : _secondsLeft > 60
            ? Colors.orange
            : colors.error;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    size: 76, color: colors.primary),
                const SizedBox(height: 22),
                Text('Check your email',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 10),
                Text(
                  'We sent a verification link to ${provider.signupEmail}. Open it, then return here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(_formattedTime,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: timerColor,
                            )),
                        const SizedBox(height: 6),
                        const Text('Time remaining to complete sign-up'),
                        const SizedBox(height: 20),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 18),
                        Text(
                          'This temporary sign-up session is saved for five minutes so it can recover if the app is closed or removed from memory.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: _resendSeconds == 0 ? _resend : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(_resendSeconds == 0
                      ? 'Resend verification email'
                      : 'Resend in ${_resendSeconds}s'),
                ),
                const SizedBox(height: 14),
                TextButton(onPressed: _cancel, child: const Text('Cancel sign-up')),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordScreen(BuildContext context, AppProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final error = _localError ?? provider.errorMessage;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finish Account Setup'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.verified_outlined, size: 76, color: Colors.green.shade600),
                const SizedBox(height: 20),
                Text('Email verified',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 8),
                Text('Choose the password you will use to sign in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant)),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible),
                              icon: Icon(_passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmController,
                          obscureText: !_confirmVisible,
                          onSubmitted: (_) => _finishPassword(),
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _confirmVisible = !_confirmVisible),
                              icon: Icon(_confirmVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                            ),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.error)),
                        ],
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _finishPassword,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Continue to Body Data'),
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
    );
  }
}
