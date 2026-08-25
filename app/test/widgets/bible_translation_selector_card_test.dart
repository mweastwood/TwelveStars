import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/widgets/bible_translation_selector_card.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';
import '../test_helper.dart';

void main() {
  group('BibleTranslationSelectorCard Widget Tests', () {
    testWidgets(
      'renders both primary and secondary translations when compareCode is provided',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'DRC',
                compareCode: 'VUL',
                onOpenSelector: (_) {},
                onSwap: () {},
                onClearCompare: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Primary Translation'), findsOneWidget);
        expect(find.text('Douay-Rheims'), findsOneWidget);
        expect(find.text('Secondary Translation'), findsOneWidget);
        expect(find.text('Clementine Vulgate'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'renders primary translation and None when compareCode is null',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'DRC',
                compareCode: null,
                onOpenSelector: (_) {},
                onSwap: () {},
                onClearCompare: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Primary Translation'), findsOneWidget);
        expect(find.text('Douay-Rheims'), findsOneWidget);
        expect(find.text('Secondary Translation'), findsOneWidget);
        expect(find.text('None'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);

        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNull);
      },
    );

    testWidgets(
      'renders primary translation and None when compareCode is "none"',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'CPDV',
                compareCode: 'none',
                onOpenSelector: (_) {},
                onSwap: () {},
                onClearCompare: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Primary Translation'), findsOneWidget);
        expect(find.text('CPDV'), findsOneWidget);
        expect(find.text('Secondary Translation'), findsOneWidget);
        expect(find.text('None'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);

        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNull);
      },
    );

    testWidgets(
      'invokes onOpenSelector with BibleTranslationTarget.primary when primary section is tapped',
      (tester) async {
        BibleTranslationTarget? selectedTarget;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'DRC',
                compareCode: 'VUL',
                onOpenSelector: (target) => selectedTarget = target,
                onSwap: () {},
                onClearCompare: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Douay-Rheims'));
        await tester.pumpAndSettle();

        expect(selectedTarget, equals(BibleTranslationTarget.primary));
      },
    );

    testWidgets(
      'invokes onOpenSelector with BibleTranslationTarget.compare when secondary section is tapped',
      (tester) async {
        BibleTranslationTarget? selectedTarget;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'DRC',
                compareCode: 'VUL',
                onOpenSelector: (target) => selectedTarget = target,
                onSwap: () {},
                onClearCompare: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clementine Vulgate'));
        await tester.pumpAndSettle();

        expect(selectedTarget, equals(BibleTranslationTarget.compare));
      },
    );

    testWidgets(
      'invokes onSwap when swap button is tapped with active comparison translation',
      (tester) async {
        int swapCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'DRC',
                compareCode: 'VUL',
                onOpenSelector: (_) {},
                onSwap: () => swapCount++,
                onClearCompare: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithIcon(IconButton, Icons.swap_horiz));
        await tester.pumpAndSettle();

        expect(swapCount, equals(1));
      },
    );

    testWidgets(
      'does not invoke onSwap when swap button is disabled (compareCode is null or "none")',
      (tester) async {
        int swapCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'DRC',
                compareCode: null,
                onOpenSelector: (_) {},
                onSwap: () => swapCount++,
                onClearCompare: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNull);

        await tester.tap(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(swapCount, equals(0));
      },
    );

    testWidgets(
      'invokes onClearCompare when close icon on secondary section is tapped',
      (tester) async {
        int clearCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleTranslationSelectorCard(
                primaryCode: 'DRC',
                compareCode: 'VUL',
                onOpenSelector: (_) {},
                onSwap: () {},
                onClearCompare: () => clearCount++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(clearCount, equals(1));
      },
    );

    // --- GOLDEN TESTS ---

    testGoldens(
      'renders BibleTranslationSelectorCard with both translations active (Light Theme)',
      (tester) async {
        final builder = GoldenBuilder.column()
          ..addScenario(
            'Both Translations Active (DRC & VUL)',
            BibleTranslationSelectorCard(
              primaryCode: 'DRC',
              compareCode: 'VUL',
              onOpenSelector: (_) {},
              onSwap: () {},
              onClearCompare: () {},
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          wrapper: materialAppWrapper(
            theme: ThemeData.light(useMaterial3: true),
          ),
          surfaceSize: const Size(450, 150),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'bible_translation_selector_card_both_light',
        );
      },
    );

    testGoldens(
      'renders BibleTranslationSelectorCard with both translations active (Dark Theme)',
      (tester) async {
        final builder = GoldenBuilder.column()
          ..addScenario(
            'Both Translations Active (DRC & VUL) - Dark',
            BibleTranslationSelectorCard(
              primaryCode: 'DRC',
              compareCode: 'VUL',
              onOpenSelector: (_) {},
              onSwap: () {},
              onClearCompare: () {},
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          wrapper: materialAppWrapper(
            theme: ThemeData.dark(useMaterial3: true),
          ),
          surfaceSize: const Size(450, 150),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'bible_translation_selector_card_both_dark',
        );
      },
    );

    testGoldens(
      'renders BibleTranslationSelectorCard with single translation active (No Secondary)',
      (tester) async {
        final builder = GoldenBuilder.column()
          ..addScenario(
            'Single Translation Active (No Secondary)',
            BibleTranslationSelectorCard(
              primaryCode: 'DRC',
              compareCode: null,
              onOpenSelector: (_) {},
              onSwap: () {},
              onClearCompare: () {},
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          wrapper: materialAppWrapper(
            theme: ThemeData.light(useMaterial3: true),
          ),
          surfaceSize: const Size(450, 150),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'bible_translation_selector_card_single_active',
        );
      },
    );

    testGoldens(
      'renders BibleTranslationSelectorCard with "none" comparison translation',
      (tester) async {
        final builder = GoldenBuilder.column()
          ..addScenario(
            'Explicit None Secondary Translation',
            BibleTranslationSelectorCard(
              primaryCode: 'CPDV',
              compareCode: 'none',
              onOpenSelector: (_) {},
              onSwap: () {},
              onClearCompare: () {},
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          wrapper: materialAppWrapper(
            theme: ThemeData.light(useMaterial3: true),
          ),
          surfaceSize: const Size(450, 150),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'bible_translation_selector_card_none_active',
        );
      },
    );
  });
}
