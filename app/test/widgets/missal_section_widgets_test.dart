import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/prayers.dart';
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

    testWidgets('MissalMassPartPlaceholder renders optional action widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissalMassPartPlaceholder(
              title: 'Communion Rite',
              description:
                  'Reception of Holy Communion and silent thanksgiving',
              icon: Icons.church,
              action: FilledButton(
                onPressed: () {},
                child: const Text('Test Action'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Communion Rite'), findsOneWidget);
      expect(find.text('Test Action'), findsOneWidget);
    });

    testWidgets(
      'MissalCommunionSectionCard renders placeholder without button when prayer is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: MissalCommunionSectionCard())),
        );

        expect(find.text('Communion Rite'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('missal_anima_christi_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'MissalCommunionSectionCard renders Anima Christi button and triggers callback on tap',
      (WidgetTester tester) async {
        final prayer = Prayer.mock(
          id: 'anima_christi',
          defaultTitle: 'Anima Christi',
          translations: const {},
        );
        bool openedModal = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MissalCommunionSectionCard(
                animaChristi: prayer,
                onOpenAnimaChristi: (context, p) {
                  openedModal = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Communion Rite'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('missal_anima_christi_button')),
          findsOneWidget,
        );
        expect(find.text('Anima Christi'), findsOneWidget);
        expect(openedModal, isFalse);

        await tester.tap(
          find.byKey(const ValueKey('missal_anima_christi_button')),
        );
        await tester.pump();

        expect(openedModal, isTrue);
      },
    );
  });
}
