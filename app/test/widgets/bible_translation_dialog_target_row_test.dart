import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';
import 'package:twelve_stars/widgets/common/dual_target_selector_row.dart';

void main() {
  group('BibleTranslationSelectorDialog DualTargetSelectorRow Tests', () {
    testWidgets(
      'renders DualTargetSelectorRow, switches active target, swaps translations, and clears secondary',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        String primary = 'CPDV';
        String? compare = 'DRC';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleTranslationSelectorDialog(
                currentPrimaryCode: primary,
                currentCompareCode: compare,
                initialTarget: BibleTranslationTarget.primary,
                onPrimarySelected: (val) => primary = val,
                onCompareSelected: (val) => compare = val,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify DualTargetSelectorRow is rendered inside the dialog
        expect(find.byType(DualTargetSelectorRow), findsOneWidget);
        expect(find.text('Selecting Primary'), findsOneWidget);
        expect(find.text('Selecting Secondary'), findsOneWidget);
        expect(find.text('CPDV'), findsOneWidget);
        expect(find.text('Douay-Rheims'), findsOneWidget);

        // 2. Switch active target to Secondary on tap and select a translation
        await tester.tap(find.text('Selecting Secondary'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sixto-Clementine Vulgate (Biblia Sacra)'));
        await tester.pumpAndSettle();
        expect(primary, equals('CPDV'));
        expect(compare, equals('VUL'));

        // Switch active target back to Primary on tap and select a translation
        await tester.tap(find.text('Selecting Primary'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Douay-Rheims Bible (Challoner Revision)'));
        await tester.pumpAndSettle();
        expect(primary, equals('DRC'));
        expect(compare, equals('VUL'));

        // 3. Swap Primary & Secondary translations when Swap is tapped
        await tester.tap(find.byTooltip('Swap Primary & Secondary'));
        await tester.pumpAndSettle();
        expect(primary, equals('VUL'));
        expect(compare, equals('DRC'));

        // 4. Clear Secondary translation when close button is tapped
        expect(find.byTooltip('Clear Secondary'), findsOneWidget);
        await tester.tap(find.byTooltip('Clear Secondary'));
        await tester.pumpAndSettle();

        expect(compare, isNull);
        expect(find.text('None'), findsOneWidget);
        expect(find.byTooltip('Clear Secondary'), findsNothing);

        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNull);
      },
    );
  });
}
