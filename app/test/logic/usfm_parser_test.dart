import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';

void main() {
  group('UsfmParser Unit Tests', () {
    test('Correctly parses simple USFM files into structured verses', () {
      const usfm = '''
\\id GEN
\\h Genesis
\\c 1
\\p
\\v 1 In the beginning God created heaven, and earth.
\\v 2 And the earth was void and empty.
\\c 2
\\v 1 So the heavens and the earth were finished.
''';

      final results = UsfmParser.parse(usfm, 'CPDV', 1, 'Genesis');

      expect(results.length, equals(3));

      // Verse 1
      expect(results[0]['bookNumber'], equals(1));
      expect(results[0]['bookName'], equals('Genesis'));
      expect(results[0]['chapter'], equals(1));
      expect(results[0]['verseNumber'], equals(1));
      expect(
        results[0]['verseText'],
        equals('In the beginning God created heaven, and earth.'),
      );
      expect(results[0]['translationCode'], equals('CPDV'));

      // Verse 2
      expect(results[1]['chapter'], equals(1));
      expect(results[1]['verseNumber'], equals(2));
      expect(
        results[1]['verseText'],
        equals('And the earth was void and empty.'),
      );

      // Verse 3 (Genesis 2:1)
      expect(results[2]['chapter'], equals(2));
      expect(results[2]['verseNumber'], equals(1));
      expect(
        results[2]['verseText'],
        equals('So the heavens and the earth were finished.'),
      );
    });

    test('Strips inline formatting and footnotes from verses', () {
      const usfm = r'''
\c 1
\v 1 In the beginning \nd Lord\nd* created the heavens.
\v 2 And the \add earth\add* was empty\f + This is a footnote \f*.
''';

      final results = UsfmParser.parse(usfm, 'CPDV', 1, 'Genesis');

      expect(results.length, equals(2));

      // Check formatting strip
      expect(
        results[0]['verseText'],
        equals('In the beginning Lord created the heavens.'),
      );

      // Check footnote strip
      expect(results[1]['verseText'], equals('And the earth was empty.'));
    });

    test('Handles empty and invalid USFM inputs gracefully', () {
      final emptyResult = UsfmParser.parse('', 'CPDV', 1, 'Genesis');
      expect(emptyResult, isEmpty);

      final invalidResult = UsfmParser.parse(
        '\\some random tag\n\\v abc invalid text',
        'CPDV',
        1,
        'Genesis',
      );
      expect(invalidResult, isEmpty);
    });
  });
}
