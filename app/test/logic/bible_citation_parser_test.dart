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

      test('parses bracketed dual notations accurately', () {
        // Single verse with bracketed dual notation
        final ps94 = BibleCitationParser.parse('Ps 94[95]:8');
        expect(ps94.length, 1);
        expect(ps94.first.isCitation, true);
        expect(ps94.first.citation!.bookName, 'Psalms');
        expect(ps94.first.citation!.chapter, 94);
        expect(ps94.first.citation!.verse, 8);
        expect(ps94.first.citation!.endVerse, isNull);
        expect(ps94.first.citation!.displayLabel, 'Psalms 94:8');
        expect(ps94.first.citation!.rawMatch, 'Ps 94[95]:8');

        // Another single verse bracketed dual citation
        final ps130 = BibleCitationParser.parse('Ps 130[131]:1');
        expect(ps130.length, 1);
        expect(ps130.first.isCitation, true);
        expect(ps130.first.citation!.bookName, 'Psalms');
        expect(ps130.first.citation!.chapter, 130);
        expect(ps130.first.citation!.verse, 1);
        expect(ps130.first.citation!.displayLabel, 'Psalms 130:1');
        expect(ps130.first.citation!.rawMatch, 'Ps 130[131]:1');

        // Verse range with bracketed dual notation
        final ps33 = BibleCitationParser.parse(
          '(Ps 33[34]:12-15)',
          verseSystem: 'dual',
        );
        expect(ps33.length, 1);
        expect(ps33.first.isCitation, true);
        expect(ps33.first.citation!.bookName, 'Psalms');
        expect(ps33.first.citation!.chapter, 33);
        expect(ps33.first.citation!.verse, 12);
        expect(ps33.first.citation!.endVerse, 15);
        expect(ps33.first.citation!.displayLabel, 'Psalms 33:12-15');
        expect(ps33.first.citation!.rawMatch, '(Ps 33[34]:12-15)');
        expect(ps33.first.citation!.verseSystem, 'dual');

        // Embedded in parenthesized text without space before colon
        final ps14 = BibleCitationParser.parse(
          'Lord, who shall rest in Thy holy hill (Ps 14[15]:1)?',
        );
        expect(ps14.length, 3);
        expect(ps14[0].text, 'Lord, who shall rest in Thy holy hill ');
        expect(ps14[1].isCitation, true);
        expect(ps14[1].citation!.chapter, 14);
        expect(ps14[1].citation!.verse, 1);
        expect(ps14[1].citation!.displayLabel, 'Psalms 14:1');
        expect(ps14[1].citation!.rawMatch, '(Ps 14[15]:1)');
        expect(ps14[2].text, '?');

        // Bracketed notation with chapter and verse inside brackets (e.g. Benedict Rule)
        final ps113 = BibleCitationParser.parse('(Ps 113[115:1]:9)');
        expect(ps113.length, 1);
        expect(ps113.first.isCitation, true);
        expect(ps113.first.citation!.bookName, 'Psalms');
        expect(ps113.first.citation!.chapter, 113);
        expect(ps113.first.citation!.verse, 9);
        expect(ps113.first.citation!.displayLabel, 'Psalms 113:9');
        expect(ps113.first.citation!.rawMatch, '(Ps 113[115:1]:9)');

        // Whole-chapter citation with bracketed alternate chapter
        final wholeChap = BibleCitationParser.parse('Ps 94[95]');
        expect(wholeChap.length, 1);
        expect(wholeChap.first.isCitation, true);
        expect(wholeChap.first.citation!.bookName, 'Psalms');
        expect(wholeChap.first.citation!.chapter, 94);
        expect(wholeChap.first.citation!.verse, isNull);
        expect(wholeChap.first.citation!.isEntireChapter, true);
        expect(wholeChap.first.citation!.displayLabel, 'Psalms 94');
        expect(wholeChap.first.citation!.rawMatch, 'Ps 94[95]');
      });
    });

    group('Didache Citation Detection & Non-False Positive Tests', () {
      test('does not misidentify Didache verse numbering as Bible citations', () {
        final verseTexts = [
          '1. There are two ways, one of life and one of death, and there is a great difference between the two ways.',
          '2. The way of life is this.',
          '3. First of all, thou shalt love the God that made thee;',
          '7. Bless them that curse you, and pray for your enemies and fast for them that persecute you;',
          '14. To every man that asketh of thee give, and ask not back;',
          '23. Let thine alms sweat into thine hands, until thou shalt have learnt to whom to give.',
        ];

        for (final text in verseTexts) {
          final segments = BibleCitationParser.parse(text);
          final citations = segments.where((s) => s.isCitation).toList();
          expect(
            citations,
            isEmpty,
            reason:
                'Verse number was falsely identified as citation in: "$text"',
          );
        }
      });

      test(
        'accurately detects scriptural citations embedded in Didache annotations',
        () {
          const textWithCitations =
              'As quoted in Didache 8:3 from (Matt. 6:9-13) and the Lord\'s prayer, '
              'as well as the Eucharistic warning (Matt. 7:6) and the prophecy of Malachi (Mal. 1:11).';

          final segments = BibleCitationParser.parse(textWithCitations);
          final citations = segments
              .where((s) => s.isCitation)
              .map((s) => s.citation!)
              .toList();

          expect(citations.length, 3);
          expect(citations[0].bookName, 'Matthew');
          expect(citations[0].chapter, 6);
          expect(citations[0].verse, 9);
          expect(citations[0].endVerse, 13);
          expect(citations[0].displayLabel, 'Matthew 6:9-13');

          expect(citations[1].bookName, 'Matthew');
          expect(citations[1].chapter, 7);
          expect(citations[1].verse, 6);
          expect(citations[1].displayLabel, 'Matthew 7:6');

          expect(citations[2].bookName, 'Malachi');
          expect(citations[2].chapter, 1);
          expect(citations[2].verse, 11);
          expect(citations[2].displayLabel, 'Malachi 1:11');
        },
      );
    });
  });

  group('BibleVerseResolver Unit Tests', () {
    test('vulgateToMasoreticPsalm maps boundary ranges correctly', () {
      // Pss 1–8: Identical
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(1), equals(1));
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(8), equals(8));

      // Ps 9: Combines Masoretic 9 & 10
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(9), equals(9));

      // Pss 10–112 (Vulgate) -> Pss 11–113 (Masoretic)
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(10), equals(11));
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(22), equals(23));
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(112), equals(113));

      // Ps 113 (Vulgate) -> Masoretic 114 & 115
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(113), equals(114));

      // Pss 114 & 115 (Vulgate) -> Ps 116 (Masoretic)
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(114), equals(116));
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(115), equals(116));

      // Pss 116–145 (Vulgate) -> Pss 117–146 (Masoretic)
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(116), equals(117));
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(145), equals(146));

      // Pss 146 & 147 (Vulgate) -> Ps 147 (Masoretic)
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(146), equals(147));
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(147), equals(147));

      // Pss 148–150: Identical
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(148), equals(148));
      expect(BibleVerseResolver.vulgateToMasoreticPsalm(150), equals(150));
    });

    test('masoreticToVulgatePsalm maps reverse boundary ranges correctly', () {
      // Pss 1–8: Identical
      expect(BibleVerseResolver.masoreticToVulgatePsalm(1), equals(1));
      expect(BibleVerseResolver.masoreticToVulgatePsalm(8), equals(8));

      // Masoretic 9 & 10 -> Vulgate 9
      expect(BibleVerseResolver.masoreticToVulgatePsalm(9), equals(9));
      expect(BibleVerseResolver.masoreticToVulgatePsalm(10), equals(9));

      // Pss 11–113 (Masoretic) -> Pss 10–112 (Vulgate)
      expect(BibleVerseResolver.masoreticToVulgatePsalm(11), equals(10));
      expect(BibleVerseResolver.masoreticToVulgatePsalm(23), equals(22));
      expect(BibleVerseResolver.masoreticToVulgatePsalm(113), equals(112));

      // Masoretic 114 & 115 -> Vulgate 113
      expect(BibleVerseResolver.masoreticToVulgatePsalm(114), equals(113));
      expect(BibleVerseResolver.masoreticToVulgatePsalm(115), equals(113));

      // Masoretic 116 -> Vulgate 114
      expect(BibleVerseResolver.masoreticToVulgatePsalm(116), equals(114));

      // Pss 117–146 (Masoretic) -> Pss 116–145 (Vulgate)
      expect(BibleVerseResolver.masoreticToVulgatePsalm(117), equals(116));
      expect(BibleVerseResolver.masoreticToVulgatePsalm(146), equals(145));

      // Masoretic 147 -> Vulgate 146
      expect(BibleVerseResolver.masoreticToVulgatePsalm(147), equals(146));

      // Pss 148–150: Identical
      expect(BibleVerseResolver.masoreticToVulgatePsalm(148), equals(148));
      expect(BibleVerseResolver.masoreticToVulgatePsalm(150), equals(150));
    });

    test('formatChapterTitle formats correctly across numbering systems', () {
      // Non-Psalm books should be unaffected
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          numberingSystem: BibleNumberingSystem.vulgate,
        ),
        equals('Genesis 1'),
      );
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          numberingSystem: BibleNumberingSystem.modern,
        ),
        equals('Genesis 1'),
      );
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          numberingSystem: BibleNumberingSystem.dual,
        ),
        equals('Genesis 1'),
      );

      // Psalms 1 (Identical across systems)
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 21,
          bookName: 'Psalms',
          chapter: 1,
          numberingSystem: BibleNumberingSystem.vulgate,
        ),
        equals('Psalms 1'),
      );
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 21,
          bookName: 'Psalms',
          chapter: 1,
          numberingSystem: BibleNumberingSystem.modern,
        ),
        equals('Psalms 1'),
      );
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 21,
          bookName: 'Psalms',
          chapter: 1,
          numberingSystem: BibleNumberingSystem.dual,
        ),
        equals('Psalms 1'),
      );

      // Psalm 22 (Vulgate 22 <-> Modern 23)
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 21,
          bookName: 'Psalms',
          chapter: 22,
          numberingSystem: BibleNumberingSystem.vulgate,
        ),
        equals('Psalms 22'),
      );
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 21,
          bookName: 'Psalms',
          chapter: 22,
          numberingSystem: BibleNumberingSystem.modern,
        ),
        equals('Psalms 23'),
      );
      expect(
        BibleVerseResolver.formatChapterTitle(
          bookNumber: 21,
          bookName: 'Psalms',
          chapter: 22,
          numberingSystem: BibleNumberingSystem.dual,
        ),
        equals('Psalms 22 (Modern 23)'),
      );
    });

    test('formatChapterPickerLabel formats picker buttons correctly', () {
      expect(
        BibleVerseResolver.formatChapterPickerLabel(
          bookNumber: 21,
          chapter: 22,
          numberingSystem: BibleNumberingSystem.vulgate,
        ),
        equals('22'),
      );
      expect(
        BibleVerseResolver.formatChapterPickerLabel(
          bookNumber: 21,
          chapter: 22,
          numberingSystem: BibleNumberingSystem.modern,
        ),
        equals('23'),
      );
      expect(
        BibleVerseResolver.formatChapterPickerLabel(
          bookNumber: 21,
          chapter: 22,
          numberingSystem: BibleNumberingSystem.dual,
        ),
        equals('22 (23)'),
      );
      expect(
        BibleVerseResolver.formatChapterPickerLabel(
          bookNumber: 21,
          chapter: 1,
          numberingSystem: BibleNumberingSystem.dual,
        ),
        equals('1'),
      );
    });

    test(
      'vulgateToMasoreticVerse maps Psalm verses accurately across boundaries',
      () {
        // Non-Psalm
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 1,
            chapter: 1,
            verse: 1,
          ),
          equals((chapter: 1, verse: 1)),
        );

        // Psalms 1-8: Identical
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 1,
            verse: 1,
          ),
          equals((chapter: 1, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 8,
            verse: 5,
          ),
          equals((chapter: 8, verse: 5)),
        );

        // Vulgate Psalm 9 (Verses 1-21 -> Masoretic Ps 9:1-21; Verses 22-39 -> Masoretic Ps 10:1-18)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 9,
            verse: 1,
          ),
          equals((chapter: 9, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 9,
            verse: 21,
          ),
          equals((chapter: 9, verse: 21)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 9,
            verse: 22,
          ),
          equals((chapter: 10, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 9,
            verse: 39,
          ),
          equals((chapter: 10, verse: 18)),
        );

        // Vulgate Psalm 22 -> Masoretic Psalm 23 (verses 1-6)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 22,
            verse: 1,
          ),
          equals((chapter: 23, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 22,
            verse: 6,
          ),
          equals((chapter: 23, verse: 6)),
        );

        // Vulgate Psalm 113 (Verses 1-8 -> Masoretic Ps 114:1-8; Verses 9-26 -> Masoretic Ps 115:1-18)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 113,
            verse: 1,
          ),
          equals((chapter: 114, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 113,
            verse: 8,
          ),
          equals((chapter: 114, verse: 8)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 113,
            verse: 9,
          ),
          equals((chapter: 115, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 113,
            verse: 26,
          ),
          equals((chapter: 115, verse: 18)),
        );

        // Vulgate Psalm 114 (Masoretic Ps 116:1-9)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 114,
            verse: 1,
          ),
          equals((chapter: 116, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 114,
            verse: 9,
          ),
          equals((chapter: 116, verse: 9)),
        );

        // Vulgate Psalm 115 (Masoretic Ps 116:10-19)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 115,
            verse: 1,
          ),
          equals((chapter: 116, verse: 10)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 115,
            verse: 10,
          ),
          equals((chapter: 116, verse: 19)),
        );

        // Vulgate Psalm 146 (Masoretic Ps 147:1-11)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 146,
            verse: 1,
          ),
          equals((chapter: 147, verse: 1)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 146,
            verse: 11,
          ),
          equals((chapter: 147, verse: 11)),
        );

        // Vulgate Psalm 147 (Masoretic Ps 147:12-20)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 147,
            verse: 1,
          ),
          equals((chapter: 147, verse: 12)),
        );
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 147,
            verse: 9,
          ),
          equals((chapter: 147, verse: 20)),
        );

        // Vulgate Psalm 150 (Identical)
        expect(
          BibleVerseResolver.vulgateToMasoreticVerse(
            bookNumber: 21,
            chapter: 150,
            verse: 6,
          ),
          equals((chapter: 150, verse: 6)),
        );
      },
    );

    test('masoreticToVulgateVerse maps Masoretic verses back accurately', () {
      // Masoretic Ps 10:1 -> Vulgate Ps 9:22
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 21,
          chapter: 10,
          verse: 1,
        ),
        equals((chapter: 9, verse: 22)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 21,
          chapter: 10,
          verse: 18,
        ),
        equals((chapter: 9, verse: 39)),
      );

      // Masoretic Ps 115:1 -> Vulgate Ps 113:9
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 21,
          chapter: 115,
          verse: 1,
        ),
        equals((chapter: 113, verse: 9)),
      );

      // Masoretic Ps 116:10 -> Vulgate Ps 115:1
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 21,
          chapter: 116,
          verse: 10,
        ),
        equals((chapter: 115, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 21,
          chapter: 116,
          verse: 19,
        ),
        equals((chapter: 115, verse: 10)),
      );

      // Masoretic Ps 147:12 -> Vulgate Ps 147:1
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 21,
          chapter: 147,
          verse: 12,
        ),
        equals((chapter: 147, verse: 1)),
      );
    });

    test(
      'formatVerseDisplay formats verse numbers across numbering systems correctly',
      () {
        // Non-Psalm: Genesis 1:1
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 1,
            chapter: 1,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.vulgate,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: null)),
        );
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 1,
            chapter: 1,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.modern,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: null)),
        );
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 1,
            chapter: 1,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: null)),
        );

        // Psalm 22:1 (verse numbers match between systems)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 21,
            chapter: 22,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: null)),
        );

        // Psalm 115:1 (Vulgate v1 -> Masoretic Ps 116:10)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 21,
            chapter: 115,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.vulgate,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: null)),
        );
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 21,
            chapter: 115,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.modern,
          ),
          equals((displayVerseNumber: 10, alternateVerseNumber: null)),
        );
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 21,
            chapter: 115,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: '10')),
        );

        // Psalm 115:10 (Vulgate v10 -> Masoretic Ps 116:19)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 21,
            chapter: 115,
            verseNumber: 10,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 10, alternateVerseNumber: '19')),
        );

        // Job 39:30 (matches)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 20,
            chapter: 39,
            verseNumber: 30,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 30, alternateVerseNumber: null)),
        );

        // Job 39:31 -> Modern 40:1 (cross-chapter)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 20,
            chapter: 39,
            verseNumber: 31,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 31, alternateVerseNumber: '40:1')),
        );
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 20,
            chapter: 39,
            verseNumber: 31,
            numberingSystem: BibleNumberingSystem.modern,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: null)),
        );

        // Job 40:1 -> Modern 40:6 (same chapter shift)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 20,
            chapter: 40,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: '6')),
        );

        // Job 40:20 -> Modern 41:1 (cross-chapter)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 20,
            chapter: 40,
            verseNumber: 20,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 20, alternateVerseNumber: '41:1')),
        );

        // Ecclesiastes 4:17 -> Modern 5:1 (cross-chapter)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 23,
            chapter: 4,
            verseNumber: 17,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 17, alternateVerseNumber: '5:1')),
        );

        // Ecclesiastes 5:1 -> Modern 5:2 (same chapter shift)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 23,
            chapter: 5,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: '2')),
        );

        // Jonah 2:1 -> Modern 1:17 (cross-chapter)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 37,
            chapter: 2,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: '1:17')),
        );

        // Hosea 14:1 -> Modern 13:16 (cross-chapter)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 33,
            chapter: 14,
            verseNumber: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 1, alternateVerseNumber: '13:16')),
        );

        // 1 Kings 22:44 -> Modern 22:43 (same chapter)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 11,
            chapter: 22,
            verseNumber: 44,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 44, alternateVerseNumber: '43')),
        );

        // 1 Kings 22:45 -> Modern 22:44 (same chapter)
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 11,
            chapter: 22,
            verseNumber: 45,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          equals((displayVerseNumber: 45, alternateVerseNumber: '44')),
        );
        expect(
          BibleVerseResolver.formatVerseDisplay(
            bookNumber: 11,
            chapter: 22,
            verseNumber: 45,
            numberingSystem: BibleNumberingSystem.modern,
          ),
          equals((displayVerseNumber: 44, alternateVerseNumber: null)),
        );
      },
    );

    test('bidirectional mappings for all divergent Old Testament books', () {
      // 1. Job (20)
      // Vulgate 39:31-35 -> Modern 40:1-5
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 39,
          verse: 31,
        ),
        equals((chapter: 40, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 39,
          verse: 35,
        ),
        equals((chapter: 40, verse: 5)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 20,
          chapter: 40,
          verse: 1,
        ),
        equals((chapter: 39, verse: 31)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 20,
          chapter: 40,
          verse: 5,
        ),
        equals((chapter: 39, verse: 35)),
      );

      // Vulgate 40:1-19 -> Modern 40:6-24
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 40,
          verse: 1,
        ),
        equals((chapter: 40, verse: 6)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 40,
          verse: 19,
        ),
        equals((chapter: 40, verse: 24)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 20,
          chapter: 40,
          verse: 6,
        ),
        equals((chapter: 40, verse: 1)),
      );

      // Vulgate 40:20-28 -> Modern 41:1-9
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 40,
          verse: 20,
        ),
        equals((chapter: 41, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 40,
          verse: 28,
        ),
        equals((chapter: 41, verse: 9)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 20,
          chapter: 41,
          verse: 1,
        ),
        equals((chapter: 40, verse: 20)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 20,
          chapter: 41,
          verse: 9,
        ),
        equals((chapter: 40, verse: 28)),
      );

      // Vulgate 41:1-25 -> Modern 41:10-34
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 41,
          verse: 1,
        ),
        equals((chapter: 41, verse: 10)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 20,
          chapter: 41,
          verse: 25,
        ),
        equals((chapter: 41, verse: 34)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 20,
          chapter: 41,
          verse: 10,
        ),
        equals((chapter: 41, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 20,
          chapter: 41,
          verse: 34,
        ),
        equals((chapter: 41, verse: 25)),
      );

      // 2. Ecclesiastes (23)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 23,
          chapter: 4,
          verse: 17,
        ),
        equals((chapter: 5, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 23,
          chapter: 5,
          verse: 1,
        ),
        equals((chapter: 4, verse: 17)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 23,
          chapter: 5,
          verse: 1,
        ),
        equals((chapter: 5, verse: 2)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 23,
          chapter: 5,
          verse: 19,
        ),
        equals((chapter: 5, verse: 20)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 23,
          chapter: 5,
          verse: 20,
        ),
        equals((chapter: 5, verse: 19)),
      );

      // 3. Canticle of Canticles (24)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 24,
          chapter: 7,
          verse: 1,
        ),
        equals((chapter: 6, verse: 13)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 24,
          chapter: 6,
          verse: 13,
        ),
        equals((chapter: 7, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 24,
          chapter: 7,
          verse: 2,
        ),
        equals((chapter: 7, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 24,
          chapter: 7,
          verse: 1,
        ),
        equals((chapter: 7, verse: 2)),
      );

      // 4. 1 Kings (11)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 11,
          chapter: 22,
          verse: 43,
        ),
        equals((chapter: 22, verse: 43)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 11,
          chapter: 22,
          verse: 44,
        ),
        equals((chapter: 22, verse: 43)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 11,
          chapter: 22,
          verse: 45,
        ),
        equals((chapter: 22, verse: 44)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 11,
          chapter: 22,
          verse: 54,
        ),
        equals((chapter: 22, verse: 53)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 11,
          chapter: 22,
          verse: 43,
        ),
        equals((chapter: 22, verse: 43)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 11,
          chapter: 22,
          verse: 44,
        ),
        equals((chapter: 22, verse: 45)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 11,
          chapter: 22,
          verse: 53,
        ),
        equals((chapter: 22, verse: 54)),
      );
      // Non-divergent chapters in 1 Kings remain identical in both directions
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 11,
          chapter: 3,
          verse: 1,
        ),
        equals((chapter: 3, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 11,
          chapter: 3,
          verse: 1,
        ),
        equals((chapter: 3, verse: 1)),
      );
      // Divergent 1 Kings 4:21-34 -> MT 5:1-14
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 11,
          chapter: 4,
          verse: 21,
        ),
        equals((chapter: 5, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 11,
          chapter: 5,
          verse: 1,
        ),
        equals((chapter: 4, verse: 21)),
      );

      // 5. 1 Chronicles (13)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 13,
          chapter: 6,
          verse: 1,
        ),
        equals((chapter: 5, verse: 27)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 13,
          chapter: 5,
          verse: 27,
        ),
        equals((chapter: 6, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 13,
          chapter: 6,
          verse: 16,
        ),
        equals((chapter: 6, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 13,
          chapter: 6,
          verse: 1,
        ),
        equals((chapter: 6, verse: 16)),
      );

      // 6. Nehemiah (16)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 16,
          chapter: 4,
          verse: 1,
        ),
        equals((chapter: 3, verse: 33)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 16,
          chapter: 3,
          verse: 33,
        ),
        equals((chapter: 4, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 16,
          chapter: 4,
          verse: 7,
        ),
        equals((chapter: 4, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 16,
          chapter: 4,
          verse: 1,
        ),
        equals((chapter: 4, verse: 7)),
      );

      // 7. Hosea (33)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 33,
          chapter: 1,
          verse: 10,
        ),
        equals((chapter: 2, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 33,
          chapter: 2,
          verse: 1,
        ),
        equals((chapter: 1, verse: 10)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 33,
          chapter: 2,
          verse: 24,
        ),
        equals((chapter: 2, verse: 25)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 33,
          chapter: 14,
          verse: 1,
        ),
        equals((chapter: 13, verse: 16)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 33,
          chapter: 13,
          verse: 16,
        ),
        equals((chapter: 14, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 33,
          chapter: 14,
          verse: 2,
        ),
        equals((chapter: 14, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 33,
          chapter: 14,
          verse: 1,
        ),
        equals((chapter: 14, verse: 2)),
      );

      // 8. Joel (34)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 34,
          chapter: 2,
          verse: 28,
        ),
        equals((chapter: 3, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 34,
          chapter: 3,
          verse: 1,
        ),
        equals((chapter: 2, verse: 28)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 34,
          chapter: 3,
          verse: 1,
        ),
        equals((chapter: 4, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 34,
          chapter: 4,
          verse: 1,
        ),
        equals((chapter: 3, verse: 1)),
      );

      // 9. Jonah (37)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 37,
          chapter: 2,
          verse: 1,
        ),
        equals((chapter: 1, verse: 17)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 37,
          chapter: 1,
          verse: 17,
        ),
        equals((chapter: 2, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 37,
          chapter: 2,
          verse: 2,
        ),
        equals((chapter: 2, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 37,
          chapter: 2,
          verse: 1,
        ),
        equals((chapter: 2, verse: 2)),
      );

      // 10. Zechariah (43)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 43,
          chapter: 1,
          verse: 18,
        ),
        equals((chapter: 2, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 43,
          chapter: 2,
          verse: 1,
        ),
        equals((chapter: 1, verse: 18)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 43,
          chapter: 2,
          verse: 1,
        ),
        equals((chapter: 2, verse: 5)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 43,
          chapter: 2,
          verse: 5,
        ),
        equals((chapter: 2, verse: 1)),
      );

      // 11. Malachi (44)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 44,
          chapter: 4,
          verse: 1,
        ),
        equals((chapter: 3, verse: 19)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 44,
          chapter: 3,
          verse: 19,
        ),
        equals((chapter: 4, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 44,
          chapter: 3,
          verse: 18,
        ),
        equals((chapter: 3, verse: 18)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 44,
          chapter: 3,
          verse: 18,
        ),
        equals((chapter: 3, verse: 18)),
      );

      // 12. Genesis (1)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 1,
          chapter: 31,
          verse: 55,
        ),
        equals((chapter: 32, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 1,
          chapter: 32,
          verse: 1,
        ),
        equals((chapter: 31, verse: 55)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 1,
          chapter: 32,
          verse: 1,
        ),
        equals((chapter: 32, verse: 2)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 1,
          chapter: 32,
          verse: 2,
        ),
        equals((chapter: 32, verse: 1)),
      );

      // 13. Exodus (2)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 2,
          chapter: 8,
          verse: 1,
        ),
        equals((chapter: 7, verse: 26)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 2,
          chapter: 7,
          verse: 26,
        ),
        equals((chapter: 8, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 2,
          chapter: 8,
          verse: 5,
        ),
        equals((chapter: 8, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 2,
          chapter: 8,
          verse: 1,
        ),
        equals((chapter: 8, verse: 5)),
      );
      // Exodus 22 mapping
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 2,
          chapter: 22,
          verse: 1,
        ),
        equals((chapter: 21, verse: 37)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 2,
          chapter: 21,
          verse: 37,
        ),
        equals((chapter: 22, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 2,
          chapter: 22,
          verse: 2,
        ),
        equals((chapter: 22, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 2,
          chapter: 22,
          verse: 1,
        ),
        equals((chapter: 22, verse: 2)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 2,
          chapter: 22,
          verse: 31,
        ),
        equals((chapter: 22, verse: 30)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 2,
          chapter: 22,
          verse: 30,
        ),
        equals((chapter: 22, verse: 31)),
      );

      // 14. Leviticus (3)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 3,
          chapter: 6,
          verse: 1,
        ),
        equals((chapter: 5, verse: 20)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 3,
          chapter: 5,
          verse: 20,
        ),
        equals((chapter: 6, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 3,
          chapter: 6,
          verse: 8,
        ),
        equals((chapter: 6, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 3,
          chapter: 6,
          verse: 1,
        ),
        equals((chapter: 6, verse: 8)),
      );

      // 15. Numbers (4)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 4,
          chapter: 16,
          verse: 36,
        ),
        equals((chapter: 17, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 4,
          chapter: 17,
          verse: 1,
        ),
        equals((chapter: 16, verse: 36)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 4,
          chapter: 17,
          verse: 1,
        ),
        equals((chapter: 17, verse: 16)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 4,
          chapter: 17,
          verse: 16,
        ),
        equals((chapter: 17, verse: 1)),
      );

      // 16. Deuteronomy (5)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 5,
          chapter: 12,
          verse: 32,
        ),
        equals((chapter: 13, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 5,
          chapter: 13,
          verse: 1,
        ),
        equals((chapter: 12, verse: 32)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 5,
          chapter: 22,
          verse: 30,
        ),
        equals((chapter: 23, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 5,
          chapter: 23,
          verse: 1,
        ),
        equals((chapter: 22, verse: 30)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 5,
          chapter: 29,
          verse: 1,
        ),
        equals((chapter: 28, verse: 69)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 5,
          chapter: 28,
          verse: 69,
        ),
        equals((chapter: 29, verse: 1)),
      );

      // 17. 1 Samuel (9)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 9,
          chapter: 20,
          verse: 43,
        ),
        equals((chapter: 21, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 9,
          chapter: 21,
          verse: 1,
        ),
        equals((chapter: 20, verse: 43)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 9,
          chapter: 21,
          verse: 1,
        ),
        equals((chapter: 21, verse: 2)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 9,
          chapter: 21,
          verse: 2,
        ),
        equals((chapter: 21, verse: 1)),
      );

      // 18. 2 Samuel (10)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 10,
          chapter: 18,
          verse: 33,
        ),
        equals((chapter: 19, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 10,
          chapter: 19,
          verse: 1,
        ),
        equals((chapter: 18, verse: 33)),
      );

      // 19. 2 Kings (12)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 12,
          chapter: 11,
          verse: 21,
        ),
        equals((chapter: 12, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 12,
          chapter: 12,
          verse: 1,
        ),
        equals((chapter: 11, verse: 21)),
      );

      // 20. 2 Chronicles (14)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 14,
          chapter: 2,
          verse: 1,
        ),
        equals((chapter: 1, verse: 18)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 14,
          chapter: 1,
          verse: 18,
        ),
        equals((chapter: 2, verse: 1)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 14,
          chapter: 14,
          verse: 1,
        ),
        equals((chapter: 13, verse: 23)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 14,
          chapter: 13,
          verse: 23,
        ),
        equals((chapter: 14, verse: 1)),
      );

      // 21. Isaiah (27)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 27,
          chapter: 9,
          verse: 1,
        ),
        equals((chapter: 8, verse: 23)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 27,
          chapter: 8,
          verse: 23,
        ),
        equals((chapter: 9, verse: 1)),
      );

      // 22. Ezekiel (31)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 31,
          chapter: 20,
          verse: 45,
        ),
        equals((chapter: 21, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 31,
          chapter: 21,
          verse: 1,
        ),
        equals((chapter: 20, verse: 45)),
      );

      // 23. Daniel (32)
      // Narrative continuation: DRC 3:91-97 -> MT 3:24-30
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 91,
        ),
        equals((chapter: 3, verse: 24)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 24,
        ),
        equals((chapter: 3, verse: 91)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 97,
        ),
        equals((chapter: 3, verse: 30)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 30,
        ),
        equals((chapter: 3, verse: 97)),
      );
      // DRC 3:98-100 -> MT 3:31-33
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 98,
        ),
        equals((chapter: 3, verse: 31)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 31,
        ),
        equals((chapter: 3, verse: 98)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 100,
        ),
        equals((chapter: 3, verse: 33)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 33,
        ),
        equals((chapter: 3, verse: 100)),
      );
      // DRC Greek addition (3:24-90) falls through as unmapped identity
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 24,
        ),
        equals((chapter: 3, verse: 24)),
      );
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 32,
          chapter: 3,
          verse: 90,
        ),
        equals((chapter: 3, verse: 90)),
      );

      // 24. Micah (38)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 38,
          chapter: 5,
          verse: 1,
        ),
        equals((chapter: 4, verse: 14)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 38,
          chapter: 4,
          verse: 14,
        ),
        equals((chapter: 5, verse: 1)),
      );

      // 25. Nahum (39)
      expect(
        BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 39,
          chapter: 1,
          verse: 15,
        ),
        equals((chapter: 2, verse: 1)),
      );
      expect(
        BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 39,
          chapter: 2,
          verse: 1,
        ),
        equals((chapter: 1, verse: 15)),
      );
    });

    test(
      'pins Hosea 2:23 and 2:24 non-injective split round-trip behavior',
      () {
        // DRC Hosea 2:23 maps to MT 2:25
        final mt23 = BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 33,
          chapter: 2,
          verse: 23,
        );
        expect(mt23, equals((chapter: 2, verse: 25)));

        // DRC Hosea 2:24 also maps to MT 2:25 (split verse)
        final mt24 = BibleVerseResolver.vulgateToMasoreticVerse(
          bookNumber: 33,
          chapter: 2,
          verse: 24,
        );
        expect(mt24, equals((chapter: 2, verse: 25)));

        // MT 2:25 maps back to DRC 2:23
        final drcFromMt = BibleVerseResolver.masoreticToVulgateVerse(
          bookNumber: 33,
          chapter: 2,
          verse: 25,
        );
        expect(drcFromMt, equals((chapter: 2, verse: 23)));

        // Round-trip of 2:23 returns 2:23
        expect(
          BibleVerseResolver.masoreticToVulgateVerse(
            bookNumber: 33,
            chapter: mt23.chapter,
            verse: mt23.verse,
          ),
          equals((chapter: 2, verse: 23)),
        );

        // Round-trip of 2:24 returns 2:23 due to non-injective split
        expect(
          BibleVerseResolver.masoreticToVulgateVerse(
            bookNumber: 33,
            chapter: mt24.chapter,
            verse: mt24.verse,
          ),
          equals((chapter: 2, verse: 23)),
        );
      },
    );

    test(
      'boundary tests for verse range transitions and out-of-range guards',
      () {
        void assertDrcToMt(int book, int ch, int v, int expCh, int expV) {
          expect(
            BibleVerseResolver.vulgateToMasoreticVerse(
              bookNumber: book,
              chapter: ch,
              verse: v,
            ),
            equals((chapter: expCh, verse: expV)),
            reason: 'DRC $book $ch:$v -> MT $expCh:$expV',
          );
        }

        void assertMtToDrc(int book, int ch, int v, int expCh, int expV) {
          expect(
            BibleVerseResolver.masoreticToVulgateVerse(
              bookNumber: book,
              chapter: ch,
              verse: v,
            ),
            equals((chapter: expCh, verse: expV)),
            reason: 'MT $book $ch:$v -> DRC $expCh:$expV',
          );
        }

        // Genesis (1)
        assertDrcToMt(1, 31, 54, 31, 54);
        assertDrcToMt(1, 31, 55, 32, 1);
        assertDrcToMt(1, 32, 1, 32, 2);
        assertDrcToMt(1, 32, 32, 32, 33);
        assertDrcToMt(1, 32, 33, 32, 33); // Out-of-range guard check
        assertMtToDrc(1, 32, 1, 31, 55);
        assertMtToDrc(1, 32, 2, 32, 1);
        assertMtToDrc(1, 32, 33, 32, 32);
        assertMtToDrc(1, 32, 34, 32, 34);

        // Exodus (2)
        assertDrcToMt(2, 8, 4, 7, 29);
        assertDrcToMt(2, 8, 5, 8, 1);
        assertDrcToMt(2, 8, 32, 8, 28);
        assertDrcToMt(2, 8, 33, 8, 33);
        assertDrcToMt(2, 22, 1, 21, 37);
        assertDrcToMt(2, 22, 2, 22, 1);
        assertDrcToMt(2, 22, 31, 22, 30);
        assertDrcToMt(2, 22, 32, 22, 32);
        assertMtToDrc(2, 7, 25, 7, 25);
        assertMtToDrc(2, 7, 26, 8, 1);
        assertMtToDrc(2, 7, 29, 8, 4);
        assertMtToDrc(2, 7, 30, 7, 30);
        assertMtToDrc(2, 8, 1, 8, 5);
        assertMtToDrc(2, 8, 28, 8, 32);
        assertMtToDrc(2, 8, 29, 8, 29);
        assertMtToDrc(2, 21, 36, 21, 36);
        assertMtToDrc(2, 21, 37, 22, 1);
        assertMtToDrc(2, 21, 38, 21, 38);
        assertMtToDrc(2, 22, 1, 22, 2);
        assertMtToDrc(2, 22, 30, 22, 31);
        assertMtToDrc(2, 22, 31, 22, 31);

        // Leviticus (3)
        assertDrcToMt(3, 6, 7, 5, 26);
        assertDrcToMt(3, 6, 8, 6, 1);
        assertDrcToMt(3, 6, 30, 6, 23);
        assertDrcToMt(3, 6, 31, 6, 31);
        assertMtToDrc(3, 5, 19, 5, 19);
        assertMtToDrc(3, 5, 20, 6, 1);
        assertMtToDrc(3, 5, 26, 6, 7);
        assertMtToDrc(3, 5, 27, 5, 27);
        assertMtToDrc(3, 6, 1, 6, 8);
        assertMtToDrc(3, 6, 23, 6, 30);
        assertMtToDrc(3, 6, 24, 6, 24);

        // Numbers (4)
        assertDrcToMt(4, 16, 35, 16, 35);
        assertDrcToMt(4, 16, 36, 17, 1);
        assertDrcToMt(4, 16, 50, 17, 15);
        assertDrcToMt(4, 16, 51, 16, 51);
        assertDrcToMt(4, 17, 1, 17, 16);
        assertDrcToMt(4, 17, 13, 17, 28);
        assertDrcToMt(4, 17, 14, 17, 14);
        assertMtToDrc(4, 17, 1, 16, 36);
        assertMtToDrc(4, 17, 15, 16, 50);
        assertMtToDrc(4, 17, 16, 17, 1);
        assertMtToDrc(4, 17, 28, 17, 13);
        assertMtToDrc(4, 17, 29, 17, 29);

        // Deuteronomy (5)
        assertDrcToMt(5, 12, 31, 12, 31);
        assertDrcToMt(5, 12, 32, 13, 1);
        assertDrcToMt(5, 12, 33, 12, 33);
        assertDrcToMt(5, 13, 18, 13, 19);
        assertDrcToMt(5, 13, 19, 13, 19);
        assertDrcToMt(5, 22, 29, 22, 29);
        assertDrcToMt(5, 22, 30, 23, 1);
        assertDrcToMt(5, 22, 31, 22, 31);
        assertDrcToMt(5, 23, 25, 23, 26);
        assertDrcToMt(5, 23, 26, 23, 26);
        assertDrcToMt(5, 29, 1, 28, 69);
        assertDrcToMt(5, 29, 29, 29, 28);
        assertDrcToMt(5, 29, 30, 29, 30);
        assertMtToDrc(5, 13, 1, 12, 32);
        assertMtToDrc(5, 13, 19, 13, 18);
        assertMtToDrc(5, 13, 20, 13, 20);
        assertMtToDrc(5, 23, 1, 22, 30);
        assertMtToDrc(5, 23, 26, 23, 25);
        assertMtToDrc(5, 23, 27, 23, 27);
        assertMtToDrc(5, 28, 69, 29, 1);
        assertMtToDrc(5, 28, 70, 28, 70);
        assertMtToDrc(5, 29, 28, 29, 29);
        assertMtToDrc(5, 29, 29, 29, 29);

        // 1 Samuel (9)
        assertDrcToMt(9, 20, 42, 20, 42);
        assertDrcToMt(9, 20, 43, 21, 1);
        assertDrcToMt(9, 20, 44, 20, 44);
        assertDrcToMt(9, 21, 15, 21, 16);
        assertDrcToMt(9, 21, 16, 21, 16);
        assertMtToDrc(9, 21, 1, 20, 43);
        assertMtToDrc(9, 21, 16, 21, 15);
        assertMtToDrc(9, 21, 17, 21, 17);

        // 2 Samuel (10)
        assertDrcToMt(10, 18, 32, 18, 32);
        assertDrcToMt(10, 18, 33, 19, 1);
        assertDrcToMt(10, 18, 34, 18, 34);
        assertDrcToMt(10, 19, 43, 19, 44);
        assertDrcToMt(10, 19, 44, 19, 44);
        assertMtToDrc(10, 19, 1, 18, 33);
        assertMtToDrc(10, 19, 44, 19, 43);
        assertMtToDrc(10, 19, 45, 19, 45);

        // 1 Kings (11)
        assertDrcToMt(11, 4, 20, 4, 20);
        assertDrcToMt(11, 4, 21, 5, 1);
        assertDrcToMt(11, 4, 34, 5, 14);
        assertDrcToMt(11, 4, 35, 4, 35);
        assertDrcToMt(11, 5, 1, 5, 15);
        assertDrcToMt(11, 5, 18, 5, 32);
        assertDrcToMt(11, 5, 19, 5, 19);
        assertDrcToMt(11, 22, 44, 22, 43);
        assertDrcToMt(11, 22, 54, 22, 53);
        assertDrcToMt(11, 22, 55, 22, 55);
        assertMtToDrc(11, 5, 1, 4, 21);
        assertMtToDrc(11, 5, 14, 4, 34);
        assertMtToDrc(11, 5, 15, 5, 1);
        assertMtToDrc(11, 5, 32, 5, 18);
        assertMtToDrc(11, 5, 33, 5, 33);
        assertMtToDrc(11, 22, 43, 22, 43);
        assertMtToDrc(11, 22, 44, 22, 45);
        assertMtToDrc(11, 22, 53, 22, 54);
        assertMtToDrc(11, 22, 54, 22, 54);

        // 2 Kings (12)
        assertDrcToMt(12, 11, 20, 11, 20);
        assertDrcToMt(12, 11, 21, 12, 1);
        assertDrcToMt(12, 11, 22, 11, 22);
        assertDrcToMt(12, 12, 21, 12, 22);
        assertDrcToMt(12, 12, 22, 12, 22);
        assertMtToDrc(12, 12, 1, 11, 21);
        assertMtToDrc(12, 12, 22, 12, 21);
        assertMtToDrc(12, 12, 23, 12, 23);

        // 1 Chronicles (13)
        assertDrcToMt(13, 6, 15, 5, 41);
        assertDrcToMt(13, 6, 16, 6, 1);
        assertDrcToMt(13, 6, 81, 6, 66);
        assertDrcToMt(13, 6, 82, 6, 82);
        assertMtToDrc(13, 5, 26, 5, 26);
        assertMtToDrc(13, 5, 27, 6, 1);
        assertMtToDrc(13, 5, 41, 6, 15);
        assertMtToDrc(13, 5, 42, 5, 42);
        assertMtToDrc(13, 6, 1, 6, 16);
        assertMtToDrc(13, 6, 66, 6, 81);
        assertMtToDrc(13, 6, 67, 6, 67);

        // 2 Chronicles (14)
        assertDrcToMt(14, 2, 1, 1, 18);
        assertDrcToMt(14, 2, 2, 2, 1);
        assertDrcToMt(14, 2, 18, 2, 17);
        assertDrcToMt(14, 2, 19, 2, 19);
        assertDrcToMt(14, 14, 1, 13, 23);
        assertDrcToMt(14, 14, 2, 14, 1);
        assertDrcToMt(14, 14, 15, 14, 14);
        assertDrcToMt(14, 14, 16, 14, 16);
        assertMtToDrc(14, 1, 18, 2, 1);
        assertMtToDrc(14, 1, 19, 1, 19);
        assertMtToDrc(14, 2, 1, 2, 2);
        assertMtToDrc(14, 2, 17, 2, 18);
        assertMtToDrc(14, 2, 18, 2, 18);
        assertMtToDrc(14, 13, 23, 14, 1);
        assertMtToDrc(14, 13, 24, 13, 24);
        assertMtToDrc(14, 14, 1, 14, 2);
        assertMtToDrc(14, 14, 14, 14, 15);
        assertMtToDrc(14, 14, 15, 14, 15);

        // Nehemiah (16)
        assertDrcToMt(16, 4, 6, 3, 38);
        assertDrcToMt(16, 4, 7, 4, 1);
        assertDrcToMt(16, 4, 23, 4, 17);
        assertDrcToMt(16, 4, 24, 4, 24);
        assertMtToDrc(16, 3, 32, 3, 32);
        assertMtToDrc(16, 3, 33, 4, 1);
        assertMtToDrc(16, 3, 38, 4, 6);
        assertMtToDrc(16, 3, 39, 3, 39);
        assertMtToDrc(16, 4, 1, 4, 7);
        assertMtToDrc(16, 4, 17, 4, 23);
        assertMtToDrc(16, 4, 18, 4, 18);

        // Job (20)
        assertDrcToMt(20, 39, 30, 39, 30);
        assertDrcToMt(20, 39, 31, 40, 1);
        assertDrcToMt(20, 39, 35, 40, 5);
        assertDrcToMt(20, 39, 36, 39, 36);
        assertDrcToMt(20, 40, 1, 40, 6);
        assertDrcToMt(20, 40, 19, 40, 24);
        assertDrcToMt(20, 40, 20, 41, 1);
        assertDrcToMt(20, 40, 28, 41, 9);
        assertDrcToMt(20, 40, 29, 40, 29);
        assertDrcToMt(20, 41, 1, 41, 10);
        assertDrcToMt(20, 41, 25, 41, 34);
        assertDrcToMt(20, 41, 26, 41, 26);
        assertMtToDrc(20, 40, 1, 39, 31);
        assertMtToDrc(20, 40, 5, 39, 35);
        assertMtToDrc(20, 40, 6, 40, 1);
        assertMtToDrc(20, 40, 24, 40, 19);
        assertMtToDrc(20, 40, 25, 40, 25);
        assertMtToDrc(20, 41, 1, 40, 20);
        assertMtToDrc(20, 41, 9, 40, 28);
        assertMtToDrc(20, 41, 10, 41, 1);
        assertMtToDrc(20, 41, 34, 41, 25);
        assertMtToDrc(20, 41, 35, 41, 35);

        // Ecclesiastes (23)
        assertDrcToMt(23, 4, 16, 4, 16);
        assertDrcToMt(23, 4, 17, 5, 1);
        assertDrcToMt(23, 4, 18, 4, 18);
        assertDrcToMt(23, 5, 1, 5, 2);
        assertDrcToMt(23, 5, 19, 5, 20);
        assertDrcToMt(23, 5, 20, 5, 20);
        assertMtToDrc(23, 5, 1, 4, 17);
        assertMtToDrc(23, 5, 2, 5, 1);
        assertMtToDrc(23, 5, 20, 5, 19);
        assertMtToDrc(23, 5, 21, 5, 21);

        // Canticle of Canticles (24)
        assertDrcToMt(24, 7, 1, 6, 13);
        assertDrcToMt(24, 7, 2, 7, 1);
        assertDrcToMt(24, 7, 13, 7, 12);
        assertDrcToMt(24, 7, 14, 7, 14);
        assertMtToDrc(24, 6, 13, 7, 1);
        assertMtToDrc(24, 7, 1, 7, 2);
        assertMtToDrc(24, 7, 12, 7, 13);
        assertMtToDrc(24, 7, 13, 7, 13);

        // Isaiah (27)
        assertDrcToMt(27, 9, 1, 8, 23);
        assertDrcToMt(27, 9, 2, 9, 1);
        assertDrcToMt(27, 9, 21, 9, 20);
        assertDrcToMt(27, 9, 22, 9, 22);
        assertMtToDrc(27, 8, 22, 8, 22);
        assertMtToDrc(27, 8, 23, 9, 1);
        assertMtToDrc(27, 8, 24, 8, 24);
        assertMtToDrc(27, 9, 1, 9, 2);
        assertMtToDrc(27, 9, 20, 9, 21);
        assertMtToDrc(27, 9, 21, 9, 21);

        // Ezekiel (31)
        assertDrcToMt(31, 20, 44, 20, 44);
        assertDrcToMt(31, 20, 45, 21, 1);
        assertDrcToMt(31, 20, 49, 21, 5);
        assertDrcToMt(31, 20, 50, 20, 50);
        assertDrcToMt(31, 21, 1, 21, 6);
        assertDrcToMt(31, 21, 32, 21, 37);
        assertDrcToMt(31, 21, 33, 21, 33);
        assertMtToDrc(31, 21, 1, 20, 45);
        assertMtToDrc(31, 21, 5, 20, 49);
        assertMtToDrc(31, 21, 6, 21, 1);
        assertMtToDrc(31, 21, 37, 21, 32);
        assertMtToDrc(31, 21, 38, 21, 38);

        // Daniel (32)
        assertDrcToMt(32, 3, 90, 3, 90);
        assertDrcToMt(32, 3, 91, 3, 24);
        assertDrcToMt(32, 3, 97, 3, 30);
        assertDrcToMt(32, 3, 98, 3, 31);
        assertDrcToMt(32, 3, 100, 3, 33);
        assertDrcToMt(32, 3, 101, 3, 101);
        assertMtToDrc(32, 3, 23, 3, 23);
        assertMtToDrc(32, 3, 24, 3, 91);
        assertMtToDrc(32, 3, 30, 3, 97);
        assertMtToDrc(32, 3, 31, 3, 98);
        assertMtToDrc(32, 3, 33, 3, 100);
        assertMtToDrc(32, 3, 34, 3, 34);

        // Hosea (33)
        assertDrcToMt(33, 1, 9, 1, 9);
        assertDrcToMt(33, 1, 10, 2, 1);
        assertDrcToMt(33, 1, 11, 2, 2);
        assertDrcToMt(33, 1, 12, 1, 12);
        assertDrcToMt(33, 2, 1, 2, 3);
        assertDrcToMt(33, 2, 23, 2, 25);
        assertDrcToMt(33, 2, 24, 2, 25);
        assertDrcToMt(33, 2, 25, 2, 25);
        assertDrcToMt(33, 11, 11, 11, 11);
        assertDrcToMt(33, 11, 12, 12, 1);
        assertDrcToMt(33, 11, 13, 11, 13);
        assertDrcToMt(33, 12, 1, 12, 2);
        assertDrcToMt(33, 12, 14, 12, 15);
        assertDrcToMt(33, 12, 15, 12, 15);
        assertDrcToMt(33, 14, 1, 13, 16);
        assertDrcToMt(33, 14, 2, 14, 1);
        assertDrcToMt(33, 14, 10, 14, 9);
        assertDrcToMt(33, 14, 11, 14, 11);
        assertMtToDrc(33, 2, 1, 1, 10);
        assertMtToDrc(33, 2, 2, 1, 11);
        assertMtToDrc(33, 2, 3, 2, 1);
        assertMtToDrc(33, 2, 25, 2, 23);
        assertMtToDrc(33, 2, 26, 2, 26);
        assertMtToDrc(33, 12, 1, 11, 12);
        assertMtToDrc(33, 12, 2, 12, 1);
        assertMtToDrc(33, 12, 15, 12, 14);
        assertMtToDrc(33, 12, 16, 12, 16);
        assertMtToDrc(33, 13, 15, 13, 15);
        assertMtToDrc(33, 13, 16, 14, 1);
        assertMtToDrc(33, 13, 17, 13, 17);
        assertMtToDrc(33, 14, 1, 14, 2);
        assertMtToDrc(33, 14, 9, 14, 10);
        assertMtToDrc(33, 14, 10, 14, 10);

        // Joel (34)
        assertDrcToMt(34, 2, 27, 2, 27);
        assertDrcToMt(34, 2, 28, 3, 1);
        assertDrcToMt(34, 2, 32, 3, 5);
        assertDrcToMt(34, 2, 33, 2, 33);
        assertDrcToMt(34, 3, 1, 4, 1);
        assertDrcToMt(34, 3, 21, 4, 21);
        assertDrcToMt(34, 3, 22, 3, 22);
        assertMtToDrc(34, 3, 1, 2, 28);
        assertMtToDrc(34, 3, 5, 2, 32);
        assertMtToDrc(34, 3, 6, 3, 6);
        assertMtToDrc(34, 4, 1, 3, 1);
        assertMtToDrc(34, 4, 21, 3, 21);
        assertMtToDrc(34, 4, 22, 4, 22);

        // Jonah (37)
        assertDrcToMt(37, 2, 1, 1, 17);
        assertDrcToMt(37, 2, 2, 2, 1);
        assertDrcToMt(37, 2, 11, 2, 10);
        assertDrcToMt(37, 2, 12, 2, 12);
        assertMtToDrc(37, 1, 16, 1, 16);
        assertMtToDrc(37, 1, 17, 2, 1);
        assertMtToDrc(37, 1, 18, 1, 18);
        assertMtToDrc(37, 2, 1, 2, 2);
        assertMtToDrc(37, 2, 10, 2, 11);
        assertMtToDrc(37, 2, 11, 2, 11);

        // Micah (38)
        assertDrcToMt(38, 5, 1, 4, 14);
        assertDrcToMt(38, 5, 2, 5, 1);
        assertDrcToMt(38, 5, 10, 5, 9);
        assertDrcToMt(38, 5, 11, 5, 10);
        assertDrcToMt(38, 5, 12, 5, 12);
        assertDrcToMt(38, 5, 14, 5, 14);
        assertMtToDrc(38, 4, 13, 4, 13);
        assertMtToDrc(38, 4, 14, 5, 1);
        assertMtToDrc(38, 4, 15, 4, 15);
        assertMtToDrc(38, 5, 1, 5, 2);
        assertMtToDrc(38, 5, 9, 5, 10);
        assertMtToDrc(38, 5, 10, 5, 11);
        assertMtToDrc(38, 5, 11, 5, 11);
        assertMtToDrc(38, 5, 12, 5, 12);
        assertMtToDrc(38, 5, 14, 5, 14);

        // Nahum (39)
        assertDrcToMt(39, 1, 14, 1, 14);
        assertDrcToMt(39, 1, 15, 2, 1);
        assertDrcToMt(39, 1, 16, 1, 16);
        assertDrcToMt(39, 2, 1, 2, 2);
        assertDrcToMt(39, 2, 13, 2, 14);
        assertDrcToMt(39, 2, 14, 2, 14);
        assertMtToDrc(39, 2, 1, 1, 15);
        assertMtToDrc(39, 2, 2, 2, 1);
        assertMtToDrc(39, 2, 14, 2, 13);
        assertMtToDrc(39, 2, 15, 2, 15);

        // Zechariah (43)
        assertDrcToMt(43, 1, 17, 1, 17);
        assertDrcToMt(43, 1, 18, 2, 1);
        assertDrcToMt(43, 1, 21, 2, 4);
        assertDrcToMt(43, 1, 22, 1, 22);
        assertDrcToMt(43, 2, 1, 2, 5);
        assertDrcToMt(43, 2, 13, 2, 17);
        assertDrcToMt(43, 2, 14, 2, 14);
        assertMtToDrc(43, 2, 1, 1, 18);
        assertMtToDrc(43, 2, 4, 1, 21);
        assertMtToDrc(43, 2, 5, 2, 1);
        assertMtToDrc(43, 2, 17, 2, 13);
        assertMtToDrc(43, 2, 18, 2, 18);

        // Malachi (44)
        assertDrcToMt(44, 3, 18, 3, 18);
        assertDrcToMt(44, 4, 1, 3, 19);
        assertDrcToMt(44, 4, 6, 3, 24);
        assertDrcToMt(44, 4, 7, 4, 7);
        assertMtToDrc(44, 3, 18, 3, 18);
        assertMtToDrc(44, 3, 19, 4, 1);
        assertMtToDrc(44, 3, 24, 4, 6);
        assertMtToDrc(44, 3, 25, 3, 25);
      },
    );

    test(
      'table-driven round-trip verification across all mapped Old Testament ranges',
      () {
        final mappedRanges = <int, List<({int chapter, int start, int end})>>{
          // Genesis (1)
          1: [
            (chapter: 31, start: 55, end: 55),
            (chapter: 32, start: 1, end: 32),
          ],
          // Exodus (2)
          2: [
            (chapter: 8, start: 1, end: 4),
            (chapter: 8, start: 5, end: 32),
            (chapter: 22, start: 1, end: 1),
            (chapter: 22, start: 2, end: 31),
          ],
          // Leviticus (3)
          3: [(chapter: 6, start: 1, end: 7), (chapter: 6, start: 8, end: 30)],
          // Numbers (4)
          4: [
            (chapter: 16, start: 36, end: 50),
            (chapter: 17, start: 1, end: 13),
          ],
          // Deuteronomy (5)
          5: [
            (chapter: 12, start: 32, end: 32),
            (chapter: 13, start: 1, end: 18),
            (chapter: 22, start: 30, end: 30),
            (chapter: 23, start: 1, end: 25),
            (chapter: 29, start: 1, end: 1),
            (chapter: 29, start: 2, end: 29),
          ],
          // 1 Samuel (9)
          9: [
            (chapter: 20, start: 43, end: 43),
            (chapter: 21, start: 1, end: 15),
          ],
          // 2 Samuel (10)
          10: [
            (chapter: 18, start: 33, end: 33),
            (chapter: 19, start: 1, end: 43),
          ],
          // 1 Kings (11)
          11: [
            (chapter: 4, start: 21, end: 34),
            (chapter: 5, start: 1, end: 18),
            (chapter: 22, start: 44, end: 44),
            (chapter: 22, start: 45, end: 54),
          ],
          // 2 Kings (12)
          12: [
            (chapter: 11, start: 21, end: 21),
            (chapter: 12, start: 1, end: 21),
          ],
          // 1 Chronicles (13)
          13: [
            (chapter: 6, start: 1, end: 15),
            (chapter: 6, start: 16, end: 81),
          ],
          // 2 Chronicles (14)
          14: [
            (chapter: 2, start: 1, end: 1),
            (chapter: 2, start: 2, end: 18),
            (chapter: 14, start: 1, end: 1),
            (chapter: 14, start: 2, end: 15),
          ],
          // Nehemiah (16)
          16: [(chapter: 4, start: 1, end: 6), (chapter: 4, start: 7, end: 23)],
          // Job (20)
          20: [
            (chapter: 39, start: 31, end: 35),
            (chapter: 40, start: 1, end: 19),
            (chapter: 40, start: 20, end: 28),
            (chapter: 41, start: 1, end: 25),
          ],
          // Ecclesiastes (23)
          23: [
            (chapter: 4, start: 17, end: 17),
            (chapter: 5, start: 1, end: 19),
          ],
          // Canticle of Canticles (24)
          24: [(chapter: 7, start: 1, end: 1), (chapter: 7, start: 2, end: 13)],
          // Isaiah (27)
          27: [(chapter: 9, start: 1, end: 1), (chapter: 9, start: 2, end: 21)],
          // Ezekiel (31)
          31: [
            (chapter: 20, start: 45, end: 49),
            (chapter: 21, start: 1, end: 32),
          ],
          // Daniel (32)
          32: [(chapter: 3, start: 91, end: 100)],
          // Hosea (33)
          33: [
            (chapter: 1, start: 10, end: 11),
            (chapter: 2, start: 1, end: 23),
            (chapter: 2, start: 24, end: 24),
            (chapter: 11, start: 12, end: 12),
            (chapter: 12, start: 1, end: 14),
            (chapter: 14, start: 1, end: 1),
            (chapter: 14, start: 2, end: 10),
          ],
          // Joel (34)
          34: [
            (chapter: 2, start: 28, end: 32),
            (chapter: 3, start: 1, end: 21),
          ],
          // Jonah (37)
          37: [(chapter: 2, start: 1, end: 1), (chapter: 2, start: 2, end: 11)],
          // Micah (38)
          38: [(chapter: 5, start: 1, end: 1), (chapter: 5, start: 2, end: 11)],
          // Nahum (39)
          39: [
            (chapter: 1, start: 15, end: 15),
            (chapter: 2, start: 1, end: 13),
          ],
          // Zechariah (43)
          43: [
            (chapter: 1, start: 18, end: 21),
            (chapter: 2, start: 1, end: 13),
          ],
          // Malachi (44)
          44: [(chapter: 4, start: 1, end: 6)],
        };

        var totalVersesTested = 0;

        for (final entry in mappedRanges.entries) {
          final bookNumber = entry.key;
          for (final range in entry.value) {
            for (var v = range.start; v <= range.end; v++) {
              totalVersesTested++;
              final mt = BibleVerseResolver.vulgateToMasoreticVerse(
                bookNumber: bookNumber,
                chapter: range.chapter,
                verse: v,
              );

              // Forward mapping must shift (or map) the verse
              expect(
                mt,
                isNot(equals((chapter: range.chapter, verse: v))),
                reason:
                    'Book $bookNumber ${range.chapter}:$v should have a distinct Masoretic mapping',
              );

              // Reverse mapping: masoreticToVulgate(vulgateToMasoretic(x))
              final vBack = BibleVerseResolver.masoreticToVulgateVerse(
                bookNumber: bookNumber,
                chapter: mt.chapter,
                verse: mt.verse,
              );

              // Pinned non-injective exceptions
              if (bookNumber == 33 && range.chapter == 2 && v == 24) {
                // Hosea 2:24 is a split of MT 2:25; MT 2:25 maps back to DRC 2:23
                expect(
                  vBack,
                  equals((chapter: 2, verse: 23)),
                  reason: 'Hosea 2:24 round-trip expected exception',
                );
              } else if (bookNumber == 11 && range.chapter == 22 && v == 44) {
                // 1 Kings 22:44 maps to MT 22:43; MT 22:43 maps back to DRC 22:43
                expect(
                  vBack,
                  equals((chapter: 22, verse: 43)),
                  reason: '1 Kings 22:44 round-trip expected exception',
                );
              } else {
                expect(
                  vBack,
                  equals((chapter: range.chapter, verse: v)),
                  reason:
                      'Round trip failed for book $bookNumber ${range.chapter}:$v -> MT ${mt.chapter}:${mt.verse}',
                );
              }

              // Injective MT back to DRC must preserve MT when mapped forward again
              final mtBack = BibleVerseResolver.vulgateToMasoreticVerse(
                bookNumber: bookNumber,
                chapter: vBack.chapter,
                verse: vBack.verse,
              );
              expect(
                mtBack,
                equals(mt),
                reason:
                    'MT consistency failed for book $bookNumber MT ${mt.chapter}:${mt.verse}',
              );
            }
          }
        }

        // Assert that all ranges across the 24 non-psalm divergent books were verified
        expect(totalVersesTested, greaterThan(400));
      },
    );
  });
}
