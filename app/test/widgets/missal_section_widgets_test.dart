import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/widgets/reader/missal_section_widgets.dart';

void main() {
  group('MissalSectionWidgets Tests', () {
    testWidgets('MissalSectionHeader renders section title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MissalSectionHeader(title: 'INTRODUCTORY RITES'),
          ),
        ),
      );

      expect(find.text('INTRODUCTORY RITES'), findsOneWidget);
    });

    testWidgets('MissalMassPartPlaceholder renders title and description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MissalMassPartPlaceholder(
              title: 'Entrance Chant',
              description: 'Entrance Antiphon of the day',
              icon: Icons.music_note,
            ),
          ),
        ),
      );

      expect(find.text('Entrance Chant'), findsOneWidget);
      expect(find.text('Entrance Antiphon of the day'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('MissalLiturgicalCard renders liturgical details', (
      WidgetTester tester,
    ) async {
      final day = LiturgicalCalendar.computeDay(DateTime(2026, 8, 15));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MissalLiturgicalCard(currentDay: day)),
        ),
      );

      expect(find.text(day.weekName), findsOneWidget);
      expect(find.text('Color: ${day.colorName}'), findsOneWidget);
    });

    testWidgets(
      'MissalFeastAlertCard renders feast title when feast is present',
      (WidgetTester tester) async {
        final day = LiturgicalCalendar.computeDay(DateTime(2026, 8, 15));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MissalFeastAlertCard(currentDay: day)),
          ),
        );

        if (day.name != null) {
          expect(find.text('SOLEMNITY / FEAST'), findsOneWidget);
          expect(find.text(day.name!), findsOneWidget);
        }
      },
    );

    testWidgets('MissalHomilySectionCard triggers callback on button tap', (
      WidgetTester tester,
    ) async {
      final day = LiturgicalCalendar.computeDay(DateTime(2026, 8, 15));
      bool openedHomily = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissalHomilySectionCard(
              currentDay: day,
              readings: const [],
              onOpenHomilyReflection: (context, currentDay, readings) {
                openedHomily = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Homily'), findsOneWidget);
      expect(find.text('Reflective instruction by the priest'), findsOneWidget);
      expect(openedHomily, isFalse);
    });
  });
}
