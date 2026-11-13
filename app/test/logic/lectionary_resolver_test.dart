import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';

void main() {
  group(
    'cleanVerseStr and resolveReadingRanges for "and", "&", and suffixes',
    () {
      test(
        'cleanVerseStr normalizes "and", "&", and letter-separated ranges',
        () {
          expect(cleanVerseStr('1a and 2-8'), '1,2-8');
          expect(cleanVerseStr('1a AND 2-8'), '1,2-8');
          expect(
            cleanVerseStr('1-3, 16-18, 21-22 and 24'),
            '1-3, 16-18, 21-22,24',
          );
          expect(cleanVerseStr('3 & 4bc, 6c-7, 8'), '3 , 4, 6-7, 8');
          expect(cleanVerseStr('1-2, 3, 4 & 6'), '1-2, 3, 4 , 6');
          expect(cleanVerseStr('1 and 9, 10-11, 12-13ab'), '1,9, 10-11, 12-13');
          expect(
            cleanVerseStr('1-2 and 4, 22-24, 25-27a'),
            '1-2,4, 22-24, 25-27',
          );
          expect(cleanVerseStr(' 1-3a, 3b-4, 5, 6'), '1-3, 3-4, 5, 6');
          expect(cleanVerseStr(' 1-3a, 3b4, 5, 6'), '1-3, 3-4, 5, 6');
        },
      );

      test('resolveReadingRanges handles John 20:1a and 2-8', () {
        final ranges = resolveReadingRanges(
          bookNumber: 52,
          defaultChapter: 20,
          defaultVerseRange: '1a and 2-8',
          citation: 'John 20:1a and 2-8',
        );
        expect(ranges, [
          const ChapterVerseRange(
            chapter: 20,
            verses: [1, 2, 3, 4, 5, 6, 7, 8],
          ),
        ]);
      });

      test(
        'resolveReadingRanges handles Psalm 136:1-3, 16-18, 21-22 and 24',
        () {
          final ranges = resolveReadingRanges(
            bookNumber: 21,
            defaultChapter: 136,
            defaultVerseRange: '1-3, 16-18, 21-22 and 24',
            citation: 'Psalm 136:1-3, 16-18, 21-22 and 24',
          );
          expect(ranges, [
            const ChapterVerseRange(
              chapter: 135,
              verses: [1, 2, 3, 16, 17, 18, 21, 22, 24],
            ),
          ]);
        },
      );

      test('resolveReadingRanges handles Psalm 78:3 & 4bc, 6c-7, 8', () {
        final ranges = resolveReadingRanges(
          bookNumber: 21,
          defaultChapter: 78,
          defaultVerseRange: '3 & 4bc, 6c-7, 8',
          citation: 'Psalm 78:3 & 4bc, 6c-7, 8',
        );
        expect(ranges, [
          const ChapterVerseRange(chapter: 77, verses: [3, 4, 6, 7, 8]),
        ]);
      });

      test(
        'resolveReadingRanges handles Psalm 145:1 and 9, 10-11, 12-13ab',
        () {
          final ranges = resolveReadingRanges(
            bookNumber: 21,
            defaultChapter: 145,
            defaultVerseRange: '1 and 9, 10-11, 12-13ab',
            citation: 'Psalm 145:1 and 9, 10-11, 12-13ab',
          );
          expect(ranges, [
            const ChapterVerseRange(
              chapter: 144,
              verses: [1, 9, 10, 11, 12, 13],
            ),
          ]);
        },
      );

      test(
        'resolveReadingRanges handles Psalm 118:1-2 and 4, 22-24, 25-27a',
        () {
          final ranges = resolveReadingRanges(
            bookNumber: 21,
            defaultChapter: 118,
            defaultVerseRange: '1-2 and 4, 22-24, 25-27a',
            citation: 'Psalm 118:1-2 and 4, 22-24, 25-27a',
          );
          expect(ranges, [
            const ChapterVerseRange(
              chapter: 117,
              verses: [1, 2, 4, 22, 23, 24, 25, 26, 27],
            ),
          ]);
        },
      );

      test(
        'resolveReadingRanges handles season_easter_4_sunday_a (Psalm 23: 1-3a, 3b-4, 5, 6)',
        () {
          final ranges = resolveReadingRanges(
            bookNumber: 21,
            defaultChapter: 23,
            defaultVerseRange: ' 1-3a, 3b-4, 5, 6',
            citation: 'Psalm 23: 1-3a, 3b-4, 5, 6',
          );
          expect(ranges, [
            const ChapterVerseRange(chapter: 22, verses: [1, 2, 3, 3, 4, 5, 6]),
          ]);
        },
      );
    },
  );

  group('Cross-chapter citations with comma in ending chapter', () {
    test('Mal 1:14b-2:2b, 8-10 includes verse 1 of chapter 2', () {
      final ranges = resolveReadingRanges(
        bookNumber: 44, // Malachi
        defaultChapter: 1,
        defaultVerseRange: '14b-2',
        citation: 'Mal 1:14b-2:2b, 8-10',
      );
      expect(ranges, [
        const ChapterVerseRange(chapter: 1, startVerseLimit: 14),
        const ChapterVerseRange(chapter: 2, verses: [1, 2, 8, 9, 10]),
      ]);
    });
  });

  group('Semicolon-separated citations with whole-chapter segments', () {
    test(
      'Whole-chapter segment in semicolon citation returns verses: null',
      () {
        final ranges = resolveReadingRanges(
          bookNumber: 50, // Mark
          defaultChapter: 1,
          defaultVerseRange: 'all; 2:1-5',
          citation: 'Mark 1:all; 2:1-5',
        );
        expect(ranges, [
          const ChapterVerseRange(chapter: 1, verses: null),
          const ChapterVerseRange(chapter: 2, verses: [1, 2, 3, 4, 5]),
        ]);
      },
    );

    test(
      'Trailing whole-chapter segment in semicolon citation returns verses: null',
      () {
        final ranges = resolveReadingRanges(
          bookNumber: 50, // Mark
          defaultChapter: 1,
          defaultVerseRange: '1-5; 2:all',
          citation: 'Mark 1:1-5; 2:all',
        );
        expect(ranges, [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4, 5]),
          const ChapterVerseRange(chapter: 2, verses: null),
        ]);
      },
    );
  });

  group('Full lectionary.json validation', () {
    test(
      'All entries in lectionary.json resolve to non-empty ranges with valid verses (<= 200)',
      () {
        final file = File('assets/bible/lectionary.json');
        expect(file.existsSync(), isTrue);
        final List<dynamic> data =
            jsonDecode(file.readAsStringSync()) as List<dynamic>;
        expect(data, isNotEmpty);

        for (final raw in data) {
          final entry = raw as Map<String, dynamic>;
          final readingKey = entry['reading_key'] as String;
          final readingType = entry['reading_type'] as String;
          final bookNumber = entry['book_number'] as int;
          final chapter = entry['chapter'] as int;
          final verseRange = entry['verse_range'] as String;
          final citation = entry['citation'] as String;

          final ranges = resolveReadingRanges(
            bookNumber: bookNumber,
            defaultChapter: chapter,
            defaultVerseRange: verseRange,
            citation: citation,
          );

          expect(
            ranges,
            isNotEmpty,
            reason: 'Empty ranges for $readingKey ($readingType): $citation',
          );

          for (final range in ranges) {
            expect(
              range.chapter,
              greaterThan(0),
              reason:
                  'Invalid chapter for $readingKey ($readingType): $citation',
            );
            if (range.verses != null) {
              expect(
                range.verses,
                isNotEmpty,
                reason:
                    'Empty verses list (should be null for whole chapter) in $readingKey ($readingType): $citation',
              );
              for (final v in range.verses!) {
                expect(
                  v,
                  inInclusiveRange(1, 200),
                  reason:
                      'Out-of-bounds verse $v in $readingKey ($readingType): $citation (verse_range: $verseRange)',
                );
              }
            }
            if (range.startVerseLimit != null) {
              expect(
                range.startVerseLimit,
                inInclusiveRange(1, 200),
                reason:
                    'Out-of-bounds startVerseLimit in $readingKey ($readingType): $citation',
              );
            }
            if (range.endVerseLimit != null) {
              expect(
                range.endVerseLimit,
                inInclusiveRange(1, 200),
                reason:
                    'Out-of-bounds endVerseLimit in $readingKey ($readingType): $citation',
              );
            }
          }
        }
      },
    );

    test(
      'Every reading_key in lectionary.json has a first reading and a gospel',
      () {
        final file = File('assets/bible/lectionary.json');
        final List<dynamic> data =
            jsonDecode(file.readAsStringSync()) as List<dynamic>;

        final typesByKey = <String, Set<String>>{};
        for (final raw in data) {
          final entry = raw as Map<String, dynamic>;
          final readingKey = entry['reading_key'] as String;
          final readingType = entry['reading_type'] as String;
          typesByKey.putIfAbsent(readingKey, () => <String>{}).add(readingType);
        }

        for (final entry in typesByKey.entries) {
          expect(
            entry.value,
            contains('first'),
            reason: '${entry.key} is missing a first reading',
          );
          expect(
            entry.value,
            contains('gospel'),
            reason: '${entry.key} is missing a gospel reading',
          );
        }
      },
    );
  });
}
