import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/saint_models.dart';
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
          final card = tester.widget<Card>(find.byType(Card));
          expect(card.color, isNull);
        }
      },
    );

    testWidgets(
      'MissalHomilySectionCard renders Homily placeholder without AI Reflection button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: MissalHomilySectionCard())),
        );

        expect(find.text('Homily'), findsOneWidget);
        expect(
          find.text('Reflective instruction by the priest'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.hearing), findsOneWidget);
        expect(find.text('AI Reflection'), findsNothing);
      },
    );

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

    testWidgets(
      'MissalSaintFeastCard renders crisp pixel-art SaintSpriteAvatar for bundled saint',
      (WidgetTester tester) async {
        const saint = Saint(
          id: 'john-berchmans',
          name: 'St. John Berchmans',
          birthDate: '1599',
          deathDate: '1621',
          nationality: 'Flemish / Belgian',
          profession: 'Jesuit Scholastic',
          categories: [SaintCategory.brother],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: MissalSaintFeastCard(saint: saint)),
          ),
        );
        await tester.pumpAndSettle();

        final avatarFinder = find.byKey(
          const Key('saint_sprite_avatar_john-berchmans'),
        );
        expect(avatarFinder, findsOneWidget);

        final imageFinder = find.descendant(
          of: avatarFinder,
          matching: find.byType(Image),
        );
        expect(imageFinder, findsOneWidget);

        final image = tester.widget<Image>(imageFinder);
        expect(image.filterQuality, FilterQuality.none);
        expect(image.isAntiAlias, isFalse);
        expect(
          (image.image as AssetImage).assetName,
          'assets/saints/john-berchmans.png',
        );
      },
    );

    testWidgets(
      'MissalSaintFeastCard renders Mary primary Marian sprite, Blessed label, onTap, and handles narrow scaled text',
      (WidgetTester tester) async {
        const mary = Saint(
          id: 'mary-mother-of-god',
          name: 'Blessed Virgin Mary (Our Lady)',
          nationality: 'Judean / Heavenly',
          profession: 'Mother of God (Theotokos)',
          categories: [SaintCategory.holyFamily],
          isDoctor: true,
          isBlessed: true,
        );
        bool tapped = false;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: MissalSaintFeastCard(
                  saint: mary,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final avatarFinder = find.byKey(
          const Key('saint_sprite_avatar_mary-mother-of-god'),
        );
        expect(avatarFinder, findsOneWidget);
        final image = tester.widget<Image>(
          find.descendant(of: avatarFinder, matching: find.byType(Image)),
        );
        expect(
          (image.image as AssetImage).assetName,
          'assets/saints/our-lady-of-grace.png',
        );
        expect(find.text('MEMORIAL / BLESSED'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(
          find.byKey(const Key('missal_saint_card_mary-mother-of-god')),
        );
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'MissalSaintFeastCard falls back to category icon when sprite asset is missing',
      (WidgetTester tester) async {
        const syntheticSaint = Saint(
          id: 'synthetic-feast-saint',
          name: 'St. Synthetic',
          nationality: 'Roman',
          profession: 'Martyr',
          categories: [SaintCategory.martyr],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: MissalSaintFeastCard(saint: syntheticSaint)),
          ),
        );
        await tester.pumpAndSettle();

        final avatarFinder = find.byKey(
          const Key('saint_sprite_avatar_synthetic-feast-saint'),
        );
        expect(avatarFinder, findsOneWidget);
        expect(
          find.descendant(
            of: avatarFinder,
            matching: find.byIcon(Icons.local_fire_department_rounded),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
