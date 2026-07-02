import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import '../test_helper.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
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
  });
}
