import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/calendar_tab.dart';
import 'package:twelve_stars/screens/missal_tab.dart';
import '../test_helper.dart';

void main() {
  group('Placeholder Tabs Golden Tests', () {
    testGoldens('CalendarTab renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Calendar Tab Placeholder',
          const SizedBox(height: 600, child: Scaffold(body: CalendarTab())),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'calendar_tab_placeholder_golden');
    });

    testGoldens('MissalTab renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Missal Tab Placeholder',
          const SizedBox(height: 600, child: Scaffold(body: MissalTab())),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'missal_tab_placeholder_golden');
    });
  });
}
