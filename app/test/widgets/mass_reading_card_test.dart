import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import '../test_helper.dart';

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

  testWidgets('MassReadingCard loads and shows verses when expanded', (
    WidgetTester tester,
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

    // Should not show verses initially
    expect(
      find.textContaining('In the beginning', findRichText: true),
      findsNothing,
    );

    // Tap to expand
    await tester.tap(find.byType(MassReadingCard));
    await tester.pump(); // Start load
    await tester.pumpAndSettle(); // Wait for all async actions to finish

    // Should show verses
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
  });
}
