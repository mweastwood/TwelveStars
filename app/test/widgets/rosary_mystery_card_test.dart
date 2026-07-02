import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/rosary_helper.dart';
import 'package:twelve_stars/widgets/rosary_mystery_card.dart';
import '../test_helper.dart';

void main() {
  group('RosaryMysteryCard Widget', () {
    const mockMystery = RosaryMystery(
      number: 1,
      title: 'The Annunciation',
      description:
          'The Angel Gabriel appears to Mary to announce that she will conceive the Son of God.',
    );

    testWidgets('renders all details correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: Center(
              child: RosaryMysteryCard(
                mystery: mockMystery,
                mysteryType: RosaryMysteryType.joyful,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mystery 1'), findsOneWidget);
      expect(find.text('Joyful Mysteries'), findsOneWidget);
      expect(find.text('The Annunciation'), findsOneWidget);
      expect(
        find.textContaining('The Angel Gabriel appears to Mary'),
        findsOneWidget,
      );
    });

    testGoldens('renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Rosary Mystery Card State',
          const RosaryMysteryCard(
            mystery: mockMystery,
            mysteryType: RosaryMysteryType.joyful,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(360, 250),
      );

      await screenMatchesGolden(tester, 'rosary_mystery_card_golden');
    });
  });
}
