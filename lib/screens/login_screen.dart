import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _passwordVisible = false;
  bool _isBusy = false;
  DateTime? _lastBackPress;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isBusy = true);
    final provider = context.read<AppProvider>();
    provider.clearError();
    final ok = await provider.login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) _goNext(provider);
  }

  Future<void> _googleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isBusy = true);
    final provider = context.read<AppProvider>();
    provider.clearError();
    final ok = await provider.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) _goNext(provider);
  }

  Future<void> _linkGoogleAccount() async {
    FocusScope.of(context).unfocus();
    setState(() => _isBusy = true);
    final provider = context.read<AppProvider>();
    final ok = await provider.linkPendingGoogleAccount(
      _emailCtrl.text,
      _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) _goNext(provider);
  }

  void _goNext(AppProvider provider) {
    if (provider.activeProfileId == null) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/body-data-step1', (r) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
    }
  }

  /// Double-press within 1 second to exit the app.
  void _onBackPress() {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 1)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPress();
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // ── Logo ──────────────────────────────────
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'BD',
                        style: tt.headlineLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text('Welcome Back',
                        style: tt.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Log in to track your wellness journey.',
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Form card ─────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email Address',
                              style: tt.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailCtrl,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Password',
                                  style: tt.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text('Forgot Password?',
                                    style: tt.labelSmall
                                        ?.copyWith(color: cs.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            obscureText: !_passwordVisible,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signIn(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign In button
                          ElevatedButton(
                            onPressed: _isBusy ? null : _signIn,
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
                                : const Text('Sign In',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                          ),
                          const SizedBox(height: 12),

                          // Google Sign In
                          OutlinedButton.icon(
                            onPressed: _isBusy ? null : _googleSignIn,
                            icon: _GoogleIcon(),
                            label: const Text('Sign in with Google',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),

                          // Error message
                          Consumer<AppProvider>(
                            builder: (_, p, __) => p.errorMessage != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(p.errorMessage!,
                                        style: tt.bodySmall
                                            ?.copyWith(color: cs.error)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Consumer<AppProvider>(
                            builder: (_, p, __) => p.hasPendingGoogleLink
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: OutlinedButton(
                                      onPressed:
                                          _isBusy ? null : _linkGoogleAccount,
                                      child: const Text(
                                          'Link Google to this account'),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign Up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed('/register'),
                        child: Text(
                          'Sign Up',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple coloured "G" icon that stands in for the real Google logo.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
