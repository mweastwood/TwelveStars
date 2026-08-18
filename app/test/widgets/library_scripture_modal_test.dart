import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/widgets/reader/library_scripture_modal.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
  });

  tearDown(() async {
    await testDb.close();
  });

  group('LibraryScriptureModal Tests', () {
    testWidgets('renders Scripture preview modal with verses', (
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
              verseText: 'In the beginning God created heaven, and earth.',
              translationCode: 'CPDV',
            ),
          );

      const citation = BibleCitation(
        rawMatch: 'Gen 1:1',
        displayLabel: 'Genesis 1:1',
        bookNumber: 1,
        bookName: 'Genesis',
        chapter: 1,
        verse: 1,
        abbrev: 'GEN',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => showLibraryScriptureModal(
                      context: context,
                      citation: citation,
                    ),
                    child: const Text('Open Scripture Modal'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Scripture Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Genesis 1'), findsOneWidget);
      expect(
        find.text('Catholic Public Domain Version (CPDV)'),
        findsOneWidget,
      );
      expect(
        find.text('In the beginning God created heaven, and earth.'),
        findsOneWidget,
      );
    });
  });
}
