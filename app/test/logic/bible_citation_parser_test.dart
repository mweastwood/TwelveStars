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
  });
}
