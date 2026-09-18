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

    testWidgets(
      'highlights target verses across chapter boundary for modern citation',
      (WidgetTester tester) async {
        // Insert Job 39 verses 33, 34, 35
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 20,
                bookName: 'Job',
                chapter: 39,
                verseNumber: 33,
                verseText: 'Job answered the Lord.',
                translationCode: 'CPDV',
              ),
            );
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 20,
                bookName: 'Job',
                chapter: 39,
                verseNumber: 34,
                verseText: 'What could I possibly answer?',
                translationCode: 'CPDV',
              ),
            );
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 20,
                bookName: 'Job',
                chapter: 39,
                verseNumber: 35,
                verseText: 'One thing I have spoken.',
                translationCode: 'CPDV',
              ),
            );

        // Modern citation Job 40:4-7
        // Modern 40:4-5 corresponds to Vg 39:34-35; Modern 40:6-7 corresponds to Vg 40:1-2
        const citation = BibleCitation(
          rawMatch: 'Job 40:4-7',
          displayLabel: 'Job 40:4-7',
          bookNumber: 20,
          bookName: 'Job',
          chapter: 40,
          verse: 4,
          endVerse: 7,
          abbrev: 'JOB',
          verseSystem: 'modern',
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
                      child: const Text('Open Cross-Chapter Modal'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Cross-Chapter Modal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Header shows Vulgate chapter with Modern alternate
        expect(find.text('Job 39 (Modern 40)'), findsOneWidget);

        // Check verse text presence
        expect(find.text('Job answered the Lord.'), findsOneWidget);
        expect(find.text('What could I possibly answer?'), findsOneWidget);
        expect(find.text('One thing I have spoken.'), findsOneWidget);

        // Check dual verse numbers
        expect(find.text('34 (40:4)'), findsOneWidget);
        expect(find.text('35 (40:5)'), findsOneWidget);

        // Find AnimatedContainers for each verse and verify highlight
        final containers = tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        final verseContainers = containers.where((c) {
          final decoration = c.decoration as BoxDecoration?;
          return decoration != null && decoration.borderRadius != null;
        }).toList();

        expect(verseContainers.length, 3);
        final v33Decoration = verseContainers[0].decoration as BoxDecoration;
        final v34Decoration = verseContainers[1].decoration as BoxDecoration;
        final v35Decoration = verseContainers[2].decoration as BoxDecoration;

        expect(v33Decoration.border, isNull);
        expect(v34Decoration.border, isNotNull);
        expect(v35Decoration.border, isNotNull);
      },
    );
  });
}
