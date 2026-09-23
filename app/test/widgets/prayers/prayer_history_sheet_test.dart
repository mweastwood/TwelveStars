import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/prayers/prayer_history_sheet.dart';

void main() {
  group('PrayerHistoryPanel Widget Tests', () {
    testWidgets('Header & Iconography Verification', (
      WidgetTester tester,
    ) async {
      const testOrigin = '4th Century Latin Mass';
      const testDescription = 'Attributed to Saint Ambrose of Milan.';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: PrayerHistoryPanel(
              origin: testOrigin,
              description: testDescription,
            ),
          ),
        ),
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
        MaterialApp(
          home: const Scaffold(
            body: PrayerHistoryPanel(
              origin: testOrigin,
              description: testDescription,
            ),
          ),
        ),
      );

      // Verify formatted origin string
      final originFinder = find.text('Origin: $testOrigin');
      expect(originFinder, findsOneWidget);

      final Text originTextWidget = tester.widget<Text>(originFinder);
      expect(originTextWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(originTextWidget.style?.fontSize, equals(12));

      // Verify full historical context description string
      final descriptionFinder = find.text(testDescription);
      expect(descriptionFinder, findsOneWidget);

      final Text descriptionTextWidget = tester.widget<Text>(
        descriptionFinder,
      );
      expect(descriptionTextWidget.style?.fontSize, equals(11));
      expect(descriptionTextWidget.style?.height, equals(1.3));
    });

    testWidgets(
      'Edge Cases & Dynamic Constraints - Empty & Single Character Strings',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PrayerHistoryPanel(origin: '', description: ''),
            ),
          ),
        );

        expect(find.text('HISTORICAL CONTEXT'), findsOneWidget);
        expect(find.text('Origin: '), findsOneWidget);
        expect(find.text(''), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PrayerHistoryPanel(origin: 'A', description: 'B'),
            ),
          ),
        );

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
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PrayerHistoryPanel(
                  origin: 'Historical Archive',
                  description: longDescription,
                ),
              ),
            ),
          ),
        );

        expect(find.text('HISTORICAL CONTEXT'), findsOneWidget);
        expect(find.text('Origin: Historical Archive'), findsOneWidget);
        expect(find.text(longDescription), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

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

      final lightContext = tester.element(find.byType(PrayerHistoryPanel));
      final lightTheme = Theme.of(lightContext);

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

      final darkContext = tester.element(find.byType(PrayerHistoryPanel));
      final darkTheme = Theme.of(darkContext);

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
}
