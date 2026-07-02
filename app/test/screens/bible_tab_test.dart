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
  });
}
