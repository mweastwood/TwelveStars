import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/widgets/prayers/prayer_history_sheet.dart';

import '../../test_helper.dart';

void main() {
  group('PrayerHistoryPanel Widget Tests', () {
    testWidgets('Header & Iconography Verification', (
      WidgetTester tester,
    ) async {
      const testOrigin = '4th Century Latin Mass';
      const testDescription = 'Attributed to Saint Ambrose of Milan.';

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: PrayerHistoryPanel(
              origin: testOrigin,
              description: testDescription,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify structural layout constraints
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsOneWidget);
      final Column columnWidget = tester.widget<Column>(columnFinder);
      expect(columnWidget.mainAxisSize, equals(MainAxisSize.min));
      expect(columnWidget.crossAxisAlignment, equals(CrossAxisAlignment.start));

      final rowFinder = find.byType(Row);
      expect(rowFinder, findsOneWidget);
      final Row rowWidget = tester.widget<Row>(rowFinder);
      expect(rowWidget.children.length, equals(3));
      expect(rowWidget.children[0], isA<Icon>());
      expect(rowWidget.children[1], isA<SizedBox>());
      expect((rowWidget.children[1] as SizedBox).width, equals(6));
      expect(rowWidget.children[2], isA<Expanded>());
      expect(find.byType(Expanded), findsOneWidget);

      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .toList();
      expect(
        sizedBoxes.any((box) => box.width == 6),
        isTrue,
        reason: 'Icon and header should have 6px horizontal spacing',
      );
      expect(
        sizedBoxes.any((box) => box.height == 6),
        isTrue,
        reason: 'Header row and origin should have 6px vertical spacing',
      );
      expect(
        sizedBoxes.any((box) => box.height == 2),
        isTrue,
        reason: 'Origin and description should have 2px vertical spacing',
      );

      // Verify history_edu icon with primary color
      final iconFinder = find.byIcon(Icons.history_edu);
      expect(iconFinder, findsOneWidget);

      final Icon iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, equals(14));

      final BuildContext context = tester.element(
        find.byType(PrayerHistoryPanel),
      );
      final theme = Theme.of(context);
      expect(iconWidget.color, equals(theme.colorScheme.primary));

      // Verify section header text and styling
      final headerFinder = find.text('HISTORICAL CONTEXT');
      expect(headerFinder, findsOneWidget);

      final Text headerTextWidget = tester.widget<Text>(headerFinder);
      expect(headerTextWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(headerTextWidget.style?.color, equals(theme.colorScheme.primary));
      expect(headerTextWidget.style?.letterSpacing, equals(0.5));
    });

    testWidgets('Content & Data Binding', (WidgetTester tester) async {
      const testOrigin = 'Rome, 1570 (Tridentine Missal)';
      const testDescription =
          'Promulgated by Pope St. Pius V following the Council of Trent to '
          'standardize liturgical worship across the Western Church.';

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: PrayerHistoryPanel(
              origin: testOrigin,
              description: testDescription,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify formatted origin string
      final originFinder = find.text('Origin: $testOrigin');
      expect(originFinder, findsOneWidget);

      final Text originTextWidget = tester.widget<Text>(originFinder);
      expect(originTextWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(originTextWidget.style?.fontSize, equals(12));

      // Verify full historical context description string
      final descriptionFinder = find.text(testDescription);
      expect(descriptionFinder, findsOneWidget);

      final Text descriptionTextWidget = tester.widget<Text>(descriptionFinder);
      expect(descriptionTextWidget.style?.fontSize, equals(11));
      expect(descriptionTextWidget.style?.height, equals(1.3));
    });

    testWidgets('Edge Cases & Dynamic Constraints - Empty Strings Handling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: PrayerHistoryPanel(origin: '', description: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HISTORICAL CONTEXT'), findsOneWidget);
      expect(find.text('Origin: '), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data == '' && w.style?.fontSize == 11,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Edge Cases & Dynamic Constraints - Whitespace-Only Strings Handling',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: PrayerHistoryPanel(origin: '   ', description: '   '),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('HISTORICAL CONTEXT'), findsOneWidget);
        expect(find.text('Origin:    '), findsOneWidget);
        expect(find.text('   '), findsOneWidget);
      },
    );

    testWidgets(
      'Edge Cases & Dynamic Constraints - Single Character Strings Handling',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: PrayerHistoryPanel(origin: 'A', description: 'B'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Origin: A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
      },
    );

    testWidgets(
      'Edge Cases & Dynamic Constraints - Long Multi-line Description',
      (WidgetTester tester) async {
        final longDescription = List.generate(
          20,
          (i) =>
              'Line $i: Detailed historical narrative of prayer origin and '
              'liturgical development.',
        ).join('\n');

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SingleChildScrollView(
                child: PrayerHistoryPanel(
                  origin: 'Historical Archive',
                  description: longDescription,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('HISTORICAL CONTEXT'), findsOneWidget);
        expect(find.text('Origin: Historical Archive'), findsOneWidget);
        expect(find.text(longDescription), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Edge Cases & Dynamic Constraints - Long Origin String Handling',
      (WidgetTester tester) async {
        const longOrigin =
            'Archdiocese of Milan, Ambrosian Rite, Fourth Century Liturgical Manuscript Collection, Codex Ambrosianus';

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: SizedBox(
                width: 250,
                child: PrayerHistoryPanel(
                  origin: longOrigin,
                  description: 'Historical context test description.',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Origin: $longOrigin'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Edge Cases & Dynamic Constraints - Multi-line Origin String Wrapping',
      (WidgetTester tester) async {
        const multiLineOrigin =
            'Archdiocese of Milan,\nAmbrosian Rite, Fourth Century,\nCodex Ambrosianus';

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: SizedBox(
                width: 200,
                child: PrayerHistoryPanel(
                  origin: multiLineOrigin,
                  description: 'Historical context test description.',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Origin: $multiLineOrigin'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Key Propagation Verification', (WidgetTester tester) async {
      const testKey = Key('prayer_history_panel_test_key');
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: PrayerHistoryPanel(
              key: testKey,
              origin: 'Origin',
              description: 'Description',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('Theme Adaptability - Light and Dark Themes', (
      WidgetTester tester,
    ) async {
      // 1. Light Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: PrayerHistoryPanel(
              origin: 'Subiaco Monastery',
              description: 'Rule of Saint Benedict, c. 516 AD.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightContext = tester.element(find.byType(PrayerHistoryPanel));
      final lightTheme = Theme.of(lightContext);

      final lightIconFinder = find.byIcon(Icons.history_edu);
      final lightIconWidget = tester.widget<Icon>(lightIconFinder);
      expect(lightIconWidget.color, equals(lightTheme.colorScheme.primary));

      final lightHeaderFinder = find.text('HISTORICAL CONTEXT');
      final lightHeaderWidget = tester.widget<Text>(lightHeaderFinder);
      expect(
        lightHeaderWidget.style?.color,
        equals(lightTheme.colorScheme.primary),
      );

      final lightOriginWidget = tester.widget<Text>(
        find.text('Origin: Subiaco Monastery'),
      );
      expect(
        lightOriginWidget.style?.color,
        equals(lightTheme.colorScheme.onSurface),
      );

      final lightDescWidget = tester.widget<Text>(
        find.text('Rule of Saint Benedict, c. 516 AD.'),
      );
      expect(
        lightDescWidget.style?.color,
        equals(lightTheme.colorScheme.onSurfaceVariant),
      );

      // 2. Dark Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(
            body: PrayerHistoryPanel(
              origin: 'Subiaco Monastery',
              description: 'Rule of Saint Benedict, c. 516 AD.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkContext = tester.element(find.byType(PrayerHistoryPanel));
      final darkTheme = Theme.of(darkContext);

      final darkIconFinder = find.byIcon(Icons.history_edu);
      final darkIconWidget = tester.widget<Icon>(darkIconFinder);
      expect(darkIconWidget.color, equals(darkTheme.colorScheme.primary));

      final darkHeaderFinder = find.text('HISTORICAL CONTEXT');
      final darkHeaderWidget = tester.widget<Text>(darkHeaderFinder);
      expect(
        darkHeaderWidget.style?.color,
        equals(darkTheme.colorScheme.primary),
      );

      final darkOriginWidget = tester.widget<Text>(
        find.text('Origin: Subiaco Monastery'),
      );
      expect(
        darkOriginWidget.style?.color,
        equals(darkTheme.colorScheme.onSurface),
      );

      final darkDescWidget = tester.widget<Text>(
        find.text('Rule of Saint Benedict, c. 516 AD.'),
      );
      expect(
        darkDescWidget.style?.color,
        equals(darkTheme.colorScheme.onSurfaceVariant),
      );
    });
  });

  group('PrayerHistoryPanel Golden Tests', () {
    testGoldens('renders PrayerHistoryPanel (Light Theme)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const Scaffold(
          body: PrayerHistoryPanel(
            origin: 'Subiaco Monastery',
            description: 'Rule of Saint Benedict, c. 516 AD.',
          ),
        ),
        wrapper: materialAppWrapper(theme: ThemeData.light(useMaterial3: true)),
        surfaceSize: const Size(400, 200),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'prayer_history_sheet_light_golden');
    });

    testGoldens('renders PrayerHistoryPanel (Dark Theme)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const Scaffold(
          body: PrayerHistoryPanel(
            origin: 'Subiaco Monastery',
            description: 'Rule of Saint Benedict, c. 516 AD.',
          ),
        ),
        wrapper: materialAppWrapper(theme: ThemeData.dark(useMaterial3: true)),
        surfaceSize: const Size(400, 200),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'prayer_history_sheet_dark_golden');
    });
  });
}
