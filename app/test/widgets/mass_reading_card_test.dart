import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
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

      // Confirm deletion
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
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
    'MassReadingCard displays favorite star badge and allows removing via favorites modal',
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

      // Save a favorite for Genesis 1:1
      await testDb.saveFavorite(
        FavoritePassagesCompanion.insert(
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          textPreview: 'In the beginning God created heaven, and earth.',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: MassReadingCard(reading: reading)),
        ),
      );
      await tester.pumpAndSettle();

      // Check star badge is displayed
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // Tap star badge -> opens favorites modal
      await tester.tap(find.byIcon(Icons.star_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Favorite Passage for Genesis 1:1'), findsOneWidget);
      expect(
        find.text('In the beginning God created heaven, and earth.'),
        findsNWidgets(2),
      );

      // Delete favorite
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm removal
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();

      // Verify favorite is removed from DB
      final favs = await testDb.getFavorites();
      expect(favs.isEmpty, isTrue);

      // Star badge should now be gone from verse row
      expect(find.byIcon(Icons.star_rounded), findsNothing);
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
      surfaceSize: const Size(450, 420),
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'mass_reading_card_expanded_golden');

    // Tap header to collapse
    await tester.tap(find.text('First Reading'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'mass_reading_card_collapsed_golden');
  });

  testGoldens(
    'MassReadingCard renders Gospel reading correctly expanded and collapsed',
    (tester) async {
      const reading = LectionaryReading(
        id: 4,
        readingKey: 'feast_annunciation',
        readingType: 'gospel',
        bookNumber: 51, // Luke
        bookName: 'Luke',
        chapter: 1,
        verseRange: '26-27',
        citation: 'Luke 1:26-27',
      );

      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 1,
              bookNumber: 51,
              bookName: 'Luke',
              chapter: 1,
              verseNumber: 26,
              verseText:
                  'And in the sixth month, the angel Gabriel was sent from God into a city of Galilee, called Nazareth,',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 2,
              bookNumber: 51,
              bookName: 'Luke',
              chapter: 1,
              verseNumber: 27,
              verseText:
                  'To a virgin espoused to a man whose name was Joseph, of the house of David; and the virgin\'s name was Mary.',
              translationCode: 'CPDV',
            ),
          );

      final builder = GoldenBuilder.column()
        ..addScenario(
          'Mass Reading Card Gospel Expanded (Default)',
          const MassReadingCard(reading: reading),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 680),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'mass_reading_card_gospel_expanded_golden',
      );

      // Tap header to collapse
      await tester.tap(find.text('Gospel'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'mass_reading_card_gospel_collapsed_golden',
      );
    },
  );

  testGoldens('BibleVerseRow renders all visual states correctly', (
    tester,
  ) async {
    final builder = GoldenBuilder.column()
      ..addScenario(
        'Default Verse',
        const BibleVerseRow(
          verseNumber: 1,
          verseText: 'In the beginning God created heaven, and earth.',
        ),
      )
      ..addScenario(
        'Selected Verse',
        const BibleVerseRow(
          verseNumber: 2,
          verseText: 'And the earth was void and empty.',
          isSelected: true,
        ),
      )
      ..addScenario(
        'Verse with Favorite Badge',
        const BibleVerseRow(
          verseNumber: 3,
          verseText: 'And God said: Be light made. And light was made.',
          isFavorite: true,
        ),
      )
      ..addScenario(
        'Verse with References Badge',
        const BibleVerseRow(
          verseNumber: 4,
          verseText: 'And God saw the light that it was good.',
          citationsCount: 3,
        ),
      )
      ..addScenario(
        'Verse with Comments Badge',
        const BibleVerseRow(
          verseNumber: 5,
          verseText: 'And he called the light Day, and the darkness Night.',
          commentsCount: 1,
        ),
      )
      ..addScenario(
        'Verse with All Badges (Favorite, References, Comments)',
        const BibleVerseRow(
          verseNumber: 6,
          verseText:
              'And there was evening and morning that made the first day.',
          isFavorite: true,
          citationsCount: 2,
          commentsCount: 2,
        ),
      )
      ..addScenario(
        'Parallel Translation Comparison',
        const BibleVerseRow(
          verseNumber: 7,
          verseText:
              'And God said: Let there be a firmament made amidst the waters.',
          compareVerseText:
              'Dixit quoque Deus: Fiat firmamentum in medio aquarum.',
        ),
      );

    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(),
      surfaceSize: const Size(500, 800),
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'bible_verse_row_scenarios_golden');
  });

  testGoldens(
    'BibleVerseRow renders all visual states correctly on widescreen',
    (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Default Verse',
          const BibleVerseRow(
            verseNumber: 1,
            verseText: 'In the beginning God created heaven, and earth.',
          ),
        )
        ..addScenario(
          'Selected Verse',
          const BibleVerseRow(
            verseNumber: 2,
            verseText: 'And the earth was void and empty.',
            isSelected: true,
          ),
        )
        ..addScenario(
          'Verse with Favorite Badge',
          const BibleVerseRow(
            verseNumber: 3,
            verseText: 'And God said: Be light made. And light was made.',
            isFavorite: true,
          ),
        )
        ..addScenario(
          'Verse with References Badge',
          const BibleVerseRow(
            verseNumber: 4,
            verseText: 'And God saw the light that it was good.',
            citationsCount: 3,
          ),
        )
        ..addScenario(
          'Verse with Comments Badge',
          const BibleVerseRow(
            verseNumber: 5,
            verseText: 'And he called the light Day, and the darkness Night.',
            commentsCount: 1,
          ),
        )
        ..addScenario(
          'Verse with All Badges (Favorite, References, Comments)',
          const BibleVerseRow(
            verseNumber: 6,
            verseText:
                'And there was evening and morning that made the first day.',
            isFavorite: true,
            citationsCount: 2,
            commentsCount: 2,
          ),
        )
        ..addScenario(
          'Parallel Translation Comparison',
          const BibleVerseRow(
            verseNumber: 7,
            verseText:
                'And God said: Let there be a firmament made amidst the waters.',
            compareVerseText:
                'Dixit quoque Deus: Fiat firmamentum in medio aquarum.',
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(800, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'bible_verse_row_scenarios_widescreen_golden',
      );
    },
  );

  testGoldens(
    'MassReadingCard renders references and comments badges correctly',
    (tester) async {
      ReverseCitationService.clear();
      final bookData = ParsedBookData(
        bookId: 'baltimore_3',
        title: 'Baltimore Catechism No. 3',
        subtitle: 'A Catechism of Christian Doctrine',
        author: 'Third Plenary Council of Baltimore',
        toc: [],
        sections: [
          BookSection(
            id: 'lesson_1',
            title: 'On the Creation',
            subtitle: '',
            content: [
              ContentItem(
                type: 'qa',
                questionNumber: 14,
                question: 'Who made the world?',
                answer: 'God made the world. (Gen. 1:1)',
              ),
            ],
          ),
        ],
      );
      ReverseCitationService.indexBookData(
        'assets/catechism/json/baltimore_3.json',
        bookData,
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

      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'My reflection on the beginning.',
          textPreview: const Value(
            'In the beginning God created heaven, and earth.',
          ),
          createdAt: DateTime(2026, 8, 15, 12, 0),
        ),
      );

      final builder = GoldenBuilder.column()
        ..addScenario(
          'Mass Reading Card with Badges',
          const MassReadingCard(reading: reading),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 420),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'mass_reading_card_references_and_comments_golden',
      );
    },
  );

  testGoldens('MassReadingCard renders verse selection and action bar', (
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

    await tester.pumpWidgetBuilder(
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: MassReadingCard(reading: reading),
        ),
      ),
      wrapper: materialAppWrapper(),
      surfaceSize: const Size(450, 480),
    );
    await tester.pumpAndSettle();

    // Select verses 1 and 2
    await tester.longPress(
      find.text('In the beginning God created heaven, and earth.'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('And the earth was void and empty.'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(
      tester,
      'mass_reading_card_selection_active_golden',
    );
  });

  testGoldens('MassReadingCard renders Library reverse citations modal', (
    tester,
  ) async {
    ReverseCitationService.clear();
    final bookData = ParsedBookData(
      bookId: 'baltimore_3',
      title: 'Baltimore Catechism No. 3',
      subtitle: 'A Catechism of Christian Doctrine',
      author: 'Third Plenary Council of Baltimore',
      toc: [],
      sections: [
        BookSection(
          id: 'lesson_1',
          title: 'On the Creation',
          subtitle: '',
          content: [
            ContentItem(
              type: 'qa',
              questionNumber: 14,
              question: 'Who made the world?',
              answer: 'God made the world. (Gen. 1:1)',
            ),
          ],
        ),
      ],
    );
    ReverseCitationService.indexBookData(
      'assets/catechism/json/baltimore_3.json',
      bookData,
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

    await tester.pumpWidgetBuilder(
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: MassReadingCard(reading: reading),
        ),
      ),
      wrapper: materialAppWrapper(),
      surfaceSize: const Size(450, 600),
    );
    await tester.pumpAndSettle();

    // Tap citation badge to open bottom sheet
    await tester.tap(find.byIcon(Icons.auto_stories_rounded));
    await tester.pumpAndSettle();

    await screenMatchesGolden(
      tester,
      'mass_reading_card_reverse_citations_modal_golden',
    );
  });

  testGoldens(
    'MassReadingCard renders verse comments modal and add comment dialog',
    (tester) async {
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

      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'My reflection on the beginning.',
          textPreview: const Value(
            'In the beginning God created heaven, and earth.',
          ),
          createdAt: DateTime(2026, 8, 15, 12, 0),
        ),
      );

      await tester.pumpWidgetBuilder(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: MassReadingCard(reading: reading),
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 600),
      );
      await tester.pumpAndSettle();

      // Tap comments badge to open bottom sheet
      await tester.tap(find.byIcon(Icons.comment_rounded));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'mass_reading_card_comments_modal_golden',
      );

      // Tap Add Another Comment to open Add Comment dialog
      await tester.tap(find.text('Add Another Comment'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'mass_reading_card_add_comment_dialog_golden',
      );
    },
  );

  group('MassReadingCard Liturgical Responses Tests', () {
    testWidgets(
      'First Reading displays "The word of the Lord" and "Thanks be to God" at bottom',
      (WidgetTester tester) async {
        const reading = LectionaryReading(
          id: 1,
          readingKey: 'feast_annunciation',
          readingType: 'first',
          bookNumber: 1,
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

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MassReadingCard(
                reading: reading,
                primaryLanguage: PrayerLanguage.english,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('The word of the Lord.', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Thanks be to God.', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Lector:', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('People:', findRichText: true),
          findsOneWidget,
        );
      },
    );

    testWidgets('Second Reading displays concluding response in Spanish', (
      WidgetTester tester,
    ) async {
      const reading = LectionaryReading(
        id: 2,
        readingKey: 'feast_annunciation',
        readingType: 'second',
        bookNumber: 58,
        bookName: 'Hebrews',
        chapter: 10,
        verseRange: '4-10',
        citation: 'Hebrews 10:4-10',
      );

      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 1,
              bookNumber: 58,
              bookName: 'Hebrews',
              chapter: 10,
              verseNumber: 4,
              verseText:
                  'For it is impossible for the blood of bulls and goats to take away sins.',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: MassReadingCard(
              reading: reading,
              primaryLanguage: PrayerLanguage.spanish,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Palabra de Dios.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Te alabamos, Señor.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Responsorial Psalm does not display concluding acclamation', (
      WidgetTester tester,
    ) async {
      const reading = LectionaryReading(
        id: 3,
        readingKey: 'feast_annunciation',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 40,
        verseRange: '7-11',
        citation: 'Psalms 40:7-11',
      );

      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 1,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 40,
              verseNumber: 7,
              verseText: 'Sacrifice and oblation thou didst not desire.',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: MassReadingCard(
              reading: reading,
              primaryLanguage: PrayerLanguage.english,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('The word of the Lord.', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Thanks be to God.', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('The Gospel of the Lord.', findRichText: true),
        findsNothing,
      );
    });

    testWidgets(
      'Gospel displays introductory dialogue and concluding acclamation with localized evangelist',
      (WidgetTester tester) async {
        const reading = LectionaryReading(
          id: 4,
          readingKey: 'feast_annunciation',
          readingType: 'gospel',
          bookNumber: 51,
          bookName: 'Luke',
          chapter: 1,
          verseRange: '26-38',
          citation: 'Luke 1:26-38',
        );

        await testDb
            .into(testDb.bibleVerses)
            .insert(
              const BibleVerse(
                id: 1,
                bookNumber: 51,
                bookName: 'Luke',
                chapter: 1,
                verseNumber: 26,
                verseText:
                    'And in the sixth month, the angel Gabriel was sent from God into a city of Galilee, called Nazareth,',
                translationCode: 'CPDV',
              ),
            );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: MassReadingCard(
                reading: reading,
                primaryLanguage: PrayerLanguage.english,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Introductory Greeting
        expect(
          find.textContaining('The Lord be with you.', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('And with your spirit.', findRichText: true),
          findsOneWidget,
        );

        // Introductory Announcement
        expect(
          find.textContaining(
            'A reading from the holy Gospel according to Luke.',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Glory to you, O Lord.', findRichText: true),
          findsOneWidget,
        );

        // Concluding Acclamation
        expect(
          find.textContaining('The Gospel of the Lord.', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Praise to you, Lord Jesus Christ.',
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Gospel displays Latin dialogue and comparison language', (
      WidgetTester tester,
    ) async {
      const reading = LectionaryReading(
        id: 5,
        readingKey: 'feast_annunciation',
        readingType: 'gospel',
        bookNumber: 49,
        bookName: 'Matthew',
        chapter: 1,
        verseRange: '1-16',
        citation: 'Matthew 1:1-16',
      );

      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 1,
              bookNumber: 49,
              bookName: 'Matthew',
              chapter: 1,
              verseNumber: 1,
              verseText: 'The book of the genealogy of Jesus Christ.',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: MassReadingCard(
              reading: reading,
              primaryLanguage: PrayerLanguage.latin,
              compareLanguage: PrayerLanguage.english,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Primary Latin
      expect(
        find.textContaining('Dóminus vobíscum.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Et cum spíritu tuo.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Léctio sancti Evangélii secúndum Matthǽum.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Glória tibi, Dómine.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Verbum Dómini.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Laus tibi, Christe.', findRichText: true),
        findsOneWidget,
      );

      // Compare English
      expect(
        find.textContaining('The Lord be with you.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('And with your spirit.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Praise to you, Lord Jesus Christ.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });
  });
}
