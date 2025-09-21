import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aningcall/main.dart';

void main() {
  testWidgets('AningCall app basic test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AningCallApp(),
      ),
    );

    // Wait for initial frame
    await tester.pump();

    // Verify that the app builds without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App title test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AningCallApp(),
      ),
    );

    await tester.pump();

    // Check if the app has the correct title
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('AningCall'));
  });
}