import 'bible_metadata.dart';

class BibleCitation {
  final String rawMatch;
  final String displayLabel;
  final int bookNumber;
  final String bookName;
  final String abbrev;
  final int chapter;
  final int? verse;
  final int? endVerse;
  final String verseSystem;

  bool get isEntireChapter => verse == null;

  const BibleCitation({
    required this.rawMatch,
    required this.displayLabel,
    required this.bookNumber,
    required this.bookName,
    required this.abbrev,
    required this.chapter,
    this.verse,
    this.endVerse,
    this.verseSystem = 'vulgate',
  });
}

class BibleVerseResolver {
  /// Resolves Vulgate Psalm chapter to Masoretic/Hebrew Psalm chapter number
  static int vulgateToMasoreticPsalm(int vulgatePsalm) {
    if (vulgatePsalm <= 8) return vulgatePsalm;
    if (vulgatePsalm == 9) return 9;
    if (vulgatePsalm >= 10 && vulgatePsalm <= 112) return vulgatePsalm + 1;
    if (vulgatePsalm == 113) return 114;
    if (vulgatePsalm == 114 || vulgatePsalm == 115) return 116;
    if (vulgatePsalm >= 116 && vulgatePsalm <= 145) return vulgatePsalm + 1;
    if (vulgatePsalm == 146 || vulgatePsalm == 147) return 147;
    return vulgatePsalm;
  }
}

class CitationSegment {
  final String? text;
  final BibleCitation? citation;

  const CitationSegment.text(this.text) : citation = null;
  const CitationSegment.citation(this.citation) : text = null;

  bool get isCitation => citation != null;
}

class BibleCitationParser {
  static final RegExp _strictRomanRegex = RegExp(
    r'^(?!$)(?:m{0,4}(?:cm|cd|d?c{0,3})(?:xc|xl|l?x{0,3})(?:ix|iv|v?i{0,3}))$',
    caseSensitive: false,
  );

  static int _romanToDecimal(String roman) {
    final clean = roman.toLowerCase().trim();
    if (!_strictRomanRegex.hasMatch(clean)) return 0;
    final romanMap = <String, int>{
      'i': 1,
      'v': 5,
      'x': 10,
      'l': 50,
      'c': 100,
      'd': 500,
      'm': 1000,
    };

    int result = 0;
    int prevValue = 0;

    for (int i = clean.length - 1; i >= 0; i--) {
      final char = clean[i];
      final currValue = romanMap[char] ?? 0;
      if (currValue < prevValue) {
        result -= currValue;
      } else {
        result += currValue;
        prevValue = currValue;
      }
    }
    return result > 0 ? result : 0;
  }

  static final Map<String, int> _aliasToBookNumber = () {
    final map = <String, int>{};
    for (final book in catholicBooks) {
      map[book.bookName.toLowerCase()] = book.bookNumber;
      map[book.abbrev.toLowerCase()] = book.bookNumber;
    }

    void alias(String a, int num) => map[a.toLowerCase()] = num;

    alias('gen', 1);
    alias('genesis', 1);
    alias('ex', 2);
    alias('exod', 2);
    alias('exodus', 2);
    alias('lev', 3);
    alias('leviticus', 3);
    alias('num', 4);
    alias('numbers', 4);
    alias('deut', 5);
    alias('deuteronomy', 5);
    alias('jos', 6);
    alias('josh', 6);
    alias('joshua', 6);
    alias('jdg', 7);
    alias('judg', 7);
    alias('judges', 7);
    alias('rut', 8);
    alias('ruth', 8);
    alias('1sa', 9);
    alias('1 sam', 9);
    alias('1sam', 9);
    alias('1 samuel', 9);
    alias('2sa', 10);
    alias('2 sam', 10);
    alias('2sam', 10);
    alias('2 samuel', 10);
    alias('1ki', 11);
    alias('1 ki', 11);
    alias('3 kings', 11);
    alias('3ki', 11);
    alias('1kings', 11);
    alias('1 kings', 11);
    alias('2ki', 12);
    alias('2 ki', 12);
    alias('4 kings', 12);
    alias('4ki', 12);
    alias('2kings', 12);
    alias('2 kings', 12);
    alias('1ch', 13);
    alias('1 chron', 13);
    alias('1 par', 13);
    alias('1 paralip', 13);
    alias('1 paralipomenon', 13);
    alias('2ch', 14);
    alias('2 chron', 14);
    alias('2 par', 14);
    alias('2 paralip', 14);
    alias('2 paralipomenon', 14);
    alias('ezr', 15);
    alias('esd', 15);
    alias('esdras', 15);
    alias('neh', 16);
    alias('nehemiah', 16);
    alias('tob', 17);
    alias('tobias', 17);
    alias('tobit', 17);
    alias('jdt', 18);
    alias('judith', 18);
    alias('est', 19);
    alias('esth', 19);
    alias('esther', 19);
    alias('job', 20);
    alias('psa', 21);
    alias('ps', 21);
    alias('pss', 21);
    alias('psalm', 21);
    alias('psalms', 21);
    alias('pro', 22);
    alias('prov', 22);
    alias('proverbs', 22);
    alias('ecc', 23);
    alias('eccl', 23);
    alias('eccles', 23);
    alias('ecclesiastes', 23);
    alias('sng', 24);
    alias('cant', 24);
    alias('song', 24);
    alias('canticle', 24);
    alias('canticles', 24);
    alias('song of songs', 24);
    alias('song of solomon', 24);
    alias('canticle of canticles', 24);
    alias('wis', 25);
    alias('wisd', 25);
    alias('wisdom', 25);
    alias('sir', 26);
    alias('ecclus', 26);
    alias('sirach', 26);
    alias('ecclesiasticus', 26);
    alias('isa', 27);
    alias('isaias', 27);
    alias('isaiah', 27);
    alias('jer', 28);
    alias('jeremias', 28);
    alias('jeremiah', 28);
    alias('lam', 29);
    alias('lamentations', 29);
    alias('bar', 30);
    alias('baruch', 30);
    alias('eze', 31);
    alias('ezek', 31);
    alias('ezekiel', 31);
    alias('dan', 32);
    alias('daniel', 32);
    alias('hos', 33);
    alias('osee', 33);
    alias('hosea', 33);
    alias('joe', 34);
    alias('joel', 34);
    alias('amo', 35);
    alias('amos', 35);
    alias('oba', 36);
    alias('obad', 36);
    alias('abdias', 36);
    alias('obadiah', 36);
    alias('jon', 37);
    alias('jonas', 37);
    alias('jonah', 37);
    alias('mic', 38);
    alias('micheas', 38);
    alias('micah', 38);
    alias('nah', 39);
    alias('nahum', 39);
    alias('hab', 40);
    alias('habacuc', 40);
    alias('habakkuk', 40);
    alias('zep', 41);
    alias('zeph', 41);
    alias('sophonias', 41);
    alias('zephaniah', 41);
    alias('hag', 42);
    alias('aggeus', 42);
    alias('haggai', 42);
    alias('zech', 43);
    alias('zacharias', 43);
    alias('zechariah', 43);
    alias('mal', 44);
    alias('malachias', 44);
    alias('malachi', 44);
    alias('1ma', 45);
    alias('1 mach', 45);
    alias('1mach', 45);
    alias('1 mac', 45);
    alias('1mac', 45);
    alias('1 macc', 45);
    alias('1macc', 45);
    alias('1 maccabees', 45);
    alias('2ma', 46);
    alias('2 mach', 46);
    alias('2mach', 46);
    alias('2 mac', 46);
    alias('2mac', 46);
    alias('2 macc', 46);
    alias('2macc', 46);
    alias('2 maccabees', 46);

    alias('mt', 49);
    alias('mat', 49);
    alias('matt', 49);
    alias('matthew', 49);
    alias('mk', 50);
    alias('mar', 50);
    alias('mark', 50);
    alias('lk', 51);
    alias('luk', 51);
    alias('luke', 51);
    alias('jn', 52);
    alias('joh', 52);
    alias('john', 52);
    alias('act', 53);
    alias('acts', 53);
    alias('rom', 54);
    alias('romans', 54);
    alias('1co', 55);
    alias('1 cor', 55);
    alias('1cor', 55);
    alias('1 corinthians', 55);
    alias('2co', 56);
    alias('2 cor', 56);
    alias('2cor', 56);
    alias('2 corinthians', 56);
    alias('gal', 57);
    alias('galatians', 57);
    alias('eph', 58);
    alias('ephesians', 58);
    alias('php', 59);
    alias('phil', 59);
    alias('philippians', 59);
    alias('col', 60);
    alias('colossians', 60);
    alias('1th', 61);
    alias('1 thes', 61);
    alias('1 thess', 61);
    alias('1thess', 61);
    alias('1 thessalonians', 61);
    alias('2th', 62);
    alias('2 thes', 62);
    alias('2 thess', 62);
    alias('2thess', 62);
    alias('2 thessalonians', 62);
    alias('1ti', 64);
    alias('1 tim', 64);
    alias('1tim', 64);
    alias('1 timothy', 64);
    alias('2ti', 65);
    alias('2 tim', 65);
    alias('2tim', 65);
    alias('2 timothy', 65);
    alias('tit', 66);
    alias('titus', 66);
    alias('phm', 67);
    alias('philem', 67);
    alias('philemon', 67);
    alias('heb', 68);
    alias('hebrews', 68);
    alias('jam', 69);
    alias('jas', 69);
    alias('james', 69);
    alias('1pe', 70);
    alias('1 pet', 70);
    alias('1pet', 70);
    alias('1 peter', 70);
    alias('2pe', 71);
    alias('2 pet', 71);
    alias('2pet', 71);
    alias('2 peter', 71);
    alias('1jn', 72);
    alias('1 jn', 72);
    alias('1 john', 72);
    alias('2jn', 73);
    alias('2 jn', 73);
    alias('2 john', 73);
    alias('3jn', 74);
    alias('3 jn', 74);
    alias('3 john', 74);
    alias('jud', 75);
    alias('jude', 75);
    alias('rev', 76);
    alias('apoc', 76);
    alias('apocalypse', 76);
    alias('revelation', 76);

    return map;
  }();

  static final RegExp _citationRegex = RegExp(
    r'\(?\b((?:[1-4]\s*)?(?:St\.\s*|Saint\s*)?[A-Z][a-zA-Z]{1,16}(?:\s+of\s+[A-Za-z]+)?\.?)'
    r'(?:'
    r'(?:\s+|\.)([ivxlcdmIVXLCDM]+)'
    r'|'
    r'\s*(\d{1,3})'
    r')'
    r'(?:'
    r'[\:\.\,\s]+([0-9ivxlcdmIVXLCDM]+)'
    r'(?:\s*[\-\u2013\u2014]\s*([0-9ivxlcdmIVXLCDM]+))?'
    r')?'
    r'\)?(?![a-zA-Z0-9])',
    caseSensitive: true,
  );

  static List<CitationSegment> parse(
    String input, {
    String verseSystem = 'vulgate',
  }) {
    if (input.isEmpty) return [const CitationSegment.text('')];

    final segments = <CitationSegment>[];
    int lastOffset = 0;

    for (final match in _citationRegex.allMatches(input)) {
      final rawBook = match.group(1)!.trim().replaceAll('.', '');
      final rawRomanChap = match.group(2)?.trim();
      final rawArabicChap = match.group(3)?.trim();
      final rawVerse = match.group(4)?.trim();
      final rawEndVerse = match.group(5)?.trim();

      var bookKey = rawBook
          .toLowerCase()
          .replaceAll(RegExp(r'^(?:st|saint)\s+'), '')
          .trim();
      final bookNum = _aliasToBookNumber[bookKey];

      if (bookNum == null) {
        continue;
      }

      final bookMetadata = catholicBooks.firstWhere(
        (b) => b.bookNumber == bookNum,
        orElse: () => catholicBooks[0],
      );

      final int chapter;
      if (rawRomanChap != null) {
        if (!_strictRomanRegex.hasMatch(rawRomanChap)) continue;
        chapter = _romanToDecimal(rawRomanChap);
      } else if (rawArabicChap != null) {
        chapter = int.tryParse(rawArabicChap) ?? 0;
      } else {
        continue;
      }

      if (chapter < 1 || chapter > bookMetadata.chaptersCount) {
        continue;
      }

      int? verse;
      if (rawVerse != null) {
        verse = int.tryParse(rawVerse);
        if (verse == null && _strictRomanRegex.hasMatch(rawVerse)) {
          verse = _romanToDecimal(rawVerse);
        }
        if (verse == null || verse < 1 || verse > 200) {
          continue;
        }
      }

      int? endVerse;
      if (rawEndVerse != null) {
        endVerse = int.tryParse(rawEndVerse);
        if (endVerse == null && _strictRomanRegex.hasMatch(rawEndVerse)) {
          endVerse = _romanToDecimal(rawEndVerse);
        }
        if (endVerse == null ||
            endVerse < 1 ||
            endVerse > 200 ||
            (verse != null && endVerse < verse)) {
          continue;
        }
      }

      if (match.start > lastOffset) {
        segments.add(
          CitationSegment.text(input.substring(lastOffset, match.start)),
        );
      }

      final String displayLabel;
      if (verse == null) {
        displayLabel = '${bookMetadata.bookName} $chapter';
      } else if (endVerse != null) {
        displayLabel = '${bookMetadata.bookName} $chapter:$verse-$endVerse';
      } else {
        displayLabel = '${bookMetadata.bookName} $chapter:$verse';
      }

      final citation = BibleCitation(
        rawMatch: match.group(0)!,
        displayLabel: displayLabel,
        bookNumber: bookNum,
        bookName: bookMetadata.bookName,
        abbrev: bookMetadata.abbrev,
        chapter: chapter,
        verse: verse,
        endVerse: endVerse,
        verseSystem: verseSystem,
      );

      segments.add(CitationSegment.citation(citation));
      lastOffset = match.end;
    }

    if (lastOffset < input.length) {
      segments.add(CitationSegment.text(input.substring(lastOffset)));
    }

    return segments.isEmpty ? [CitationSegment.text(input)] : segments;
  }
}
