import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodydata/main.dart';
import 'package:bodydata/providers/app_provider.dart';

class _Harness extends StatelessWidget {
  const _Harness();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppProvider>(
      create: (_) => AppProvider()..initialize(),
      child: const BodyDataApp(),
    );
  }
}

void main() {
  testWidgets('App renders login screen on cold start',
      (WidgetTester tester) async {
    // The shared_preferences mock must be seeded before any read;
    // otherwise getInstance() never resolves in the test zone.
    SharedPreferences.setMockInitialValues({});

    Object? initError;
    await runZonedGuarded(
      () => tester.pumpWidget(const _Harness()),
      (error, stack) => initError ??= error,
    );

    // Let the async initialisation (SharedPreferences load) complete,
    // then pump once more so the UI reflects the finished state.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // On first launch (no stored account) the router shows the login screen.
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
