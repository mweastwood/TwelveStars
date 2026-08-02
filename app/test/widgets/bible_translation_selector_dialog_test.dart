import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';

void main() {
  group('BibleTranslationSelectorDialog Unit & Widget Tests', () {
    test('BibleTranslationInfo contains all 7 translations', () {
      expect(BibleTranslationInfo.allTranslations.length, equals(7));

      final drc = BibleTranslationInfo.getByCode('DRC');
      expect(drc.name, contains('Douay-Rheims'));
      expect(drc.approvalStatus, equals(BibleApprovalStatus.imprimatur));

      final cpvd = BibleTranslationInfo.getByCode('CPDV');
      expect(cpvd.approvalStatus, equals(BibleApprovalStatus.noImprimatur));

      final lxx = BibleTranslationInfo.getByCode('LXX');
      expect(
        lxx.approvalStatus,
        equals(BibleApprovalStatus.canonicalSourceText),
      );
    });

    testWidgets(
      'BibleTranslationSelectorDialog renders translation options and badges',
      (tester) async {
        String primary = 'CPDV';
        String? compare = 'DRC';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleTranslationSelectorDialog(
                currentPrimaryCode: primary,
                currentCompareCode: compare,
                onPrimarySelected: (val) => primary = val,
                onCompareSelected: (val) => compare = val,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check header title
        expect(find.text('Bible Translations'), findsOneWidget);

        // Check translation cards & badges
        expect(
          find.text('Douay-Rheims Bible (Challoner Revision)'),
          findsOneWidget,
        );
        expect(find.text('✓ Imprimatur'), findsWidgets);

        // Test Swap Button
        await tester.tap(find.byTooltip('Swap Primary & Secondary'));
        await tester.pumpAndSettle();

        expect(primary, equals('DRC'));
        expect(compare, equals('CPDV'));

        // Test Multi-Select Filter Chips (Spanish + Imprimatur)
        await tester.tap(find.widgetWithText(FilterChip, 'Spanish'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilterChip, 'Imprimatur'));
        await tester.pumpAndSettle();

        expect(find.text('Biblia Torres Amat'), findsOneWidget);
        expect(
          find.text('Douay-Rheims Bible (Challoner Revision)'),
          findsNothing,
        );

        // Clear filters
        await tester.tap(find.widgetWithText(ActionChip, 'Clear Filters'));
        await tester.pumpAndSettle();

        // Test Search Bar
        await tester.enterText(find.byType(TextField), 'Clementine');
        await tester.pumpAndSettle();

        expect(find.textContaining('Sixto-Clementine Vulgate'), findsOneWidget);
        expect(
          find.text('Douay-Rheims Bible (Challoner Revision)'),
          findsNothing,
        );
      },
    );

    // --- GOLDEN TESTS ---

    testGoldens(
      'renders BibleTranslationSelectorDialog in Primary mode (Light Theme)',
      (tester) async {
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: BibleTranslationSelectorDialog(
              currentPrimaryCode: 'CPDV',
              currentCompareCode: 'DRC',
              initialTarget: BibleTranslationTarget.primary,
              onPrimarySelected: (_) {},
              onCompareSelected: (_) {},
            ),
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData.light(useMaterial3: true),
          ),
          surfaceSize: const Size(600, 800),
        );
        await tester.pumpAndSettle();
        await screenMatchesGolden(
          tester,
          'bible_translation_dialog_primary_light',
        );
      },
    );

    testGoldens(
      'renders BibleTranslationSelectorDialog in Primary mode (Dark Theme)',
      (tester) async {
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: BibleTranslationSelectorDialog(
              currentPrimaryCode: 'CPDV',
              currentCompareCode: 'DRC',
              initialTarget: BibleTranslationTarget.primary,
              onPrimarySelected: (_) {},
              onCompareSelected: (_) {},
            ),
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData.dark(useMaterial3: true),
          ),
          surfaceSize: const Size(600, 800),
        );
        await tester.pumpAndSettle();
        await screenMatchesGolden(
          tester,
          'bible_translation_dialog_primary_dark',
        );
      },
    );

    testGoldens(
      'renders BibleTranslationSelectorDialog in Secondary mode (Light Theme)',
      (tester) async {
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: BibleTranslationSelectorDialog(
              currentPrimaryCode: 'CPDV',
              currentCompareCode: 'DRC',
              initialTarget: BibleTranslationTarget.compare,
              onPrimarySelected: (_) {},
              onCompareSelected: (_) {},
            ),
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData.light(useMaterial3: true),
          ),
          surfaceSize: const Size(600, 800),
        );
        await tester.pumpAndSettle();
        await screenMatchesGolden(
          tester,
          'bible_translation_dialog_secondary_light',
        );
      },
    );

    testGoldens(
      'renders BibleTranslationSelectorDialog with single translation active (No Secondary)',
      (tester) async {
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: BibleTranslationSelectorDialog(
              currentPrimaryCode: 'DRC',
              currentCompareCode: null,
              initialTarget: BibleTranslationTarget.primary,
              onPrimarySelected: (_) {},
              onCompareSelected: (_) {},
            ),
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData.light(useMaterial3: true),
          ),
          surfaceSize: const Size(600, 800),
        );
        await tester.pumpAndSettle();
        await screenMatchesGolden(
          tester,
          'bible_translation_dialog_single_active',
        );
      },
    );

    testGoldens('renders BibleTranslationSelectorDialog with filters applied', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        Scaffold(
          body: BibleTranslationSelectorDialog(
            currentPrimaryCode: 'CPDV',
            currentCompareCode: 'DRC',
            initialTarget: BibleTranslationTarget.primary,
            onPrimarySelected: (_) {},
            onCompareSelected: (_) {},
          ),
        ),
        wrapper: materialAppWrapper(theme: ThemeData.light(useMaterial3: true)),
        surfaceSize: const Size(600, 800),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Spanish'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Imprimatur'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'bible_translation_dialog_filtered');
    });

    testGoldens('renders BibleTranslationSelectorDialog search query state', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        Scaffold(
          body: BibleTranslationSelectorDialog(
            currentPrimaryCode: 'CPDV',
            currentCompareCode: 'DRC',
            initialTarget: BibleTranslationTarget.primary,
            onPrimarySelected: (_) {},
            onCompareSelected: (_) {},
          ),
        ),
        wrapper: materialAppWrapper(theme: ThemeData.light(useMaterial3: true)),
        surfaceSize: const Size(600, 800),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Clementine');
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'bible_translation_dialog_search');
    });
  });
}
