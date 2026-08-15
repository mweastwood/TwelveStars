import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
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
    'MassReadingCard loads and shows verses on separate lines using BibleVerseRow, and toggles collapse',
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

      // Should show individual verse rows on separate lines
      expect(find.byType(BibleVerseRow), findsNWidgets(2));
      expect(
        find.text('In the beginning God created heaven, and earth.'),
        findsOneWidget,
      );
      expect(find.text('And the earth was void and empty.'), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.text('First Reading'));
      await tester.pumpAndSettle();

      // Verses should be collapsed
      expect(find.byType(BibleVerseRow), findsNothing);

      // Tap header to re-expand
      await tester.tap(find.text('First Reading'));
      await tester.pumpAndSettle();

      expect(find.byType(BibleVerseRow), findsNWidgets(2));
    },
  );

  testWidgets(
    'MassReadingCard displays reverse citations and user comments badges with interactive modals',
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

      // Save a user comment for Genesis 1:1
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'My reflection on the beginning.',
          textPreview: const Value(
            'In the beginning God created heaven, and earth.',
          ),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: MassReadingCard(reading: reading)),
        ),
      );
      await tester.pumpAndSettle();

      // Check comment badge is displayed
      expect(find.byIcon(Icons.comment_rounded), findsOneWidget);

      // Tap comment badge -> opens comments modal
      await tester.tap(find.byIcon(Icons.comment_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Comments for Genesis 1:1'), findsOneWidget);
      expect(find.text('My reflection on the beginning.'), findsOneWidget);

      // Delete comment
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify comment is removed from DB
      final comments = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_1',
      );
      expect(comments.isEmpty, isTrue);
    },
  );

  testWidgets(
    'MassReadingCard supports verse selection, saving favorite, adding comment, and copying selection',
    (WidgetTester tester) async {
      // Mock Clipboard
      final List<Map<String, dynamic>> clipboardLog = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(methodCall.arguments as Map<String, dynamic>);
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {
              'text': clipboardLog.isNotEmpty ? clipboardLog.last['text'] : '',
            };
          }
          return null;
        },
      );

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

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: MassReadingCard(reading: reading)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Long press verse 1 to trigger selection
      await tester.longPress(
        find.text('In the beginning God created heaven, and earth.'),
      );
      await tester.pumpAndSettle();

      // Selection action bar should appear
      expect(find.text('Genesis 1:1'), findsOneWidget);
      expect(find.text('1 verse selected'), findsOneWidget);

      // 2. Tap verse 2 to expand selection
      await tester.tap(find.text('And the earth was void and empty.'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ReaderSelectionActionBar),
          matching: find.text('Genesis 1:1-2'),
        ),
        findsOneWidget,
      );
      expect(find.text('2 verses selected'), findsOneWidget);

      // 3. Test Copy
      await tester.tap(find.byTooltip('Copy selection'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Copied Genesis 1:1-2 to clipboard'), findsOneWidget);

      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        clipboardData?.text,
        'Genesis 1:1-2\n1 In the beginning God created heaven, and earth.\n2 And the earth was void and empty.',
      );

      // Selection cleared after copy
      expect(find.text('2 verses selected'), findsNothing);

      // 4. Select verse 1 again and save favorite
      await tester.longPress(
        find.text('In the beginning God created heaven, and earth.'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      final favorites = await testDb.getFavorites();
      expect(favorites.length, 1);
      expect(favorites.first.bookName, 'Genesis');
      expect(favorites.first.chapter, 1);
      expect(favorites.first.startVerse, 1);
      expect(favorites.first.endVerse, 1);

      // 5. Select verse 2 and add comment
      await tester.longPress(find.text('And the earth was void and empty.'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.comment_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Add Comment for Genesis 1:2'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Comment on void earth');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final comments = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_2',
      );
      expect(comments.length, 1);
      expect(comments.first.commentText, 'Comment on void earth');

      // Comment badge should be visible on verse 2
      expect(find.byIcon(Icons.comment_rounded), findsOneWidget);
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

    // Tap header to collapse
    await tester.tap(find.text('First Reading'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'mass_reading_card_collapsed_golden');
  });
}
