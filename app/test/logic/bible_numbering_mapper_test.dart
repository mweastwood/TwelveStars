import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_numbering_mapper.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';

void main() {
  group('BibleVerseResolver.mapLectionaryToVulgateRanges', () {
    test(
      'returns both Vulgate Psalm ranges when a Masoretic Psalm spans two Vulgate Psalms',
      () {
        // Masoretic Psalm 116:1-19 spans Vulgate Psalm 114:1-9 and Psalm 115:1-10
        final ps116Ranges = BibleVerseResolver.mapLectionaryToVulgateRanges(
          bookNumber: 21,
          chapter: 116,
          verses: [for (int v = 1; v <= 19; v++) v],
        );
        expect(ps116Ranges.length, 2);
        expect(ps116Ranges[0].chapter, 114);
        expect(ps116Ranges[0].verses, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
        expect(ps116Ranges[1].chapter, 115);
        expect(ps116Ranges[1].verses, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

        // Masoretic Psalm 147:1-20 spans Vulgate Psalm 146:1-11 and Psalm 147:1-9
        final ps147Ranges = BibleVerseResolver.mapLectionaryToVulgateRanges(
          bookNumber: 21,
          chapter: 147,
          verses: [for (int v = 1; v <= 20; v++) v],
        );
        expect(ps147Ranges.length, 2);
        expect(ps147Ranges[0].chapter, 146);
        expect(ps147Ranges[0].verses, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
        expect(ps147Ranges[1].chapter, 147);
        expect(ps147Ranges[1].verses, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      },
    );

    test(
      'maps whole-chapter citations in shifted chapters to their proper Vulgate chapter',
      () {
        const expectedChapterMappings =
            <({int bookNumber, int modernChapter, int vulgateChapter})>[
              (
                bookNumber: 1,
                modernChapter: 32,
                vulgateChapter: 32,
              ), // Genesis 32
              (
                bookNumber: 5,
                modernChapter: 13,
                vulgateChapter: 13,
              ), // Deuteronomy 13
              (
                bookNumber: 5,
                modernChapter: 23,
                vulgateChapter: 23,
              ), // Deuteronomy 23
              (
                bookNumber: 9,
                modernChapter: 21,
                vulgateChapter: 21,
              ), // 1 Samuel 21
              (
                bookNumber: 10,
                modernChapter: 19,
                vulgateChapter: 19,
              ), // 2 Samuel 19
              (
                bookNumber: 12,
                modernChapter: 12,
                vulgateChapter: 12,
              ), // 2 Kings 12
              (
                bookNumber: 23,
                modernChapter: 5,
                vulgateChapter: 5,
              ), // Ecclesiastes 5
              (
                bookNumber: 33,
                modernChapter: 12,
                vulgateChapter: 12,
              ), // Hosea 12
              (bookNumber: 34, modernChapter: 3, vulgateChapter: 2), // Joel 3
              (bookNumber: 34, modernChapter: 4, vulgateChapter: 3), // Joel 4
              (bookNumber: 39, modernChapter: 2, vulgateChapter: 2), // Nahum 2
              (bookNumber: 50, modernChapter: 9, vulgateChapter: 9), // Mark 9
            ];

        for (final tc in expectedChapterMappings) {
          final ranges = BibleVerseResolver.mapLectionaryToVulgateRanges(
            bookNumber: tc.bookNumber,
            chapter: tc.modernChapter,
            verses: const [],
          );
          expect(
            ranges.length,
            1,
            reason:
                'Expected single range for book ${tc.bookNumber} ch ${tc.modernChapter}',
          );
          expect(
            ranges.first.chapter,
            tc.vulgateChapter,
            reason:
                'Book ${tc.bookNumber} whole-chapter ${tc.modernChapter} should map to Vulgate ${tc.vulgateChapter}',
          );
          expect(ranges.first.verses, isEmpty);
        }
      },
    );
  });

  group('ReverseCitationService whole-chapter and Joel 4 indexing', () {
    setUp(ReverseCitationService.clear);
    tearDown(ReverseCitationService.clear);

    test(
      'indexes modern whole-chapter citations in shifted chapters to their proper Vulgate chapter',
      () {
        final bookData = ParsedBookData.fromJson({
          'book_id': 'test_modern_book',
          'title': 'Test Modern Book',
          'subtitle': '',
          'author': 'Test Author',
          'verse_system': 'modern',
          'toc': [],
          'sections': [
            {
              'id': 'sec_1',
              'title': 'Section 1',
              'content': [
                {
                  'type': 'paragraph',
                  'text':
                      'See Genesis 32; Deuteronomy 13; Deuteronomy 23; 1 Samuel 21; '
                      '2 Samuel 19; 2 Kings 12; Ecclesiastes 5; Hosea 12; Nahum 2; '
                      'Mark 9; and Joel 4 for whole-chapter references, as well as Joel 4:1-2.',
                },
              ],
            },
          ],
        });

        ReverseCitationService.indexBookData('test_modern_book.json', bookData);

        expect(ReverseCitationService.getChapterCitations(1, 32), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(1, 31), isEmpty);

        expect(ReverseCitationService.getChapterCitations(5, 13), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(5, 12), isEmpty);

        expect(ReverseCitationService.getChapterCitations(5, 23), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(5, 22), isEmpty);

        expect(ReverseCitationService.getChapterCitations(9, 21), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(9, 20), isEmpty);

        expect(ReverseCitationService.getChapterCitations(10, 19), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(10, 18), isEmpty);

        expect(ReverseCitationService.getChapterCitations(12, 12), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(12, 11), isEmpty);

        expect(ReverseCitationService.getChapterCitations(23, 5), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(23, 4), isEmpty);

        expect(ReverseCitationService.getChapterCitations(33, 12), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(33, 11), isEmpty);

        expect(ReverseCitationService.getChapterCitations(39, 2), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(39, 1), isEmpty);

        expect(ReverseCitationService.getChapterCitations(50, 9), isNotEmpty);
        expect(ReverseCitationService.getChapterCitations(50, 8), isEmpty);

        // Joel 4 maps to Vulgate Joel 3
        expect(ReverseCitationService.getChapterCitations(34, 3), isNotEmpty);
        expect(ReverseCitationService.getVerseCitations(34, 3, 1), isNotEmpty);
        expect(ReverseCitationService.getVerseCitations(34, 3, 2), isNotEmpty);
      },
    );
  });
}
