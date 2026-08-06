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
  });
}
