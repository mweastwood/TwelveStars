import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import 'package:twelve_stars/widgets/homily_reflection_sheet.dart';
import 'package:twelve_stars/widgets/missal_creed_carousel.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
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
    ];
  });

  tearDown(() async {
    TimeHelper.setCustomTime(null);
    await testDb.close();
    PrayerDatabase.mockPrayers = null;
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
      'Creed carousel switches between Nicene and Apostles Creeds via swipe and tap',
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

        // Swipe left on the PageView to bring in Apostles' Creed
        await tester.drag(find.byType(PageView), const Offset(-600, 0));
        await tester.pumpAndSettle();

        // Verify Apostles' Creed subtitle is present
        expect(find.text('Profession of Faith'), findsOneWidget);

        // Swipe right on the PageView to navigate back
        await tester.drag(find.byType(PageView), const Offset(600, 0));
        await tester.pumpAndSettle();

        expect(find.text('Symbol of Faith'), findsOneWidget);

        // Switch via indicator chip tap
        await tester.tap(find.byKey(const Key('apostles_creed_chip')));
        await tester.pumpAndSettle();

        expect(find.text('Profession of Faith'), findsOneWidget);

        await tester.tap(find.byKey(const Key('nicene_creed_chip')));
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
