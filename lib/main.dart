import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/body_data_step1_screen.dart';
import 'screens/body_data_step2_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_verification_screen.dart';

// Flutter versions before and after the Material 3 theme API migration use
// CardTheme and CardThemeData respectively. Deriving the type from ThemeData
// keeps the project source compatible with both FlutLab and local Flutter.
dynamic _buildCardTheme() {
  final base = ThemeData().cardTheme;
  return (base as dynamic).copyWith(
    elevation: 2.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

Future<void> _enableImmersiveNavigation() async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIChangeCallback((visible) async {
      if (!visible) return;
      await Future<void>.delayed(const Duration(seconds: 5));
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  } catch (_) {
    // Some desktop and test hosts do not expose Android system UI controls.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _enableImmersiveNavigation();

  // Android uses android/app/google-services.json. If the app is run in a
  // test environment or on a platform without Firebase options, the local
  // persistence/auth fallback remains available instead of blocking startup.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is optional for local/test execution.
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const BodyDataApp(),
    ),
  );
}

class BodyDataApp extends StatelessWidget {
  const BodyDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<AppProvider>().isDarkMode;
    return MaterialApp(
      title: 'BodyData',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: _buildCardTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: _buildCardTheme(),
      ),
      // Named routes
      home: const _AppRouter(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/forgot-password':
            return MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen());
          case '/body-data-step1':
            return MaterialPageRoute(
                builder: (_) => const BodyDataStep1Screen());
          case '/body-data-step2':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => BodyDataStep2Screen(
                name: args?['name'] as String? ?? '',
                dobTimestamp: args?['dobTimestamp'] as int? ??
                    DateTime.now().millisecondsSinceEpoch,
                gender: args?['gender'] as String? ?? 'Other',
              ),
            );
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/signup-verification':
            return MaterialPageRoute(
                builder: (_) => const SignupVerificationScreen());
          default:
            return MaterialPageRoute(builder: (_) => const _AppRouter());
        }
      },
    );
  }
}

/// Decides which screen to show on app start based on auth / profile state.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'BD',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        if (provider.hasPendingSignup) {
          return const SignupVerificationScreen();
        }
        if (provider.activeAccountId == null) {
          return const LoginScreen();
        }
        if (provider.activeProfileId == null) {
          return const BodyDataStep1Screen();
        }
        return const DashboardScreen();
      },
    );
  }
}
