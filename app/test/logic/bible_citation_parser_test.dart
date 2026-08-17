import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/prayers.dart';

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
      },
    );
  });
}
