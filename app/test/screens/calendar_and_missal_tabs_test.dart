import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import 'package:twelve_stars/widgets/homily_reflection_sheet.dart';
import 'package:twelve_stars/widgets/anima_christi_sheet.dart';
import 'package:twelve_stars/widgets/missal_creed_carousel.dart';
import 'package:twelve_stars/widgets/reader/missal_section_widgets.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/time_helper.dart';
import '../test_helper.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() async {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    await testDb.ensurePopulated();

    PrayerDatabase.mockPrayers = [
      Prayer.mock(
        id: 'sign_of_the_cross',
        defaultTitle: 'Sign of the Cross',
        hasAmen: true,
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Sign of the Cross',
              subtitle: 'Signum Crucis',
              text:
                  'In the name of the Father, and of the Son, and of the Holy Spirit.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Signum Crucis',
              text: 'In nomine Patris, et Filii, et Spiritus Sancti.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'confiteor',
        defaultTitle: 'Confiteor',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Confiteor',
              subtitle: 'I confess to almighty God',
              text: 'I confess to almighty God...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Confiteor',
              text: 'Confiteor Deo omnipotenti...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'gloria',
        defaultTitle: 'Gloria',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Gloria',
              subtitle: 'Glory to God in the Highest',
              text: 'Glory to God in the highest...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Gloria in excelsis Deo',
              text: 'Gloria in excelsis Deo...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'nicene_creed',
        defaultTitle: 'Nicene Creed',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Nicene Creed',
              subtitle: 'Symbol of Faith',
              text: 'I believe in one God, the Father almighty...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'apostles_creed',
        defaultTitle: 'Apostles\' Creed',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Apostles\' Creed',
              subtitle: 'Profession of Faith',
              text: 'I believe in God, the Father almighty...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'our_father',
        defaultTitle: 'Our Father',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Our Father',
              subtitle: "The Lord's Prayer",
              text: 'Our Father, who art in heaven...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'mass_greeting',
        defaultTitle: 'Greeting',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Greeting',
              text:
                  'Priest: In the name of the Father...\nPeople: Amen.\n\nPriest: The Lord be with you.\nPeople: And with your spirit.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Salutatio',
              text:
                  'Sacerdos: In nomine Patris...\nPopulus: Amen.\n\nSacerdos: Dominus vobiscum.\nPopulus: Et cum spiritu tuo.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'kyrie_eleison',
        defaultTitle: 'Kyrie Eleison',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Kyrie Eleison',
              subtitle: 'Lord, Have Mercy',
              text: 'Lord, have mercy. Christ, have mercy. Lord, have mercy.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Kyrie Eleison',
              text: 'Kyrie, eleison. Christe, eleison. Kyrie, eleison.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'sanctus',
        defaultTitle: 'Sanctus',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Sanctus',
              subtitle: 'Holy, Holy, Holy',
              text: 'Holy, Holy, Holy Lord God of hosts...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Sanctus',
              text: 'Sanctus, Sanctus, Sanctus Dominus Deus Sabaoth...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'sign_of_peace',
        defaultTitle: 'Sign of Peace',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Sign of Peace',
              text:
                  'Priest: The peace of the Lord be with you always.\nPeople: And with your spirit.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Pax Domini',
              text:
                  'Sacerdos: Pax Domini sit semper vobiscum.\nPopulus: Et cum spiritu tuo.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'agnus_dei',
        defaultTitle: 'Agnus Dei',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Agnus Dei',
              subtitle: 'Lamb of God',
              text: 'Lamb of God, you take away the sins of the world...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Agnus Dei',
              text: 'Agnus Dei, qui tollis peccata mundi...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'dismissal',
        defaultTitle: 'Blessing & Dismissal',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Concluding Blessing & Dismissal',
              text: 'Go forth, the Mass is ended.\nPeople: Thanks be to God.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Benedictio et Dismissio',
              text: 'Ite, missa est.\nPopulus: Deo gratias.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'anima_christi',
        defaultTitle: 'Anima Christi',
        category: 'devotion',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Anima Christi',
              subtitle: 'Soul of Christ',
              text:
                  'Soul of Christ, sanctify me. Body of Christ, save me. Blood of Christ, inebriate me.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Anima Christi',
              subtitle: 'Corpus Christi',
              text:
                  'Anima Christi, sanctifica me. Corpus Christi, salva me. Sanguis Christi, inebria me.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
    ];

    SaintDatabase.mockSaints = [
      const Saint(
        id: 'thomas-aquinas',
        name: 'St. Thomas Aquinas',
        birthDate: '1225',
        deathDate: '1274',
        nationality: 'Italian',
        profession: 'Dominican Friar & Theologian',
        isDoctor: true,
        feastDay: 'January 28',
        patronage: 'Students, Academics, Theologians',
        summary: 'Angelic Doctor of the Church, author of Summa Theologiae.',
      ),
      const Saint(
        id: 'francis-of-assisi',
        name: 'St. Francis of Assisi',
        birthDate: '1181',
        deathDate: '1226',
        nationality: 'Italian',
        profession: 'Friar Minor & Founder',
        isDoctor: false,
        feastDay: 'October 4',
        patronage: 'Animals, Ecology, Peace',
        summary: 'Founder of Franciscan Orders, received the stigmata.',
      ),
    ];
  });

  tearDown(() async {
    TimeHelper.setCustomTime(null);
    await testDb.close();
    PrayerDatabase.mockPrayers = null;
    SaintDatabase.mockSaints = null;
  });

  group('Placeholder Tabs Golden Tests', () {
    testGoldens('MissalTab renders correctly collapsed and expanded', (
      tester,
    ) async {
      TimeHelper.setCustomTime(DateTime(2026, 7, 4));
      await tester.pumpWidgetBuilder(
        const SizedBox(
          height: 800,
          child: Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'missal_tab_placeholder_golden');

      // Tap title to expand month calendar
      await tester.tap(find.text('Saturday, July 4, 2026'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'missal_tab_expanded_month_golden');
    });
  });

  group('MissalTab Month Grid & Interactive Tests', () {
    testWidgets('toggles calendar expansion by tapping date title', (
      tester,
    ) async {
      final fixedDate = DateTime(2026, 7, 2);
      TimeHelper.setCustomTime(fixedDate);
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              initialDate: fixedDate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default: Collapsed Week View
      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
      expect(find.text('July 2026'), findsNothing);

      // Tap title -> Expand Month View
      await tester.tap(find.text('Thursday, July 2, 2026'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
      expect(find.text('Thursday, July 2, 2026'), findsNothing);

      // Tap title again -> Collapse Week View
      await tester.tap(find.text('July 2026'));
      await tester.pumpAndSettle();

      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
      expect(find.text('July 2026'), findsNothing);
    });

    testWidgets('allows month navigation and day selection on grid', (
      tester,
    ) async {
      final fixedDate = DateTime(2026, 7, 2); // Thursday in Ordinary Time
      TimeHelper.setCustomTime(fixedDate);
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              initialDate: fixedDate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State Check
      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
      expect(find.textContaining('13th Week in Ordinary Time'), findsWidgets);

      // Expand Calendar to access Month Grid by tapping date title
      await tester.tap(find.text('Thursday, July 2, 2026'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);

      // 2. Next Month Navigation
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();

      expect(find.text('August 2026'), findsOneWidget);

      // 3. Grid Cell Selection (Select Assumption of BVM - Aug 15)
      final cell15 = find.widgetWithText(InkWell, '15');
      expect(cell15, findsOneWidget);
      await tester.tap(cell15);
      await tester.pumpAndSettle();

      expect(find.text('Saturday, August 15, 2026'), findsOneWidget);
      expect(
        find.text('The Assumption of the Blessed Virgin Mary'),
        findsOneWidget,
      );
    });
  });

  group('MissalTab Interactive Widget Tests', () {
    testWidgets('allows day navigation and displays prayers/readings', (
      tester,
    ) async {
      final fixedDate = DateTime(2026, 7, 2); // Thursday
      TimeHelper.setCustomTime(fixedDate);
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State Check
      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
      expect(find.text('Mass Missal'), findsOneWidget);
      expect(find.text('INTRODUCTORY RITES'), findsOneWidget);
      expect(find.text('LITURGY OF THE WORD'), findsOneWidget);
      expect(find.text('LITURGY OF THE EUCHARIST'), findsOneWidget);

      // Verify greeting and Confiteor exist, standalone Sign of the Cross is not present
      expect(find.text('Greeting'), findsOneWidget);
      expect(find.text('Sign of the Cross'), findsNothing);
      expect(find.text('Confiteor'), findsWidgets);

      // 2. Day Navigation
      await tester.tap(find.byTooltip('Next Day'));
      await tester.pumpAndSettle();

      expect(find.text('Friday, July 3, 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Day'));
      await tester.pumpAndSettle();

      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
    });

    testWidgets(
      'Creed carousel switches between Nicene and Apostles Creeds via swipe and tap on peeking card',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 2);
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Default is Nicene Creed
        expect(find.text('Nicene Creed'), findsWidgets);
        expect(find.text('Symbol of Faith'), findsOneWidget); // Nicene subtitle

        // Scroll down to center the carousel in viewport
        await tester.ensureVisible(find.byType(MissalCreedCarousel));
        await tester.pumpAndSettle();

        // Swipe left on the MissalCreedCarousel to bring in Apostles' Creed
        await tester.drag(
          find.byType(MissalCreedCarousel),
          const Offset(-600, 0),
        );
        await tester.pumpAndSettle();

        // Verify Apostles' Creed subtitle is present
        expect(find.text('Profession of Faith'), findsOneWidget);

        // Swipe right on the MissalCreedCarousel to navigate back
        await tester.drag(
          find.byType(MissalCreedCarousel),
          const Offset(600, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Symbol of Faith'), findsOneWidget);

        // Switch via tapping peeking Apostles' Creed card
        await tester.tap(find.byKey(const Key('apostles_creed_peeking_tap')));
        await tester.pumpAndSettle();

        expect(find.text('Profession of Faith'), findsOneWidget);

        // Switch back via tapping peeking Nicene Creed card
        await tester.tap(find.byKey(const Key('nicene_creed_peeking_tap')));
        await tester.pumpAndSettle();

        expect(find.text('Symbol of Faith'), findsOneWidget);
      },
    );

    testWidgets('Today FAB visibility and click behavior', (tester) async {
      final fixedDate = DateTime(2026, 7, 2);
      TimeHelper.setCustomTime(fixedDate);
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Since initial date is today, Today FAB should NOT be visible
      expect(find.widgetWithText(FloatingActionButton, 'Today'), findsNothing);

      // Navigate away
      await tester.tap(find.byTooltip('Next Day'));
      await tester.pumpAndSettle();

      // Today FAB should be visible now
      expect(
        find.widgetWithText(FloatingActionButton, 'Today'),
        findsOneWidget,
      );

      // Tap it to return
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Today'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FloatingActionButton, 'Today'), findsNothing);
    });

    testWidgets('Next Sunday FAB jumps to next Sunday', (tester) async {
      final fixedDate = DateTime(2026, 7, 2); // Thursday
      TimeHelper.setCustomTime(fixedDate);
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Next Sunday FAB -> date should jump to Sunday, July 5
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Next Sunday'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday, July 5, 2026'), findsOneWidget);
    });

    testWidgets(
      'MissalTab readings do not reset to loading spinner on parent rebuild',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 2);
        TimeHelper.setCustomTime(fixedDate);

        bool stateFlag = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildTestableWidget(
                child: Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => stateFlag = !stateFlag),
                        child: Text('Rebuild Parent: $stateFlag'),
                      ),
                      Expanded(
                        child: MissalTab(
                          primaryLanguage: PrayerLanguage.english,
                          compareLanguage: PrayerLanguage.latin,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('LITURGY OF THE WORD'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Trigger parent rebuild (simulating translation selector toggle)
        await tester.tap(find.textContaining('Rebuild Parent'));
        await tester.pump(); // Single frame pump

        // Verify that FutureBuilder did NOT reset to CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('LITURGY OF THE WORD'), findsOneWidget);
      },
    );

    testWidgets(
      'MassReadingCard uses BibleVerseRow to inherit ambient font size and text scaling',
      (tester) async {
        final sampleReading = LectionaryReading(
          id: 1,
          readingKey: '2026-07-02',
          readingType: 'first',
          citation: 'Gen 1:1-5',
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          verseRange: '1-5',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MassReadingCard(reading: sampleReading, fontSize: 22.0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final verseRow = tester.widget<BibleVerseRow>(
          find.byType(BibleVerseRow).first,
        );
        expect(verseRow.fontSize, equals(22.0));
      },
    );

    test(
      'verifies BibleDatabase getReadings for Christ the King Solemnity across cycles',
      () async {
        // Year A (2026-11-22)
        final dayA = LiturgicalCalendar.computeDay(DateTime(2026, 11, 22));
        expect(dayA.lectionaryKey, 'season_ordinary_time_34_sunday_a');
        final readingsA = await BibleDatabaseHelper.db.getReadings(
          dayA.lectionaryKey,
        );
        expect(readingsA, isNotEmpty);
        expect(readingsA.length, equals(4)); // First, Psalm, Second, Gospel

        // Year B (2024-11-24)
        final dayB = LiturgicalCalendar.computeDay(DateTime(2024, 11, 24));
        expect(dayB.lectionaryKey, 'season_ordinary_time_34_sunday_b');
        final readingsB = await BibleDatabaseHelper.db.getReadings(
          dayB.lectionaryKey,
        );
        expect(readingsB, isNotEmpty);
        expect(readingsB.length, equals(4));

        // Year C (2025-11-23)
        final dayC = LiturgicalCalendar.computeDay(DateTime(2025, 11, 23));
        expect(dayC.lectionaryKey, 'season_ordinary_time_34_sunday_c');
        final readingsC = await BibleDatabaseHelper.db.getReadings(
          dayC.lectionaryKey,
        );
        expect(readingsC, isNotEmpty);
        expect(readingsC.length, equals(4));
      },
    );

    testWidgets(
      'MissalTab renders Christ the King readings correctly without showing no readings seeded',
      (tester) async {
        TimeHelper.setCustomTime(
          DateTime(2024, 11, 24),
        ); // Christ the King Year B
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No readings seeded for this date.'), findsNothing);
        expect(find.text('LITURGY OF THE WORD'), findsOneWidget);
        expect(find.text('First Reading'), findsOneWidget);
        expect(find.text('Responsorial Psalm'), findsOneWidget);
        expect(find.text('Second Reading'), findsOneWidget);
        expect(find.text('Gospel'), findsOneWidget);
      },
    );

    testWidgets(
      'MissalTab renders Homily section with AI Reflection button and opens sheet when tapped',
      (tester) async {
        LocalAgentHelper.instance = MockMissalAiService();
        TimeHelper.setCustomTime(DateTime(2024, 11, 24));
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Homily'), findsOneWidget);
        expect(find.text('AI Reflection'), findsOneWidget);

        await tester.ensureVisible(find.text('AI Reflection'));
        await tester.tap(find.text('AI Reflection'));
        await tester.pump();
        await tester.pump();

        expect(find.byType(HomilyReflectionSheet), findsOneWidget);
        expect(find.text('Homily Reflection'), findsOneWidget);
      },
    );

    testGoldens(
      'MissalTab renders Homily section with AI Reflection button and opens modal sheet',
      (tester) async {
        LocalAgentHelper.instance = MockMissalAiService();
        TimeHelper.setCustomTime(DateTime(2024, 11, 24));
        await tester.pumpWidgetBuilder(
          const Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('AI Reflection'));
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'missal_tab_homily_section_golden',
          customPump: (tester) async => await tester.pump(),
        );

        await tester.tap(find.text('AI Reflection'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        await screenMatchesGolden(
          tester,
          'missal_tab_homily_reflection_modal_golden',
          customPump: (tester) async => await tester.pump(),
        );
      },
    );

    testGoldens(
      'MissalTab renders Creed section with Apostles Creed active and Nicene Creed peeking',
      (tester) async {
        LocalAgentHelper.instance = MockMissalAiService();
        TimeHelper.setCustomTime(DateTime(2024, 11, 24));
        await tester.pumpWidgetBuilder(
          const Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        // Scroll down to the Creed carousel
        await tester.ensureVisible(find.byType(MissalCreedCarousel));
        await tester.pumpAndSettle();

        // Tap peeking Apostles Creed card to focus it
        await tester.tap(find.byKey(const Key('apostles_creed_peeking_tap')));
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'missal_tab_apostles_creed_golden',
          customPump: (tester) async => await tester.pump(),
        );
      },
    );

    testWidgets(
      'displays saint feast card when date has a saint feast and tapping opens saint details modal',
      (tester) async {
        final fixedDate = DateTime(2026, 1, 28); // St. Thomas Aquinas feast day
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
                initialDate: fixedDate,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check header and date
        expect(find.text('Wednesday, January 28, 2026'), findsOneWidget);

        // Check saint feast card is rendered
        expect(find.byType(MissalSaintFeastCard), findsOneWidget);
        expect(
          find.byKey(const Key('missal_saint_card_thomas-aquinas')),
          findsOneWidget,
        );
        expect(find.text('SAINT MEMORIAL / FEAST'), findsOneWidget);
        expect(find.text('St. Thomas Aquinas (1225 – 1274)'), findsOneWidget);
        expect(
          find.text('Italian • Dominican Friar & Theologian'),
          findsOneWidget,
        );
        expect(
          find.text('Patron of Students, Academics, Theologians'),
          findsOneWidget,
        );
        expect(find.text('Doctor'), findsOneWidget);

        // Tap the card to open the bottom sheet
        await tester.tap(
          find.byKey(const Key('missal_saint_card_thomas-aquinas')),
        );
        await tester.pumpAndSettle();

        // Verify saint details bottom sheet
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        expect(find.text('January 28'), findsOneWidget);
        expect(find.text('Biography & Significance'), findsOneWidget);
        expect(
          find.text(
            'Angelic Doctor of the Church, author of Summa Theologiae.',
          ),
          findsWidgets,
        );
      },
    );

    testWidgets('calendar grid renders star markers on saint feast days', (
      tester,
    ) async {
      final fixedDate = DateTime(2026, 1, 28);
      TimeHelper.setCustomTime(fixedDate);
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              initialDate: fixedDate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The day cell for 28th should have a star indicator icon
      final cell28 = find.widgetWithText(InkWell, '28').first;
      expect(
        find.descendant(of: cell28, matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );
    });

    testGoldens(
      'MissalTab renders saint feast card and opens saint details modal',
      (tester) async {
        final fixedDate = DateTime(2026, 1, 28);
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: MissalTab(
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              initialDate: fixedDate,
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'missal_tab_saint_feast_card_golden',
          customPump: (tester) async => await tester.pump(),
        );

        // Tap the saint feast card to open the details modal
        await tester.tap(
          find.byKey(const Key('missal_saint_card_thomas-aquinas')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        await screenMatchesGolden(
          tester,
          'missal_tab_saint_details_modal_golden',
          customPump: (tester) async => await tester.pump(),
        );
      },
    );

    testWidgets(
      'filter chips bar renders above introductory rites with all options',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 4);
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check Readings Only chip is present and unselected by default
        expect(
          find.byKey(const ValueKey('missal_filter_readings_only')),
          findsOneWidget,
        );
        final readingsOnlyChip = tester.widget<FilterChip>(
          find.byKey(const ValueKey('missal_filter_readings_only')),
        );
        expect(readingsOnlyChip.selected, isFalse);

        // Check prayer filter chips are present and selected by default
        expect(
          find.byKey(const ValueKey('missal_filter_mass_greeting')),
          findsOneWidget,
        );
        final massGreetingChip = tester.widget<FilterChip>(
          find.byKey(const ValueKey('missal_filter_mass_greeting')),
        );
        expect(massGreetingChip.selected, isTrue);

        expect(
          find.byKey(const ValueKey('missal_filter_confiteor')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('missal_filter_kyrie_eleison')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('missal_filter_gloria')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'toggling Readings Only chip hides prayers and keeps readings visible',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 4);
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially, INTRODUCTORY RITES and LITURGY OF THE WORD are present
        expect(find.text('INTRODUCTORY RITES'), findsOneWidget);
        expect(find.text('LITURGY OF THE WORD'), findsOneWidget);

        // Tap "Readings Only" chip
        await tester.tap(
          find.byKey(const ValueKey('missal_filter_readings_only')),
        );
        await tester.pumpAndSettle();

        // Now INTRODUCTORY RITES should be hidden, LITURGY OF THE WORD remains visible
        expect(find.text('INTRODUCTORY RITES'), findsNothing);
        expect(find.text('LITURGY OF THE WORD'), findsOneWidget);
        expect(find.text('LITURGY OF THE EUCHARIST'), findsNothing);
        expect(find.text('CONCLUDING RITES'), findsNothing);

        // Toggle "Readings Only" chip off again
        await tester.tap(
          find.byKey(const ValueKey('missal_filter_readings_only')),
        );
        await tester.pumpAndSettle();

        // INTRODUCTORY RITES is restored
        expect(find.text('INTRODUCTORY RITES'), findsOneWidget);
      },
    );

    testWidgets(
      'toggling individual prayer chips hides and reveals corresponding prayers',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 4);
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ensure Mass Greeting prayer chip is selected
        expect(
          find.byKey(const ValueKey('missal_filter_mass_greeting')),
          findsOneWidget,
        );

        // Tap Mass Greeting chip to unselect / hide it
        await tester.tap(
          find.byKey(const ValueKey('missal_filter_mass_greeting')),
        );
        await tester.pumpAndSettle();

        final updatedGreetingChip = tester.widget<FilterChip>(
          find.byKey(const ValueKey('missal_filter_mass_greeting')),
        );
        expect(updatedGreetingChip.selected, isFalse);

        // Tap Mass Greeting chip again to re-enable
        await tester.tap(
          find.byKey(const ValueKey('missal_filter_mass_greeting')),
        );
        await tester.pumpAndSettle();

        final reEnabledGreetingChip = tester.widget<FilterChip>(
          find.byKey(const ValueKey('missal_filter_mass_greeting')),
        );
        expect(reEnabledGreetingChip.selected, isTrue);
      },
    );

    testWidgets(
      'filter chip preferences persist and restore across MissalTab reloads',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 4);
        TimeHelper.setCustomTime(fixedDate);
        PrayerDatabase.mockSettings = UserSettings();

        // 1. Initial render and toggle preferences
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle Confiteor off
        await tester.tap(find.byKey(const ValueKey('missal_filter_confiteor')));
        await tester.pumpAndSettle();

        // Verify settings in mock settings
        expect(
          PrayerDatabase.mockSettings?.missalHiddenPrayers,
          contains('confiteor'),
        );

        // 2. Re-instantiate / reload MissalTab
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Confiteor chip should still be unselected
        final reloadedConfiteorChip = tester.widget<FilterChip>(
          find.byKey(const ValueKey('missal_filter_confiteor')),
        );
        expect(reloadedConfiteorChip.selected, isFalse);
      },
    );

    testWidgets(
      'MissalTab renders Communion Rite section with Anima Christi button and tapping opens modal sheet',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 4);
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to Communion Rite
        await tester.ensureVisible(
          find.byKey(const ValueKey('missal_anima_christi_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Communion Rite'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('missal_anima_christi_button')),
          findsOneWidget,
        );
        expect(find.text('Anima Christi'), findsOneWidget);

        // Tap the Anima Christi button to open the modal bottom sheet
        await tester.tap(
          find.byKey(const ValueKey('missal_anima_christi_button')),
        );
        await tester.pumpAndSettle();

        // Verify the Anima Christi bottom sheet opened
        expect(find.byType(AnimaChristiSheet), findsOneWidget);
        expect(find.text('Thanksgiving after Communion'), findsOneWidget);
        expect(
          find.textContaining('Soul of Christ, sanctify me.'),
          findsOneWidget,
        );
        // Dual language display
        expect(
          find.textContaining('Anima Christi, sanctifica me.'),
          findsOneWidget,
        );

        // Close the modal
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(AnimaChristiSheet), findsNothing);
        expect(find.text('Communion Rite'), findsOneWidget);
      },
    );

    testWidgets(
      'MissalTab Anima Christi button is hidden when Readings Only filter is active',
      (tester) async {
        final fixedDate = DateTime(2026, 7, 4);
        TimeHelper.setCustomTime(fixedDate);
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ensure visible initially
        expect(
          find.byKey(const ValueKey('missal_anima_christi_button')),
          findsOneWidget,
        );

        // Toggle Readings Only filter chip
        await tester.tap(
          find.byKey(const ValueKey('missal_filter_readings_only')),
        );
        await tester.pumpAndSettle();

        // Liturgy of Eucharist & Anima Christi button should not be present
        expect(
          find.byKey(const ValueKey('missal_anima_christi_button')),
          findsNothing,
        );
      },
    );
  });
}

class MockMissalAiService implements AiService {
  @override
  Future<AiCoreStatus> checkStatus() async => AiCoreStatus.available;
  @override
  Future<void> triggerDownload() async {}
  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {}
  @override
  Future<int> countTokens({required String prompt, dynamic imageBytes}) async =>
      100;
  @override
  Future<String?> generateContent({
    required String prompt,
    dynamic imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async => 'Mock homily reflection';
  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    dynamic imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async => AiResponse(text: 'Mock homily reflection', isTruncated: false);
}
