import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';

void main() {
  group('BibleCitationParser Unit Tests', () {
    test('parses standard Old Testament citation', () {
      final segments = BibleCitationParser.parse(
        'Read Genesis (Gen. 3:15) for context.',
      );
      expect(segments.length, 3);
      expect(segments[0].isCitation, false);
      expect(segments[0].text, 'Read Genesis ');
      expect(segments[1].isCitation, true);
      expect(segments[1].citation!.bookName, 'Genesis');
      expect(segments[1].citation!.chapter, 3);
      expect(segments[1].citation!.verse, 15);
      expect(segments[1].citation!.displayLabel, 'Genesis 3:15');
      expect(segments[2].isCitation, false);
      expect(segments[2].text, ' for context.');
    });

    test('parses verse range citation', () {
      final segments = BibleCitationParser.parse(
        'See (Matt. 4:2-4) in scripture.',
      );
      expect(segments.length, 3);
      final cit = segments[1].citation!;
      expect(cit.bookName, 'Matthew');
      expect(cit.chapter, 4);
      expect(cit.verse, 2);
      expect(cit.endVerse, 4);
      expect(cit.displayLabel, 'Matthew 4:2-4');
    });

    test('parses traditional Roman numeral citation', () {
      final segments = BibleCitationParser.parse('As noted in (Apoc. xii. 1).');
      expect(segments.length, 3);
      final cit = segments[1].citation!;
      expect(cit.bookName, 'Revelation');
      expect(cit.chapter, 12);
      expect(cit.verse, 1);
      expect(cit.displayLabel, 'Revelation 12:1');
    });

    test('parses Deuterocanonical book citations', () {
      final wisdom = BibleCitationParser.parse('(Wisd. 2:12)');
      expect(wisdom.first.citation!.bookName, 'Wisdom');

      final sirach = BibleCitationParser.parse('(Ecclus. 3:1)');
      expect(sirach.first.citation!.bookName, 'Sirach');

      final maccabees = BibleCitationParser.parse('(1 Mach. 2:14)');
      expect(maccabees.first.citation!.bookName, '1 Maccabees');
    });

    test('handles text with no citations gracefully', () {
      final segments = BibleCitationParser.parse(
        'This is a plain sentence with no scripture references.',
      );
      expect(segments.length, 1);
      expect(segments[0].isCitation, false);
      expect(
        segments[0].text,
        'This is a plain sentence with no scripture references.',
      );
    });

    test('parses multiple citations in single paragraph', () {
      final text = 'Compare (Gen. 3:15) with (Luke 1:28) and (John 19:28).';
      final segments = BibleCitationParser.parse(text);
      final citations = segments
          .where((s) => s.isCitation)
          .map((s) => s.citation!)
          .toList();

      expect(citations.length, 3);
      expect(citations[0].displayLabel, 'Genesis 3:15');
      expect(citations[1].displayLabel, 'Luke 1:28');
      expect(citations[2].displayLabel, 'John 19:28');
    });

    test('parses entire chapter citations', () {
      final segments = BibleCitationParser.parse(
        'Read the story of Babel in (Gen. 11) or see (Matt 4).',
      );
      final citations = segments
          .where((s) => s.isCitation)
          .map((s) => s.citation!)
          .toList();

      expect(citations.length, 2);
      expect(citations[0].bookName, 'Genesis');
      expect(citations[0].chapter, 11);
      expect(citations[0].verse, null);
      expect(citations[0].isEntireChapter, true);
      expect(citations[0].displayLabel, 'Genesis 11');

      expect(citations[1].bookName, 'Matthew');
      expect(citations[1].chapter, 4);
      expect(citations[1].verse, null);
      expect(citations[1].isEntireChapter, true);
      expect(citations[1].displayLabel, 'Matthew 4');
    });

    test('parses New Testament epistle citations correctly', () {
      final epistles = <String, Map<String, dynamic>>{
        '(1 Tim. 2:5)': {'bookName': '1 Timothy', 'bookNumber': 64},
        '(2 Tim. 1:7)': {'bookName': '2 Timothy', 'bookNumber': 65},
        '(Titus 1:1)': {'bookName': 'Titus', 'bookNumber': 66},
        '(Philem. 1:4)': {'bookName': 'Philemon', 'bookNumber': 67},
        '(Heb. 11:1)': {'bookName': 'Hebrews', 'bookNumber': 68},
        '(James 1:5)': {'bookName': 'James', 'bookNumber': 69},
        '(1 Pet. 5:7)': {'bookName': '1 Peter', 'bookNumber': 70},
        '(2 Pet. 3:9)': {'bookName': '2 Peter', 'bookNumber': 71},
        '(1 John 4:8)': {'bookName': '1 John', 'bookNumber': 72},
        '(2 John 1:3)': {'bookName': '2 John', 'bookNumber': 73},
        '(3 John 1:4)': {'bookName': '3 John', 'bookNumber': 74},
        '(Jude 1:20)': {'bookName': 'Jude', 'bookNumber': 75},
      };

      for (final entry in epistles.entries) {
        final segments = BibleCitationParser.parse(entry.key);
        expect(segments.length, 1, reason: 'Failed parsing ${entry.key}');
        expect(segments.first.isCitation, true);
        final cit = segments.first.citation!;
        expect(
          cit.bookName,
          entry.value['bookName'],
          reason: 'Wrong bookName for ${entry.key}',
        );
        expect(
          cit.bookNumber,
          entry.value['bookNumber'],
          reason: 'Wrong bookNumber for ${entry.key}',
        );
      }
    });

    group('Negative Test Cases (False Positive Prevention)', () {
      test('does not parse Latin and devotional phrases as citations', () {
        final phrases = [
          'Ave Maria',
          'Stabat Mater',
          'Gloria in excelsis',
          'Te Deum',
        ];

        for (final phrase in phrases) {
          final segments = BibleCitationParser.parse(phrase);
          expect(
            segments.length,
            1,
            reason: 'Should return single text segment for "$phrase"',
          );
          expect(
            segments.first.isCitation,
            false,
            reason: 'Should not identify citation in "$phrase"',
          );
          expect(segments.first.text, phrase);
        }
      });

      test('does not match words with book prefixes', () {
        final phrases = [
          'Marian devotion',
          'Marked text',
          'Job hunting',
          'Romans conquered',
          'Genesis of life',
          'Wisdom is useful',
          'Acts of kindness',
        ];

        for (final phrase in phrases) {
          final segments = BibleCitationParser.parse(phrase);
          expect(
            segments.length,
            1,
            reason: 'Should not create citation for "$phrase"',
          );
          expect(segments.first.isCitation, false);
          expect(segments.first.text, phrase);
        }
      });

      test('rejects out-of-bounds chapter citations against metadata', () {
        final outOfBounds = [
          'Mark 25:1', // Mark has 16 chapters
          'Jude 2:1', // Jude has 1 chapter
          'Obadiah 5:1', // Obadiah has 1 chapter
        ];

        for (final phrase in outOfBounds) {
          final segments = BibleCitationParser.parse(phrase);
          expect(
            segments.length,
            1,
            reason: 'Should reject out-of-bounds citation "$phrase"',
          );
          expect(segments.first.isCitation, false);
          expect(segments.first.text, phrase);
        }
      });

      test('rejects non-citation dates and numbers', () {
        const dateText = 'Mar. 15, 2024';
        final segments = BibleCitationParser.parse(dateText);
        expect(segments.length, 1);
        expect(segments.first.isCitation, false);
        expect(segments.first.text, dateText);
      });
    });

    group('Positive Test Cases (Valid Citations Retained)', () {
      test('parses standard citations accurately', () {
        final cases = <String, Map<String, dynamic>>{
          'Gen. 3:15': {
            'bookName': 'Genesis',
            'chapter': 3,
            'verse': 15,
            'endVerse': null,
            'displayLabel': 'Genesis 3:15',
          },
          'Matt. 4:2-4': {
            'bookName': 'Matthew',
            'chapter': 4,
            'verse': 2,
            'endVerse': 4,
            'displayLabel': 'Matthew 4:2-4',
          },
          'John 3:16': {
            'bookName': 'John',
            'chapter': 3,
            'verse': 16,
            'endVerse': null,
            'displayLabel': 'John 3:16',
          },
          '1 Cor. 13:4-8': {
            'bookName': '1 Corinthians',
            'chapter': 13,
            'verse': 4,
            'endVerse': 8,
            'displayLabel': '1 Corinthians 13:4-8',
          },
        };

        for (final entry in cases.entries) {
          final segments = BibleCitationParser.parse(entry.key);
          expect(segments.length, 1);
          expect(segments.first.isCitation, true);
          final cit = segments.first.citation!;
          expect(cit.bookName, entry.value['bookName']);
          expect(cit.chapter, entry.value['chapter']);
          expect(cit.verse, entry.value['verse']);
          expect(cit.endVerse, entry.value['endVerse']);
          expect(cit.displayLabel, entry.value['displayLabel']);
        }
      });

      test('parses various Roman numeral formats', () {
        final cases = <String, Map<String, dynamic>>{
          'Apoc. xii. 1': {
            'bookName': 'Revelation',
            'chapter': 12,
            'verse': 1,
            'displayLabel': 'Revelation 12:1',
          },
          'Matt. iv. 2': {
            'bookName': 'Matthew',
            'chapter': 4,
            'verse': 2,
            'displayLabel': 'Matthew 4:2',
          },
          'Ps. xxiii': {
            'bookName': 'Psalms',
            'chapter': 23,
            'verse': null,
            'displayLabel': 'Psalms 23',
          },
          'John iii. 16': {
            'bookName': 'John',
            'chapter': 3,
            'verse': 16,
            'displayLabel': 'John 3:16',
          },
        };

        for (final entry in cases.entries) {
          final segments = BibleCitationParser.parse(entry.key);
          expect(segments.length, 1, reason: 'Failed parsing ${entry.key}');
          expect(segments.first.isCitation, true);
          final cit = segments.first.citation!;
          expect(cit.bookName, entry.value['bookName']);
          expect(cit.chapter, entry.value['chapter']);
          expect(cit.verse, entry.value['verse']);
          expect(cit.displayLabel, entry.value['displayLabel']);
        }
      });

      test('parses Deuterocanonical book citations', () {
        final cases = <String, Map<String, dynamic>>{
          'Wisd. 2:12': {
            'bookName': 'Wisdom',
            'chapter': 2,
            'verse': 12,
            'endVerse': null,
            'displayLabel': 'Wisdom 2:12',
          },
          'Ecclus. 3:1': {
            'bookName': 'Sirach',
            'chapter': 3,
            'verse': 1,
            'endVerse': null,
            'displayLabel': 'Sirach 3:1',
          },
          '1 Mach. 2:14': {
            'bookName': '1 Maccabees',
            'chapter': 2,
            'verse': 14,
            'endVerse': null,
            'displayLabel': '1 Maccabees 2:14',
          },
          '2 Mach. 7:1-5': {
            'bookName': '2 Maccabees',
            'chapter': 7,
            'verse': 1,
            'endVerse': 5,
            'displayLabel': '2 Maccabees 7:1-5',
          },
        };

        for (final entry in cases.entries) {
          final segments = BibleCitationParser.parse(entry.key);
          expect(segments.length, 1, reason: 'Failed parsing ${entry.key}');
          expect(segments.first.isCitation, true);
          final cit = segments.first.citation!;
          expect(cit.bookName, entry.value['bookName']);
          expect(cit.chapter, entry.value['chapter']);
          expect(cit.verse, entry.value['verse']);
          expect(cit.endVerse, entry.value['endVerse']);
          expect(cit.displayLabel, entry.value['displayLabel']);
        }
      });

      test('parses punctuation and dash variants correctly', () {
        // En-dash and em-dash
        final enDashSegments = BibleCitationParser.parse('Matt. 4:2–4');
        expect(enDashSegments.first.isCitation, true);
        expect(enDashSegments.first.citation!.displayLabel, 'Matthew 4:2-4');

        final emDashSegments = BibleCitationParser.parse('Matt. 4:2—4');
        expect(emDashSegments.first.isCitation, true);
        expect(emDashSegments.first.citation!.displayLabel, 'Matthew 4:2-4');

        // Colon, dot, comma
        final colonSegments = BibleCitationParser.parse('Luke 1:28');
        expect(colonSegments.first.isCitation, true);
        expect(colonSegments.first.citation!.displayLabel, 'Luke 1:28');

        final dotSegments = BibleCitationParser.parse('Luke 1.28');
        expect(dotSegments.first.isCitation, true);
        expect(dotSegments.first.citation!.displayLabel, 'Luke 1:28');

        final commaSegments = BibleCitationParser.parse('Luke 1, 28');
        expect(commaSegments.first.isCitation, true);
        expect(commaSegments.first.citation!.displayLabel, 'Luke 1:28');
      });

      test('parses parenthetical and embedded citations', () {
        final parenthetical = BibleCitationParser.parse('(Luke 1:28)');
        expect(parenthetical.first.isCitation, true);
        expect(parenthetical.first.citation!.displayLabel, 'Luke 1:28');
        expect(parenthetical.first.citation!.rawMatch, '(Luke 1:28)');

        final embedded = BibleCitationParser.parse(
          'see John 19:28 for context',
        );
        expect(embedded.length, 3);
        expect(embedded[0].text, 'see ');
        expect(embedded[1].isCitation, true);
        expect(embedded[1].citation!.displayLabel, 'John 19:28');
        expect(embedded[2].text, ' for context');
      });

      test('parses common Catholic book abbreviations', () {
        final aliases = <String, String>{
          'Mk 1:1': 'Mark 1:1',
          'Mt 4:2': 'Matthew 4:2',
          'Lk 1:28': 'Luke 1:28',
          'Jn 3:16': 'John 3:16',
          'Phil 2:5': 'Philippians 2:5',
          '1 Thess 5:16': '1 Thessalonians 5:16',
        };

        for (final entry in aliases.entries) {
          final segments = BibleCitationParser.parse(entry.key);
          expect(segments.length, 1, reason: 'Failed parsing ${entry.key}');
          expect(segments.first.isCitation, true);
          expect(segments.first.citation!.displayLabel, entry.value);
        }
      });
    });
  });
}
