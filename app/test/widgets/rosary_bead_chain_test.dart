import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/rosary_helper.dart';
import 'package:twelve_stars/widgets/rosary_bead_chain.dart';
import '../test_helper.dart';

void main() {
  group('RosaryBeadChain Widget', () {
    final steps = RosaryHelper.generateSteps(RosaryMysteryType.joyful);

    testWidgets('renders list of beads and triggers tap callback', (
      tester,
    ) async {
      int? tappedIndex;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: RosaryBeadChain(
              steps: steps,
              currentStep: 0,
              onStepSelected: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Verify that there are beads rendered (Semantics should find them)
      expect(find.bySemanticsLabel(RegExp(r'Bead 1:')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Bead 2:')), findsOneWidget);

      // Tap on the second bead (index 1)
      await tester.tap(find.bySemanticsLabel(RegExp(r'Bead 2:')));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(1));
    });

    testGoldens('renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Rosary Bead Chain Start State',
          SizedBox(
            height: 300,
            child: RosaryBeadChain(
              steps: steps,
              currentStep: 0,
              onStepSelected: (_) {},
            ),
          ),
        )
        ..addScenario(
          'Rosary Bead Chain Medal Active State',
          SizedBox(
            height: 300,
            child: RosaryBeadChain(
              steps: steps,
              currentStep: 66, // Closing prayers Medal step
              onStepSelected: (_) {},
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(120, 900),
      );

      await screenMatchesGolden(tester, 'rosary_bead_chain_golden');
    });
  });
}
