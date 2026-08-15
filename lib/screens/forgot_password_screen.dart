import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendInstructions() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isBusy = true);

    final provider = context.read<AppProvider>();
    provider.clearError();
    final sent = await provider.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _sent = sent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: _sent ? _buildSuccess(tt, cs) : _buildForm(tt, cs),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child:
                Icon(Icons.lock_reset, color: cs.onPrimaryContainer, size: 32),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('Forgot your password?',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "Enter your email and we'll send you instructions to reset it.",
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 36),
        Text('Email Address',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendInstructions(),
          decoration: const InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        Consumer<AppProvider>(
          builder: (context, provider, _) {
            final message = provider.errorMessage;
            if (message == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message,
                style: TextStyle(color: cs.error),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _isBusy ? null : _sendInstructions,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
          child: _isBusy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send Instructions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(TextTheme tt, ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('Email Sent!',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Instructions have been sent to\n${_emailCtrl.text.trim()}',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 36),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
