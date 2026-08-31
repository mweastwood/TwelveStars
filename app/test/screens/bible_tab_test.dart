import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import 'package:twelve_stars/widgets/bible_chapter_view.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';

import '../test_helper.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    PrayerDatabase.mockPrayers = [];
  });

  tearDown(() async {
    PrayerDatabase.mockSettings = null;
    await testDb.close();
  });

  group('BibleTab Widget Tests', () {
    testWidgets('displays verses from database', (WidgetTester tester) async {
      // Pre-populate database with mock verses
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText:
                  'In the beginning God created the heaven, and the earth.',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 2,
              verseText: 'And the earth was void and empty.',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );

      // Verify it starts with a loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for async load to finish
      await tester.pumpAndSettle();

      // Verify title and verses are displayed
      expect(find.text('Genesis 1'), findsNWidgets(2));
      expect(
        find.text('Catholic Public Domain Version (CPDV)'),
        findsOneWidget,
      );
      expect(
        find.text('In the beginning God created the heaven, and the earth.'),
        findsOneWidget,
      );
      expect(find.text('And the earth was void and empty.'), findsOneWidget);
    });

    testWidgets(
      'restores saved Bible reading position and persists new position on navigation',
      (WidgetTester tester) async {
        final genesisBook = catholicBooks.firstWhere((b) => b.bookNumber == 1);

        await tester.runAsync(() async {
          await testDb.ensureBookPopulated(2, 'Exodus', 'EXO');
          await testDb.ensureBookPopulated(1, 'Genesis', 'GEN');
        });

        final settings = UserSettings(
          lastBibleBookNumber: 2, // Exodus
          lastBibleChapter: 1,
        );
        await testDb.saveUserSettings(settings);
        PrayerDatabase.mockPrayers = null;

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // Verify it restored to Exodus 1
        expect(find.text('Exodus 1'), findsNWidgets(2));

        // Navigate to Genesis 2
        final state = tester.state<BibleTabState>(find.byType(BibleTab));
        state.navigateToChapter(genesisBook, 2);
        await tester.pumpAndSettle();

        final updatedSettings = await testDb.getUserSettings();
        expect(updatedSettings?.lastBibleBookNumber, equals(1));
        expect(updatedSettings?.lastBibleChapter, equals(2));
      },
    );

    testWidgets('navigateToFavorite navigates and sets highlight target', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await testDb.ensureBookPopulated(1, 'Genesis', 'GEN');
      });

      final settings = UserSettings(
        lastBibleBookNumber: 1,
        lastBibleChapter: 1,
      );
      await testDb.saveUserSettings(settings);
      PrayerDatabase.mockPrayers = null;

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pumpAndSettle();

      const fav = FavoritePassage(
        id: 1,
        bookNumber: 1,
        bookName: 'Genesis',
        chapter: 2,
        startVerse: 3,
        endVerse: 4,
        textPreview: 'And he blessed the seventh day, and sanctified it.',
      );

      final state = tester.state<BibleTabState>(find.byType(BibleTab));
      state.navigateToFavorite(fav);
      await tester.pumpAndSettle();

      final updatedSettings = await testDb.getUserSettings();
      expect(updatedSettings?.lastBibleBookNumber, equals(1));
      expect(updatedSettings?.lastBibleChapter, equals(2));
    });

    testWidgets('navigateToComment navigates and sets highlight target', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await testDb.ensureBookPopulated(1, 'Genesis', 'GEN');
      });

      final settings = UserSettings(
        lastBibleBookNumber: 1,
        lastBibleChapter: 1,
      );
      await testDb.saveUserSettings(settings);
      PrayerDatabase.mockPrayers = null;

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pumpAndSettle();

      final comment = UserComment(
        id: 1,
        documentId: 'gen',
        sectionIndex: 3,
        nodeId: 'gen_3_5',
        commentText: 'Test reflection',
        createdAt: DateTime(2026, 1, 1),
      );

      final state = tester.state<BibleTabState>(find.byType(BibleTab));
      state.navigateToComment(comment);
      await tester.pumpAndSettle();

      final updatedSettings = await testDb.getUserSettings();
      expect(updatedSettings?.lastBibleBookNumber, equals(1));
      expect(updatedSettings?.lastBibleChapter, equals(3));
    });

    testGoldens('renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Bible Tab Populated State',
          BibleTab(
            initialVerses: [
              BibleVerse(
                id: 1,
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText:
                    'In the beginning God created the heaven, and the earth.',
                translationCode: 'CPDV',
              ),
            ],
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'bible_tab_populated_golden');
    });

    testWidgets('expand navigation sheet and select book and chapter', (
      WidgetTester tester,
    ) async {
      // Pre-populate Gen 1 and Exo 1
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning...',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 2,
              bookName: 'Exodus',
              chapter: 1,
              verseNumber: 1,
              verseText: 'These are the names...',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Panel starts collapsed, displaying "Genesis 1"
      expect(find.text('Genesis 1'), findsNWidgets(2));
      expect(find.text('Books'), findsNothing);

      // Drag up from the location header
      await tester.drag(find.text('Genesis 1').last, const Offset(0.0, -300.0));
      await tester.pumpAndSettle();

      // Verify the panel is now expanded
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Chapters'), findsOneWidget);

      // Tap on "Exodus" chip
      await tester.tap(find.text('Exodus'));
      await tester.pumpAndSettle();

      // Tap chapter 1 of Exodus
      await tester.tap(find.text('1').last);
      await tester.pumpAndSettle();

      // Now it should have transitioned to Exodus 1
      expect(find.text('Exodus 1'), findsNWidgets(2));
      expect(find.text('These are the names...'), findsOneWidget);
    });

    testWidgets('horizontal swiping transitions chapters', (
      WidgetTester tester,
    ) async {
      // Pre-populate Genesis 1 and Genesis 2
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'Genesis 1 Verse 1',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 2,
              verseNumber: 1,
              verseText: 'Genesis 2 Verse 1',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Genesis 1 Verse 1'), findsOneWidget);

      // Swipe left (drag from right to left) to go to the next page
      await tester.drag(
        find.text('Genesis 1 Verse 1'),
        const Offset(-400.0, 0.0),
      );
      await tester.pumpAndSettle();

      // Now we should be on Genesis 2
      expect(find.text('Genesis 2 Verse 1'), findsOneWidget);
      expect(find.text('Genesis 2'), findsNWidgets(2));
    });

    testWidgets('long press to select verses and save as favorite', (
      WidgetTester tester,
    ) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning...',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 2,
              verseText: 'And the earth was void...',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Long press verse 1 to start selection
      await tester.longPress(find.text('In the beginning...'));
      await tester.pumpAndSettle();

      // Tap verse 2 to expand selection
      await tester.tap(find.text('And the earth was void...'));
      await tester.pumpAndSettle();

      // Check selection bar appears
      expect(find.text('Genesis 1:1-2'), findsOneWidget);
      expect(find.text('2 verses selected'), findsOneWidget);

      // Tap Save
      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      // Verify SnackBar and favorites list has the favorite
      expect(find.byType(SnackBar), findsOneWidget);
      final favorites = await testDb.getFavorites();
      expect(favorites.length, 1);
      final fav = favorites.first;
      expect(fav.bookName, 'Genesis');
      expect(fav.chapter, 1);
      expect(fav.startVerse, 1);
      expect(fav.endVerse, 2);
    });

    testWidgets('long press to select verses and copy to clipboard', (
      WidgetTester tester,
    ) async {
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

      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning...',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 2,
              verseText: 'And the earth was void...',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Long press verse 1 to start selection
      await tester.longPress(find.text('In the beginning...'));
      await tester.pumpAndSettle();

      // Tap verse 2 to expand selection
      await tester.tap(find.text('And the earth was void...'));
      await tester.pumpAndSettle();

      // Tap Copy
      await tester.tap(find.byTooltip('Copy selection'));
      await tester.pumpAndSettle();

      // Verify SnackBar and clipboard data
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Copied Genesis 1:1-2 to clipboard'), findsOneWidget);

      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        clipboardData?.text,
        'Genesis 1:1-2\n1 In the beginning...\n2 And the earth was void...',
      );
    });

    testGoldens('renders selection bar correctly', (tester) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created...',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidgetBuilder(
        const Scaffold(body: BibleTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.longPress(find.text('In the beginning God created...'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'bible_tab_selection_active_golden');
    });

    testGoldens('renders favorites tab correctly', (tester) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created...',
              translationCode: 'CPDV',
            ),
          );

      await testDb
          .into(testDb.favoritePassages)
          .insert(
            FavoritePassagesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              startVerse: 1,
              endVerse: 1,
              textPreview: 'In the beginning God created...',
            ),
          );

      await tester.pumpWidgetBuilder(
        const Scaffold(body: BibleTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(find.text('Genesis 1').last, const Offset(0.0, -300.0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'bible_tab_favorites_list_golden');
    });

    testWidgets('displays both translations side-by-side in parallel view', (
      WidgetTester tester,
    ) async {
      // 1. Setup mock settings
      final settings = UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'DRC',
      );
      PrayerDatabase.mockSettings = settings;

      // 2. Pre-populate database with verses for both CPDV and DRC
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created the heaven (CPDV).',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created heaven (DRC).',
              translationCode: 'DRC',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 3. Verify both texts are on screen
      expect(
        find.text('In the beginning God created the heaven (CPDV).'),
        findsOneWidget,
      );
      expect(
        find.text('In the beginning God created heaven (DRC).'),
        findsOneWidget,
      );

      // Clean up mock settings
      PrayerDatabase.mockSettings = null;
    });

    testGoldens('renders primary translation dialog correctly', (tester) async {
      final settings = UserSettings(showBibleTranslationSelectors: true);
      PrayerDatabase.mockSettings = settings;

      // 1. Populate database to prevent infinite loading spinner
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created...',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidgetBuilder(
        const Scaffold(body: BibleTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Primary Translation card
      await tester.tap(find.text('Primary Translation'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'bible_tab_primary_dialog_golden');

      // Tap Close to close dialog
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      PrayerDatabase.mockSettings = null;
    });

    testWidgets('primary and comparison selection dialogs update preferences', (
      WidgetTester tester,
    ) async {
      // Initialize mock settings
      final settings = UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'none',
        showBibleTranslationSelectors: true,
      );
      PrayerDatabase.mockSettings = settings;

      // Populate database for verification
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created the heaven (CPDV).',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created heaven (DRC).',
              translationCode: 'DRC',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Open Primary Dialog
      await tester.tap(find.text('Primary Translation'));
      await tester.pumpAndSettle();

      // Tap DRC translation card to set as Primary
      await tester.tap(find.text('Douay-Rheims Bible (Challoner Revision)'));
      await tester.pumpAndSettle();

      // Verify primary selection is updated
      expect(settings.primaryBibleTranslation, equals('DRC'));

      // Switch target to Secondary inside dialog
      await tester.tap(find.text('Selecting Secondary'));
      await tester.pumpAndSettle();

      // Enter search text "Catholic Public Domain" to isolate CPDV card
      await tester.enterText(find.byType(TextField), 'Catholic Public Domain');
      await tester.pumpAndSettle();

      // Tap CPDV card to set as Secondary
      await tester.tap(find.text('Catholic Public Domain Version'));
      await tester.pumpAndSettle();

      // Verify comparison selection is updated
      expect(settings.compareBibleTranslation, equals('CPDV'));

      PrayerDatabase.mockSettings = null;
    });

    testWidgets('comparison verse text uses matching onSurface color', (
      WidgetTester tester,
    ) async {
      final settings = UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'DRC',
      );
      PrayerDatabase.mockSettings = settings;

      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'Verse CPDV',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'Verse DRC',
              translationCode: 'DRC',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Locate the CPDV Text widget and DRC Text widget
      final cpdvTextWidget = tester.widget<Text>(find.text('Verse CPDV'));
      final drcTextWidget = tester.widget<Text>(find.text('Verse DRC'));

      // Verify that their styles have the exact same color
      expect(cpdvTextWidget.style?.color, equals(drcTextWidget.style?.color));

      PrayerDatabase.mockSettings = null;
    });

    testGoldens('renders parallel translations side-by-side correctly', (
      tester,
    ) async {
      // 1. Setup mock settings for parallel view
      final settings = UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'DRC',
      );
      PrayerDatabase.mockSettings = settings;

      // 2. Pre-populate database with verses for both CPDV and DRC
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created the heaven (CPDV).',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created heaven (DRC).',
              translationCode: 'DRC',
            ),
          );

      await tester.pumpWidgetBuilder(
        const Scaffold(body: BibleTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await screenMatchesGolden(
        tester,
        'bible_tab_parallel_translation_golden',
      );

      // Clean up mock settings
      PrayerDatabase.mockSettings = null;
    });

    testWidgets('allows adding a comment to a verse via selection action bar', (
      WidgetTester tester,
    ) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText:
                  'In the beginning God created the heaven, and the earth.',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pumpAndSettle();

      // Long press verse to trigger selection bar
      await tester.longPress(
        find.text('In the beginning God created the heaven, and the earth.'),
      );
      await tester.pumpAndSettle();

      // Tap Add Comment button in selection bar
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.comment_outlined));
      await tester.pumpAndSettle();

      // Verify Add Comment dialog appears
      expect(find.text('Add Comment for Genesis 1:1'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter comment text and save
      await tester.enterText(
        find.byType(TextField),
        'My Genesis 1:1 reflection',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify comment saved in DB
      final commentsInDb = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_1',
      );
      expect(commentsInDb.length, 1);
      expect(commentsInDb.first.commentText, 'My Genesis 1:1 reflection');

      // Verify comment badge is now displayed next to the verse
      expect(find.byIcon(Icons.comment_rounded), findsOneWidget);
    });

    testWidgets(
      'Bible verse selection action bar displays buttons in order (Save, Comment, Copy, Close) and saves favorite',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText:
                    'In the beginning God created the heaven, and the earth.',
                translationCode: 'CPDV',
              ),
            );

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // Long press verse to trigger selection bar
        await tester.longPress(
          find.text('In the beginning God created the heaven, and the earth.'),
        );
        await tester.pumpAndSettle();

        // Verify button order: Save (star) -> Comment (comment_outlined) -> Copy (content_copy) -> Close (close)
        final starFinder = find.byIcon(Icons.star);
        final commentFinder = find.byIcon(Icons.comment_outlined);
        final copyFinder = find.byIcon(Icons.content_copy);
        final closeFinder = find.byIcon(Icons.close);

        expect(starFinder, findsOneWidget);
        expect(commentFinder, findsOneWidget);
        expect(copyFinder, findsOneWidget);
        expect(closeFinder, findsOneWidget);

        final starX = tester.getCenter(starFinder).dx;
        final commentX = tester.getCenter(commentFinder).dx;
        final copyX = tester.getCenter(copyFinder).dx;
        final closeX = tester.getCenter(closeFinder).dx;

        expect(starX, lessThan(commentX));
        expect(commentX, lessThan(copyX));
        expect(copyX, lessThan(closeX));

        // Tap Save (star icon)
        await tester.tap(starFinder);
        await tester.pumpAndSettle();

        // Verify favorite is saved in database
        final favorites = await testDb.getFavorites();
        expect(favorites.length, 1);
        expect(favorites.first.bookName, 'Genesis');
        expect(favorites.first.chapter, 1);
        expect(favorites.first.startVerse, 1);
        expect(favorites.first.endVerse, 1);
      },
    );

    testWidgets('opens verse comments modal and deletes comment', (
      WidgetTester tester,
    ) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created...',
              translationCode: 'CPDV',
            ),
          );

      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'Existing verse comment',
          textPreview: const Value('In the beginning God created...'),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pumpAndSettle();

      // Verify comment badge is rendered
      expect(find.byIcon(Icons.comment_rounded), findsOneWidget);

      // Tap comment badge to open modal
      await tester.tap(find.byIcon(Icons.comment_rounded));
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Comments for Genesis 1:1'), findsOneWidget);
      expect(find.text('Existing verse comment'), findsOneWidget);

      // Tap delete button in modal
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify comment deleted from DB
      final commentsInDb = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_1',
      );
      expect(commentsInDb.isEmpty, isTrue);
    });

    testWidgets(
      'shows star badge on favorited verse and allows deleting via modal',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'In the beginning God created...',
                translationCode: 'CPDV',
              ),
            );

        await testDb.saveFavorite(
          FavoritePassagesCompanion.insert(
            bookNumber: 1,
            bookName: 'Genesis',
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            textPreview: 'In the beginning God created...',
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // Verify star badge is rendered next to verse 1
        expect(find.byIcon(Icons.star_rounded), findsOneWidget);

        // Tap star badge to open favorites modal
        await tester.tap(find.byIcon(Icons.star_rounded));
        await tester.pumpAndSettle();

        // Verify modal content
        expect(find.text('Favorite Passage for Genesis 1:1'), findsOneWidget);
        expect(
          find.text('In the beginning God created...'),
          findsNWidgets(2),
        ); // in verse row + modal

        // Tap delete button in modal
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Verify favorite deleted from DB
        final favsInDb = await testDb.getFavorites();
        expect(favsInDb.isEmpty, isTrue);

        // Star badge should now be removed from verse row
        expect(find.byIcon(Icons.star_rounded), findsNothing);
      },
    );

    testWidgets(
      'opens verse comments modal, edits comment, and updates UI and DB',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'In the beginning God created...',
                translationCode: 'CPDV',
              ),
            );

        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'GEN',
            sectionIndex: 1,
            nodeId: '1_1_1',
            commentText: 'Original comment text',
            textPreview: const Value('In the beginning God created...'),
            createdAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // Tap comment badge to open verse comments modal
        await tester.tap(find.byIcon(Icons.comment_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Original comment text'), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

        // Tap edit button
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        // Verify Edit dialog is opened with pre-populated text
        expect(find.text('Edit Comment for Genesis 1:1'), findsOneWidget);
        expect(
          find.text('Original comment text'),
          findsNWidgets(2),
        ); // One in sheet behind, one in textfield

        // Update text in TextField
        await tester.enterText(
          find.byType(TextField),
          'Edited comment text in modal',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Verify SnackBar and updated text in modal
        expect(find.text('Updated comment for Genesis 1:1'), findsOneWidget);
        expect(find.text('Edited comment text in modal'), findsOneWidget);

        // Verify updated in DB
        final commentsInDb = await testDb.getComments(
          documentId: 'GEN',
          nodeId: '1_1_1',
        );
        expect(commentsInDb.length, equals(1));
        expect(
          commentsInDb.first.commentText,
          equals('Edited comment text in modal'),
        );
      },
    );

    testWidgets(
      'canceling edit comment dialog preserves original comment text',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'In the beginning God created...',
                translationCode: 'CPDV',
              ),
            );

        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'GEN',
            sectionIndex: 1,
            nodeId: '1_1_1',
            commentText: 'Unchanged original comment',
            textPreview: const Value('In the beginning God created...'),
            createdAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // Open comments modal
        await tester.tap(find.byIcon(Icons.comment_rounded));
        await tester.pumpAndSettle();

        // Tap Edit
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        // Change text but tap Cancel
        await tester.enterText(
          find.byType(TextField),
          'Modified but canceled text',
        );
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        // Verify original text still displayed
        expect(find.text('Unchanged original comment'), findsOneWidget);
        expect(find.text('Modified but canceled text'), findsNothing);

        // Verify DB unchanged
        final commentsInDb = await testDb.getComments(
          documentId: 'GEN',
          nodeId: '1_1_1',
        );
        expect(
          commentsInDb.first.commentText,
          equals('Unchanged original comment'),
        );
      },
    );

    testWidgets('edits comment from Bible tab bottom panel Comments drawer', (
      WidgetTester tester,
    ) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created...',
              translationCode: 'CPDV',
            ),
          );

      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'Drawer comment original',
          textPreview: const Value('In the beginning God created...'),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expand bottom panel
      await tester.drag(find.text('Genesis 1').last, const Offset(0.0, -300.0));
      await tester.pumpAndSettle();

      // Switch to Comments tab
      await tester.tap(find.text('Comments'));
      await tester.pumpAndSettle();

      expect(find.text('Drawer comment original'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Tap Edit button
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Comment for Genesis 1:1'), findsOneWidget);

      // Update text and save
      await tester.enterText(find.byType(TextField), 'Drawer comment updated');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify UI reflects new text
      expect(find.text('Drawer comment updated'), findsOneWidget);

      // Verify DB update
      final commentsInDb = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_1',
      );
      expect(commentsInDb.first.commentText, equals('Drawer comment updated'));
    });

    testGoldens('renders comments tab in bottom panel correctly', (
      tester,
    ) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created...',
              translationCode: 'CPDV',
            ),
          );

      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'A note on Genesis 1:1',
          textPreview: const Value('In the beginning God created...'),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidgetBuilder(
        const Scaffold(body: BibleTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(find.text('Genesis 1').last, const Offset(0.0, -300.0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comments'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'bible_tab_comments_list_golden');
    });

    testWidgets('scrollToVerse navigates to off-screen verse in long chapter', (
      WidgetTester tester,
    ) async {
      for (int i = 1; i <= 50; i++) {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: i,
                verseText:
                    'Genesis 1 verse $i long content text line for scrolling test verification.',
                translationCode: 'CPDV',
              ),
            );
      }

      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: SizedBox(
              height: 600,
              child: BibleChapterView(
                book: catholicBooks.firstWhere((b) => b.bookNumber == 1),
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                scrollController: scrollController,
                scrollToVerse: 45,
                highlightStartVerse: 45,
                highlightEndVerse: 45,
                navigationSessionId: 'session_test_45',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify verse 45 is scrolled into view and visible
      expect(
        find.text(
          'Genesis 1 verse 45 long content text line for scrolling test verification.',
        ),
        findsOneWidget,
      );
      expect(scrollController.offset, greaterThan(0.0));

      // Advance past highlight timer so no pending timers remain after widget disposal
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
      'enforces maxCachedControllers (10) on chapter scroll controllers',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<BibleTabState>(find.byType(BibleTab));
        expect(state.chapterScrollControllers.length, lessThanOrEqualTo(10));
      },
    );

    testWidgets(
      'initializes with the translation selector collapsed by default',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<BibleTabState>(find.byType(BibleTab));
        expect(state.showTranslationSelectors, isFalse);
      },
    );

    testWidgets(
      'toggling translation selector animates panel and saves state to UserSettings',
      (WidgetTester tester) async {
        final initialSettings = UserSettings(
          showBibleTranslationSelectors: false,
        );
        PrayerDatabase.mockSettings = initialSettings;

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<BibleTabState>(find.byType(BibleTab));
        expect(state.showTranslationSelectors, isFalse);

        // Toggle open
        state.toggleTranslationSelectors();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(state.showTranslationSelectors, isTrue);
        expect(
          PrayerDatabase.mockSettings?.showBibleTranslationSelectors,
          isTrue,
        );

        // Toggle closed
        state.toggleTranslationSelectors();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(state.showTranslationSelectors, isFalse);
        expect(
          PrayerDatabase.mockSettings?.showBibleTranslationSelectors,
          isFalse,
        );
      },
    );

    testWidgets(
      'restores open state when initialized with showBibleTranslationSelectors: true in settings',
      (WidgetTester tester) async {
        final initialSettings = UserSettings(
          showBibleTranslationSelectors: true,
        );
        PrayerDatabase.mockSettings = initialSettings;

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<BibleTabState>(find.byType(BibleTab));
        expect(state.showTranslationSelectors, isTrue);
      },
    );

    testWidgets(
      'renders Psalm header in Vulgate, Modern, and Dual numbering modes',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 115,
                verseNumber: 1,
                verseText:
                    'Alleluia. I had confidence, because of what I was saying, but then I was greatly humbled.',
                translationCode: 'CPDV',
              ),
            );

        final psalmBook = catholicBooks.firstWhere((b) => b.bookNumber == 21);

        // 1. Vulgate Mode
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: psalmBook,
                chapter: 115,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                numberingSystem: BibleNumberingSystem.vulgate,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Psalms 115'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        // 2. Modern Mode
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: psalmBook,
                chapter: 115,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                numberingSystem: BibleNumberingSystem.modern,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Psalms 116'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);

        // 3. Dual Mode
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: psalmBook,
                chapter: 115,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                numberingSystem: BibleNumberingSystem.dual,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Psalms 115 (Modern 116)'), findsOneWidget);
        expect(find.text('1 (10)'), findsOneWidget);
      },
    );

    testGoldens(
      'renders real CPDV Psalm 115 chapter under Vulgate, Modern, and Dual numbering schemes with verse number shifts',
      (tester) async {
        final psalmBook = catholicBooks.firstWhere((b) => b.bookNumber == 21);
        final psalm115Verses = [
          'Alleluia. I had confidence, because of what I was saying, but then I was greatly humbled.',
          'I said in my excess, “Every man is a liar.”',
          'What shall I repay to the Lord, for all the things that he has repaid to me?',
          'I will take up the cup of salvation, and I will call upon the name of the Lord.',
          'I will repay my vows to the Lord, in the sight of all his people.',
          'Precious in the sight of the Lord is the death of his holy ones.',
          'O Lord, because I am your servant, your servant and the son of your handmaid, you have broken my bonds.',
          'I will sacrifice to you the sacrifice of praise, and I will invoke the name of the Lord.',
          'I will repay my vows to the Lord in the sight of all his people,',
          'in the courts of the house of the Lord, in your midst, O Jerusalem.',
        ];

        for (var i = 0; i < psalm115Verses.length; i++) {
          await testDb
              .into(testDb.bibleVerses)
              .insert(
                BibleVersesCompanion.insert(
                  bookNumber: 21,
                  bookName: 'Psalms',
                  chapter: 115,
                  verseNumber: i + 1,
                  verseText: psalm115Verses[i],
                  translationCode: 'CPDV',
                ),
              );
        }

        // 1. Vulgate Numbering Scheme
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: BibleChapterView(
              book: psalmBook,
              chapter: 115,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              numberingSystem: BibleNumberingSystem.vulgate,
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();
        await screenMatchesGolden(
          tester,
          'bible_chapter_cpdv_psalm_115_vulgate_golden',
        );

        // 2. Modern Numbering Scheme
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: BibleChapterView(
              book: psalmBook,
              chapter: 115,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              numberingSystem: BibleNumberingSystem.modern,
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();
        await screenMatchesGolden(
          tester,
          'bible_chapter_cpdv_psalm_115_modern_golden',
        );

        // 3. Dual Numbering Scheme
        await tester.pumpWidgetBuilder(
          Scaffold(
            body: BibleChapterView(
              book: psalmBook,
              chapter: 115,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              numberingSystem: BibleNumberingSystem.dual,
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();
        await screenMatchesGolden(
          tester,
          'bible_chapter_cpdv_psalm_115_dual_golden',
        );
      },
    );

    testWidgets('tapping unassigned ribbon shows instructional snackbar', (
      WidgetTester tester,
    ) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning...',
              translationCode: 'CPDV',
            ),
          );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bible_ribbon_0')));
      await tester.pump();

      expect(
        find.text('Long press this ribbon to bookmark the current chapter'),
        findsOneWidget,
      );
    });

    testWidgets(
      'long pressing ribbon bookmarks current chapter and updates settings',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'In the beginning...',
                translationCode: 'CPDV',
              ),
            );
        PrayerDatabase.mockPrayers = null;

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byKey(const Key('bible_ribbon_2')));
        await tester.pumpAndSettle();

        final settings = await testDb.getUserSettings();
        expect(settings?.bibleRibbons, isNotNull);
        expect(settings!.bibleRibbons!.length, equals(1));
        expect(settings.bibleRibbons!.first.ribbonIndex, equals(2));
        expect(settings.bibleRibbons!.first.bookNumber, equals(1));
        expect(settings.bibleRibbons!.first.chapter, equals(1));
      },
    );

    testWidgets('tapping assigned ribbon jumps to bookmarked chapter', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await testDb.ensureBookPopulated(1, 'Genesis', 'GEN');
        await testDb.ensureBookPopulated(2, 'Exodus', 'EXO');
      });

      final settings = UserSettings(
        lastBibleBookNumber: 1, // Genesis 1
        lastBibleChapter: 1,
        bibleRibbons: [
          const BibleRibbonBookmark(
            ribbonIndex: 1,
            bookNumber: 2,
            chapter: 1,
          ), // Exodus 1
        ],
      );
      await testDb.saveUserSettings(settings);
      PrayerDatabase.mockPrayers = null;

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pumpAndSettle();

      // Starts on Genesis 1
      expect(find.text('Genesis 1'), findsNWidgets(2));

      // Tap ribbon 1 (Gold Ribbon -> Exodus 1)
      await tester.tap(find.byKey(const Key('bible_ribbon_1')));
      await tester.pumpAndSettle();

      expect(find.text('Exodus 1'), findsNWidgets(2));

      final updatedSettings = await testDb.getUserSettings();
      expect(updatedSettings?.lastBibleBookNumber, equals(2));
      expect(updatedSettings?.lastBibleChapter, equals(1));
    });

    testWidgets(
      'long-pressing a ribbon immediately renders vertical page ribbon on current chapter',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'Genesis 1 Verse 1',
                translationCode: 'CPDV',
              ),
            );
        PrayerDatabase.mockPrayers = null;

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // Initially no page ribbon
        expect(find.byKey(const Key('bible_page_ribbon_2')), findsNothing);

        // Long press green ribbon (ribbon 2)
        await tester.longPress(find.byKey(const Key('bible_ribbon_2')));
        await tester.pumpAndSettle();

        // Page ribbon should now appear
        expect(find.byKey(const Key('bible_page_ribbon_2')), findsOneWidget);
      },
    );

    testWidgets(
      'swiping between bookmarked and unbookmarked chapters updates page ribbon visibility',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'Genesis 1 Verse 1',
                translationCode: 'CPDV',
              ),
            );
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 2,
                verseNumber: 1,
                verseText: 'Genesis 2 Verse 1',
                translationCode: 'CPDV',
              ),
            );

        final settings = UserSettings(
          lastBibleBookNumber: 1,
          lastBibleChapter: 1,
          bibleRibbons: [
            const BibleRibbonBookmark(
              ribbonIndex: 0,
              bookNumber: 1,
              chapter: 1,
            ),
          ],
        );
        await testDb.saveUserSettings(settings);
        PrayerDatabase.mockPrayers = null;

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // On Genesis 1, red page ribbon (index 0) is visible
        expect(find.byKey(const Key('bible_page_ribbon_0')), findsOneWidget);

        // Swipe to Genesis 2
        await tester.drag(
          find.text('Genesis 1 Verse 1'),
          const Offset(-400.0, 0.0),
        );
        await tester.pumpAndSettle();

        // On Genesis 2, no page ribbon
        expect(find.text('Genesis 2 Verse 1'), findsOneWidget);
        expect(find.byKey(const Key('bible_page_ribbon_0')), findsNothing);

        // Swipe back to Genesis 1
        await tester.drag(
          find.text('Genesis 2 Verse 1'),
          const Offset(400.0, 0.0),
        );
        await tester.pumpAndSettle();

        // On Genesis 1 again, page ribbon is visible
        expect(find.text('Genesis 1 Verse 1'), findsOneWidget);
        expect(find.byKey(const Key('bible_page_ribbon_0')), findsOneWidget);
      },
    );

    testWidgets(
      'long pressing a ribbon replaces any existing ribbon on the current chapter (one ribbon per page)',
      (WidgetTester tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'Genesis 1 Verse 1',
                translationCode: 'CPDV',
              ),
            );
        final initialSettings = UserSettings(
          lastBibleBookNumber: 1,
          lastBibleChapter: 1,
          bibleRibbons: [
            const BibleRibbonBookmark(
              ribbonIndex: 0,
              bookNumber: 1,
              chapter: 1,
            ),
          ],
        );
        await testDb.saveUserSettings(initialSettings);
        PrayerDatabase.mockPrayers = null;

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        // Ribbon 0 is initially present
        expect(find.byKey(const Key('bible_page_ribbon_0')), findsOneWidget);

        // Long press green ribbon (ribbon 2) on Genesis 1
        await tester.longPress(find.byKey(const Key('bible_ribbon_2')));
        await tester.pumpAndSettle();

        // Ribbon 0 should be replaced by ribbon 2 on the page
        expect(find.byKey(const Key('bible_page_ribbon_0')), findsNothing);
        expect(find.byKey(const Key('bible_page_ribbon_2')), findsOneWidget);

        final updatedSettings = await testDb.getUserSettings();
        expect(updatedSettings?.bibleRibbons, isNotNull);
        expect(updatedSettings!.bibleRibbons!.length, equals(1));
        expect(updatedSettings.bibleRibbons!.first.ribbonIndex, equals(2));
        expect(updatedSettings.bibleRibbons!.first.bookNumber, equals(1));
        expect(updatedSettings.bibleRibbons!.first.chapter, equals(1));
      },
    );

    testGoldens('renders vertical page ribbons on bookmarked Bible chapter', (
      tester,
    ) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText:
                  'In the beginning God created the heaven, and the earth.',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 2,
              verseText:
                  'And the earth was void and empty, and darkness was upon the face of the deep; and the spirit of God moved over the waters.',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 3,
              verseText: 'And God said: Be light made. And light was made.',
              translationCode: 'CPDV',
            ),
          );

      final settings = UserSettings(
        lastBibleBookNumber: 1,
        lastBibleChapter: 1,
        bibleRibbons: [
          const BibleRibbonBookmark(ribbonIndex: 0, bookNumber: 1, chapter: 1),
          const BibleRibbonBookmark(
            ribbonIndex: 2,
            bookNumber: 19,
            chapter: 23,
          ),
        ],
      );
      await testDb.saveUserSettings(settings);
      PrayerDatabase.mockPrayers = null;

      await tester.pumpWidgetBuilder(
        const Scaffold(body: BibleTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'bible_tab_bookmarked_page_ribbons_golden',
      );
    });

    testGoldens(
      'renders highlighted Bible verse on chapter marked with ribbon without ribbon intersection',
      (tester) async {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
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
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 2,
                verseText:
                    'And the earth was void and empty, and darkness was upon the face of the deep; and the spirit of God moved over the waters.',
                translationCode: 'CPDV',
              ),
            );

        final settings = UserSettings(
          lastBibleBookNumber: 1,
          lastBibleChapter: 1,
          bibleRibbons: [
            const BibleRibbonBookmark(
              ribbonIndex: 0,
              bookNumber: 1,
              chapter: 1,
            ),
          ],
        );
        await testDb.saveUserSettings(settings);
        PrayerDatabase.mockPrayers = null;

        await tester.pumpWidgetBuilder(
          const Scaffold(body: BibleTab()),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Long press verse 1 to highlight / select it
        await tester.longPress(
          find.text('In the beginning God created heaven, and earth.'),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'bible_tab_bookmarked_ribbon_verse_highlight_golden',
        );
      },
    );
  });
}
