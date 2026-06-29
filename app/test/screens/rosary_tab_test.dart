import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/rosary_tab.dart';
import '../test_helper.dart';

void main() {
  group('RosaryTab Screen', () {
    testWidgets('renders all placeholder and info text correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: RosaryTab())),
      );

      expect(find.text('The Holy Rosary'), findsOneWidget);
      expect(find.text('Contemplate the Mysteries'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);
      expect(
        find.textContaining('A fully interactive Rosary guide'),
        findsOneWidget,
      );
      expect(
        find.textContaining('The Rosary is the weapon for these times.'),
        findsOneWidget,
      );
    });

    testGoldens('renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario('Rosary Tab Initial State', const RosaryTab());

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(400, 750),
      );

      await screenMatchesGolden(tester, 'rosary_tab_golden');
    });
  });
}
