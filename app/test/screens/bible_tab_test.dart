import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
      await tester.tap(find.text('Save'));
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

      // Tap Cancel to close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('primary and comparison selection dialogs update preferences', (
      WidgetTester tester,
    ) async {
      // Initialize mock settings
      final settings = UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'none',
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

      // 1. Open Primary Dialog and choose DRC
      await tester.tap(find.text('Primary Translation'));
      await tester.pumpAndSettle();

      // Tap DRC option (we find option containing DRC title)
      await tester.tap(find.text('Douay-Rheims Bible (DRC)').first);
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify primary selection is updated
      expect(settings.primaryBibleTranslation, equals('DRC'));

      // 2. Open Comparison Dialog and choose CPDV
      await tester.tap(find.text('Comparison Translation'));
      await tester.pumpAndSettle();

      // Tap CPDV option
      await tester.tap(
        find.text('Catholic Public Domain Version (CPDV)').first,
      );
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
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
  });
}
