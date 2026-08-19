import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroundu/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app under a ProviderScope and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dynamicColorSchemeProvider.overrideWith(
            (ref) async => const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Color(0xFFF3F5F2),
              onSurface: Colors.black,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the root MaterialApp is built successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
