import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:drift/native.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import '../test_helper.dart' hide materialAppWrapper;

void main() {
  late BibleDatabase testDb;

  setUp(() async {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;

    // Reset mocks to ensure we load from db
    PrayerDatabase.mockPrayers = null;
    PrayerDatabase.mockSettings = null;

    // Save default settings
    await testDb.saveUserSettings(
      UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'none',
      ),
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('MassReadingCard displays reading header, icon, and citation', (
    WidgetTester tester,
  ) async {
    const reading = LectionaryReading(
      id: 1,
      readingKey: 'feast_annunciation',
      readingType: 'gospel',
      bookNumber: 42, // Luke
      bookName: 'Luke',
      chapter: 1,
      verseRange: '26-38',
      citation: 'Luke 1:26-38',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: const Scaffold(body: MassReadingCard(reading: reading)),
      ),
    );

    expect(find.text('Gospel'), findsOneWidget);
    expect(find.text('Luke 1:26-38'), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
  });

  testWidgets(
    'MassReadingCard loads and shows verses expanded by default, and toggles collapse',
    (WidgetTester tester) async {
      const reading = LectionaryReading(
        id: 1,
        readingKey: 'feast_annunciation',
        readingType: 'first',
        bookNumber: 1, // Genesis
        bookName: 'Genesis',
        chapter: 1,
        verseRange: '1-2',
        citation: 'Genesis 1:1-2',
      );

      // Mock verses in db
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 1,
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created heaven, and earth.',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 2,
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 2,
              verseText: 'And the earth was void and empty.',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: MassReadingCard(reading: reading)),
        ),
      );
      await tester.pumpAndSettle();

      // Should show verses expanded by default
      expect(
        find.textContaining(
          'In the beginning God created heaven, and earth.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'And the earth was void and empty.',
          findRichText: true,
        ),
        findsOneWidget,
      );

      // Tap to collapse
      await tester.tap(find.byType(MassReadingCard));
      await tester.pumpAndSettle();

      // Verses should be collapsed
      expect(
        find.textContaining('In the beginning', findRichText: true),
        findsNothing,
      );
    },
  );

  testGoldens('MassReadingCard renders correctly expanded and collapsed', (
    tester,
  ) async {
    const reading = LectionaryReading(
      id: 1,
      readingKey: 'feast_annunciation',
      readingType: 'first',
      bookNumber: 1, // Genesis
      bookName: 'Genesis',
      chapter: 1,
      verseRange: '1-2',
      citation: 'Genesis 1:1-2',
    );

    await testDb
        .into(testDb.bibleVerses)
        .insert(
          const BibleVerse(
            id: 1,
            bookNumber: 1,
            bookName: 'Genesis',
            chapter: 1,
            verseNumber: 1,
            verseText: 'In the beginning God created heaven, and earth.',
            translationCode: 'CPDV',
          ),
        );
    await testDb
        .into(testDb.bibleVerses)
        .insert(
          const BibleVerse(
            id: 2,
            bookNumber: 1,
            bookName: 'Genesis',
            chapter: 1,
            verseNumber: 2,
            verseText: 'And the earth was void and empty.',
            translationCode: 'CPDV',
          ),
        );

    final builder = GoldenBuilder.column()
      ..addScenario(
        'Mass Reading Card Expanded (Default)',
        const MassReadingCard(reading: reading),
      );

    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(),
      surfaceSize: const Size(450, 300),
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'mass_reading_card_expanded_golden');

    // Tap to collapse
    await tester.tap(find.byType(MassReadingCard));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'mass_reading_card_collapsed_golden');
  });
}
