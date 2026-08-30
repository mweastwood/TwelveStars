import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/bible_translation_dialog.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';

void main() {
  group('BibleTranslationDialog Widget Tests', () {
    testWidgets(
      'renders BibleTranslationSelectorDialog with correct props for primary mode and none compare',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BibleTranslationDialog(
                mode: BibleTranslationDialogMode.primary,
                currentPrimary: 'CPDV',
                currentCompare: 'none',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final selectorFinder = find.byType(BibleTranslationSelectorDialog);
        expect(selectorFinder, findsOneWidget);

        final selector = tester.widget<BibleTranslationSelectorDialog>(
          selectorFinder,
        );
        expect(selector.currentPrimaryCode, equals('CPDV'));
        expect(selector.currentCompareCode, isNull);
        expect(selector.initialTarget, equals(BibleTranslationTarget.primary));
      },
    );

    testWidgets(
      'renders BibleTranslationSelectorDialog with correct props for compare mode with compare code',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BibleTranslationDialog(
                mode: BibleTranslationDialogMode.compare,
                currentPrimary: 'CPDV',
                currentCompare: 'DRC',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final selectorFinder = find.byType(BibleTranslationSelectorDialog);
        expect(selectorFinder, findsOneWidget);

        final selector = tester.widget<BibleTranslationSelectorDialog>(
          selectorFinder,
        );
        expect(selector.currentPrimaryCode, equals('CPDV'));
        expect(selector.currentCompareCode, equals('DRC'));
        expect(selector.initialTarget, equals(BibleTranslationTarget.compare));
      },
    );

    testWidgets(
      'pops selected primary translation code when a translation is tapped in primary mode',
      (tester) async {
        String? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      dialogResult = await showDialog<String>(
                        context: context,
                        builder: (dialogCtx) => const BibleTranslationDialog(
                          mode: BibleTranslationDialogMode.primary,
                          currentPrimary: 'CPDV',
                          currentCompare: 'none',
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(BibleTranslationDialog), findsOneWidget);
        expect(find.text('Bible Translations'), findsOneWidget);

        // Select DRC (Douay-Rheims)
        await tester.tap(find.text('Douay-Rheims Bible (Challoner Revision)'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed and return 'DRC'
        expect(find.byType(BibleTranslationDialog), findsNothing);
        expect(dialogResult, equals('DRC'));
      },
    );

    testWidgets(
      'pops selected compare translation code when a translation is tapped in compare mode',
      (tester) async {
        String? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      dialogResult = await showDialog<String>(
                        context: context,
                        builder: (dialogCtx) => const BibleTranslationDialog(
                          mode: BibleTranslationDialogMode.compare,
                          currentPrimary: 'CPDV',
                          currentCompare: 'DRC',
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(BibleTranslationDialog), findsOneWidget);

        // In compare mode, tap Sixto-Clementine Vulgate to select VUL as secondary
        await tester.tap(find.textContaining('Sixto-Clementine Vulgate'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed and return 'VUL'
        expect(find.byType(BibleTranslationDialog), findsNothing);
        expect(dialogResult, equals('VUL'));
      },
    );

    testWidgets(
      'pops "none" when clearing secondary translation in compare mode',
      (tester) async {
        String? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      dialogResult = await showDialog<String>(
                        context: context,
                        builder: (dialogCtx) => const BibleTranslationDialog(
                          mode: BibleTranslationDialogMode.compare,
                          currentPrimary: 'CPDV',
                          currentCompare: 'DRC',
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(BibleTranslationDialog), findsOneWidget);

        // Tap Clear Secondary button
        await tester.tap(find.byTooltip('Clear Secondary'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed and return 'none'
        expect(find.byType(BibleTranslationDialog), findsNothing);
        expect(dialogResult, equals('none'));
      },
    );

    testWidgets('pops null when close icon button is tapped', (tester) async {
      String? dialogResult = 'initial_val';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    dialogResult = await showDialog<String>(
                      context: context,
                      builder: (dialogCtx) => const BibleTranslationDialog(
                        mode: BibleTranslationDialogMode.primary,
                        currentPrimary: 'CPDV',
                        currentCompare: 'none',
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(BibleTranslationDialog), findsOneWidget);

      // Tap Close button
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed with null
      expect(find.byType(BibleTranslationDialog), findsNothing);
      expect(dialogResult, isNull);
    });
  });
}
