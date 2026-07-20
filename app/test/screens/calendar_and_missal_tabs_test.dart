import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/calendar_tab.dart';
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:drift/native.dart';
import 'package:twelve_stars/logic/bible_database.dart';
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
    testGoldens('CalendarTab renders correctly', (tester) async {
      TimeHelper.setCustomTime(DateTime(2026, 7, 2));
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Calendar Tab Placeholder',
          SizedBox(
            height: 600,
            child: Scaffold(
              body: CalendarTab(initialDate: DateTime(2026, 7, 2)),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'calendar_tab_placeholder_golden');
    });

    testGoldens('MissalTab renders correctly', (tester) async {
      TimeHelper.setCustomTime(DateTime(2026, 7, 4));
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Missal Tab Placeholder',
          const SizedBox(
            height: 600,
            child: Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'missal_tab_placeholder_golden');
    });
  });

  group('CalendarTab Interactive Widget Tests', () {
    testWidgets('allows month navigation and day selection', (tester) async {
      final fixedDate = DateTime(2026, 7, 2); // Thursday in Ordinary Time
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: CalendarTab(initialDate: fixedDate)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State Check
      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
      expect(find.text('July 2026'), findsOneWidget);
      expect(find.textContaining('13th Week in Ordinary Time'), findsWidgets);

      // 2. Next Month Navigation
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();

      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Sunday, August 2, 2026'), findsOneWidget);

      // 3. Grid Cell Selection (Select Assumption of BVM - Aug 15)
      // Note: Cell text is '15'.
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

    testWidgets('Today FAB visibility and click behavior', (tester) async {
      // Initialize with today's real date to test FAB visibility
      final today = DateTime.now();

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: CalendarTab(initialDate: today)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Today is selected initially -> Today FAB should NOT be visible
      expect(find.widgetWithText(FloatingActionButton, 'Today'), findsNothing);

      // 2. Navigate away -> Today FAB should become visible
      await tester.tap(find.byTooltip('Next Day'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FloatingActionButton, 'Today'),
        findsOneWidget,
      );

      // 3. Tap Today FAB -> selection returns to today, FAB is hidden again
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Today'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FloatingActionButton, 'Today'), findsNothing);
    });

    testWidgets('Next Sunday FAB jumps to next Sunday', (tester) async {
      final fixedDate = DateTime(2026, 7, 2); // Thursday
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: CalendarTab(initialDate: fixedDate)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial date display is Thursday, July 2
      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);

      // 2. Tap Next Sunday FAB -> date should jump to Sunday, July 5
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Next Sunday'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday, July 5, 2026'), findsOneWidget);

      // 3. Tap it again -> date should jump to Sunday, July 12
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Next Sunday'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday, July 12, 2026'), findsOneWidget);
    });

    testWidgets('displays lectionary readings in correct order on Sunday', (
      tester,
    ) async {
      final fixedDate = DateTime(2026, 7, 5); // Sunday, July 5, 2026
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: CalendarTab(initialDate: fixedDate)),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the title of readings are displayed in correct order:
      // First Reading -> Responsorial Psalm -> Second Reading -> Gospel.
      final firstReadingFinder = find.text('First Reading');
      final psalmFinder = find.text('Responsorial Psalm');
      final secondReadingFinder = find.text('Second Reading');
      final gospelFinder = find.text('Gospel');

      expect(firstReadingFinder, findsOneWidget);
      expect(psalmFinder, findsOneWidget);
      expect(secondReadingFinder, findsOneWidget);
      expect(gospelFinder, findsOneWidget);

      final firstReadingY = tester.getCenter(firstReadingFinder).dy;
      final psalmY = tester.getCenter(psalmFinder).dy;
      final secondReadingY = tester.getCenter(secondReadingFinder).dy;
      final gospelY = tester.getCenter(gospelFinder).dy;

      expect(firstReadingY < psalmY, isTrue);
      expect(psalmY < secondReadingY, isTrue);
      expect(secondReadingY < gospelY, isTrue);
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

      // Verify sign of the cross and Confiteor exist
      expect(find.text('Sign of the Cross'), findsOneWidget);
      expect(find.text('Confiteor'), findsOneWidget);

      // 2. Day Navigation
      await tester.tap(find.byTooltip('Next Day'));
      await tester.pumpAndSettle();

      expect(find.text('Friday, July 3, 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Day'));
      await tester.pumpAndSettle();

      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
    });

    testWidgets('Creed toggle switches between Nicene and Apostles Creeds', (
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
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is Nicene Creed
      expect(find.text('Nicene Creed'), findsWidgets);
      expect(find.text('Symbol of Faith'), findsOneWidget); // Nicene subtitle

      // Tap on Apostles' Creed segment
      final apostlesCreedSegment = find.text('Apostles\' Creed');
      await tester.ensureVisible(apostlesCreedSegment);
      await tester.tap(apostlesCreedSegment);
      await tester.pumpAndSettle();

      // Verify Apostles' Creed subtitle
      expect(find.text('Profession of Faith'), findsOneWidget);
      expect(find.text('Symbol of Faith'), findsNothing);
    });

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
  });
}
