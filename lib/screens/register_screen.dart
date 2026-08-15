import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  bool _isBusy = false;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _startSignup() async {
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Enter a valid email address.');
      return;
    }

    setState(() => _isBusy = true);
    final provider = context.read<AppProvider>();
    provider.clearError();
    final started = await provider.startSignup(email);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (started) {
      final destination = provider.firebaseAvailable
          ? '/signup-verification'
          : '/body-data-step1';
      Navigator.of(context).pushNamedAndRemoveUntil(destination, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text('Join us to start your wellness journey.',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Email Address',
                            style: textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _startSignup(),
                          decoration: const InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'After you submit, a verification link will be sent to your email. You will have five minutes to verify it, even if the app is removed from memory. You will choose your password after verification.',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isBusy ? null : _startSignup,
                          child: _isBusy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Send Verification Email'),
                        ),
                        if (_localError != null) ...[
                          const SizedBox(height: 12),
                          Text(_localError!,
                              style: TextStyle(color: colors.error)),
                        ],
                        Consumer<AppProvider>(
                          builder: (_, provider, __) =>
                              provider.errorMessage == null
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(provider.errorMessage!,
                                          style: TextStyle(color: colors.error)),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text('Login',
                          style: textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
