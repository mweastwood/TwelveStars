import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reader/bible_reader_adapter.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/bible_annotation_card.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/library_scripture_modal.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    PrayerDatabase.mockSettings = UserSettings();
    UserSettingsController.instance.resetForTesting();
  });

  tearDown(() async {
    UserSettingsController.instance.resetForTesting();
    PrayerDatabase.mockSettings = null;
    await testDb.close();
  });

  group('BibleReaderAdapter.formatPassageCitation', () {
    test(
      'formats single-chapter single-verse and range in Vulgate, Modern, and Dual',
      () {
        // Identical numbering in Vulgate and Modern (Genesis 1:1-3)
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 1,
            bookName: 'Genesis',
            startChapter: 1,
            startVerse: 1,
            endChapter: 1,
            endVerse: 1,
            numberingSystem: BibleNumberingSystem.vulgate,
          ),
          'Genesis 1:1',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 1,
            bookName: 'Genesis',
            startChapter: 1,
            startVerse: 1,
            endChapter: 1,
            endVerse: 3,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          'Genesis 1:1-3',
        );

        // Divergent numbering (Vg Psalm 22:1-2 -> Modern Psalm 23:1-2)
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 22,
            startVerse: 1,
            endChapter: 22,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.vulgate,
          ),
          'Psalms 22:1-2',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 22,
            startVerse: 1,
            endChapter: 22,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.modern,
          ),
          'Psalms 23:1-2',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 22,
            startVerse: 1,
            endChapter: 22,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          'Psalms 22:1-2 (Modern 23:1-2)',
        );
      },
    );

    test('formats cross-chapter ranges in Vulgate, Modern, and Dual', () {
      // Single Vulgate chapter (Exodus 8:1-6) that spans Modern 7:26-8:2
      expect(
        BibleReaderAdapter.formatPassageCitation(
          bookNumber: 2,
          bookName: 'Exodus',
          startChapter: 8,
          startVerse: 1,
          endChapter: 8,
          endVerse: 6,
          numberingSystem: BibleNumberingSystem.modern,
        ),
        'Exodus 7:26-8:2',
      );
      expect(
        BibleReaderAdapter.formatPassageCitation(
          bookNumber: 2,
          bookName: 'Exodus',
          startChapter: 8,
          startVerse: 1,
          endChapter: 8,
          endVerse: 6,
          numberingSystem: BibleNumberingSystem.dual,
        ),
        'Exodus 8:1-6 (Modern 7:26-8:2)',
      );

      // Explicit cross-chapter Vulgate range (Genesis 1:31-2:2)
      expect(
        BibleReaderAdapter.formatPassageCitation(
          bookNumber: 1,
          bookName: 'Genesis',
          startChapter: 1,
          startVerse: 31,
          endChapter: 2,
          endVerse: 2,
          numberingSystem: BibleNumberingSystem.vulgate,
        ),
        'Genesis 1:31-2:2',
      );
    });
  });

  group('BibleReaderAdapter instance delegation & formatVersesForClipboard', () {
    final psalmsBook = catholicBooks.firstWhere((b) => b.bookNumber == 21);

    test('formatSelectionCitation delegates to formatPassageCitation', () {
      final adapter = BibleReaderAdapter(
        bibleBook: psalmsBook,
        dbHelper: testDb,
      );

      expect(adapter.formatSelectionCitation(22, 1, 1), 'Psalms 22:1');
      expect(
        adapter.formatSelectionCitation(
          22,
          1,
          3,
          numberingSystem: BibleNumberingSystem.modern,
        ),
        'Psalms 23:1-3',
      );
      expect(
        adapter.formatSelectionCitation(
          22,
          1,
          3,
          numberingSystem: BibleNumberingSystem.dual,
        ),
        'Psalms 22:1-3 (Modern 23:1-3)',
      );
    });

    test(
      'formatVersesForClipboard and formatClipboardContent format single and multi-verse selections',
      () {
        final adapter = BibleReaderAdapter(
          bibleBook: catholicBooks.firstWhere((b) => b.bookNumber == 20), // Job
          dbHelper: testDb,
        );

        const v34 = BibleVerse(
          id: 1,
          bookNumber: 20,
          bookName: 'Job',
          chapter: 39,
          verseNumber: 34,
          verseText: 'What could I possibly answer?',
          translationCode: 'CPDV',
        );
        const v35 = BibleVerse(
          id: 2,
          bookNumber: 0, // exercise fallbackBookNumber
          bookName: 'Job',
          chapter: 39,
          verseNumber: 35,
          verseText: 'One thing I have spoken.',
          translationCode: 'CPDV',
        );

        // Single verse omits verse number prefix
        expect(
          adapter.formatClipboardContent('Job 39:34', const [
            v34,
          ], numberingSystem: BibleNumberingSystem.vulgate),
          'Job 39:34\nWhat could I possibly answer?',
        );

        // Multi-verse in Dual includes alternate Modern verse numbers
        expect(
          adapter.formatClipboardContent('Job 39:34-35 (Modern 40:4-5)', const [
            v34,
            v35,
          ], numberingSystem: BibleNumberingSystem.dual),
          'Job 39:34-35 (Modern 40:4-5)\n'
          '34 (40:4) What could I possibly answer?\n'
          '35 (40:5) One thing I have spoken.',
        );

        // Multi-verse in Modern uses Modern display numbers
        expect(
          BibleReaderAdapter.formatVersesForClipboard(
            citation: 'Job 40:4-5',
            verses: const [v34, v35],
            numberingSystem: BibleNumberingSystem.modern,
            fallbackBookNumber: 20,
          ),
          'Job 40:4-5\n'
          '4 What could I possibly answer?\n'
          '5 One thing I have spoken.',
        );
      },
    );
  });

  group('BibleAnnotationItem.formatCitation & citation getter', () {
    final psalmFavItem = BibleAnnotationItem(
      bookNumber: 21,
      bookName: 'Psalms',
      chapter: 22,
      startVerse: 1,
      endVerse: 3,
      textPreview: 'The Lord ruleth me: and I shall want nothing.',
      type: BibleAnnotationType.favorite,
      createdAt: DateTime(2026, 1, 1),
    );

    test(
      'formatCitation formats according to explicit BibleNumberingSystem',
      () {
        expect(
          psalmFavItem.formatCitation(BibleNumberingSystem.vulgate),
          'Psalms 22:1-3',
        );
        expect(
          psalmFavItem.formatCitation(BibleNumberingSystem.modern),
          'Psalms 23:1-3',
        );
        expect(
          psalmFavItem.formatCitation(BibleNumberingSystem.dual),
          'Psalms 22:1-3 (Modern 23:1-3)',
        );
      },
    );

    test(
      'citation getter uses UserSettingsController when initialized and defaults to vulgate otherwise',
      () async {
        expect(UserSettingsController.instance.isInitialized, isFalse);
        expect(psalmFavItem.citation, 'Psalms 22:1-3');

        await UserSettingsController.instance.update(
          UserSettings(bibleNumberingSystemCode: 'dual'),
        );
        expect(UserSettingsController.instance.isInitialized, isTrue);
        expect(psalmFavItem.citation, 'Psalms 22:1-3 (Modern 23:1-3)');
      },
    );
  });

  group('LibraryScriptureModal reuses BibleVerseRow', () {
    testWidgets(
      'renders BibleVerseRow widgets with target selection and dual numbering',
      (tester) async {
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

        const citation = BibleCitation(
          rawMatch: 'Job 40:4',
          displayLabel: 'Job 40:4',
          bookNumber: 20,
          bookName: 'Job',
          chapter: 40,
          verse: 4,
          abbrev: 'JOB',
          verseSystem: 'modern',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLibraryScriptureModal(
                    context: context,
                    citation: citation,
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        final rows = tester
            .widgetList<BibleVerseRow>(find.byType(BibleVerseRow))
            .toList();
        expect(rows, hasLength(2));

        expect(rows[0].verseNumber, 33);
        expect(rows[0].alternateVerseNumber, '40:3');
        expect(rows[0].isSelected, isFalse);
        expect(
          rows[0].padding,
          const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        );

        expect(rows[1].verseNumber, 34);
        expect(rows[1].alternateVerseNumber, '40:4');
        expect(rows[1].isSelected, isTrue);
        expect(rows[1].verseText, 'What could I possibly answer?');
      },
    );
  });
}
