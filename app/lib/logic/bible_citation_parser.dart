import 'bible_metadata.dart';

class BibleCitation {
  final String rawMatch;
  final String displayLabel;
  final int bookNumber;
  final String bookName;
  final String abbrev;
  final int chapter;
  final int verse;
  final int? endVerse;

  const BibleCitation({
    required this.rawMatch,
    required this.displayLabel,
    required this.bookNumber,
    required this.bookName,
    required this.abbrev,
    required this.chapter,
    required this.verse,
    this.endVerse,
  });
}

class CitationSegment {
  final String? text;
  final BibleCitation? citation;

  const CitationSegment.text(this.text) : citation = null;
  const CitationSegment.citation(this.citation) : text = null;

  bool get isCitation => citation != null;
}

class BibleCitationParser {
  static int _romanToDecimal(String roman) {
    final clean = roman.toLowerCase().trim();
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
    return result > 0 ? result : 1;
  }

  static const Map<String, int> _aliasToBookNumber = {
    // Pentateuch
    'gen': 1, 'genesis': 1,
    'ex': 2, 'exod': 2, 'exodus': 2,
    'lev': 3, 'leviticus': 3,
    'num': 4, 'numbers': 4,
    'deut': 5, 'deuteronomy': 5,

    // Historical
    'jos': 6, 'josh': 6, 'joshua': 6,
    'jdg': 7, 'judg': 7, 'judges': 7,
    'rut': 8, 'ruth': 8,
    '1sa': 9, '1 sam': 9, '1sam': 9, '1 samuel': 9,
    '2sa': 10, '2 sam': 10, '2sam': 10, '2 samuel': 10,
    '1ki': 11,
    '1 ki': 11,
    '3 kings': 11,
    '3ki': 11,
    '1kings': 11,
    '1 kings': 11,
    '2ki': 12,
    '2 ki': 12,
    '4 kings': 12,
    '4ki': 12,
    '2kings': 12,
    '2 kings': 12,
    '1ch': 13, '1 chron': 13, '1 par': 13, '1 paralip': 13, '1chron': 13,
    '2ch': 14, '2 chron': 14, '2 par': 14, '2 paralip': 14, '2chron': 14,
    'ezr': 15, 'esd': 15, 'esdras': 15, 'ezra': 15,
    'neh': 16, 'nehemiah': 16,
    'tob': 17, 'tobias': 17, 'tobit': 17,
    'jdt': 18, 'judith': 18,
    'est': 19, 'esth': 19, 'esther': 19,

    // Wisdom
    'job': 20,
    'psa': 21, 'ps': 21, 'pss': 21, 'psalm': 21, 'psalms': 21,
    'pro': 22, 'prov': 22, 'proverbs': 22,
    'ecc': 23, 'eccl': 23, 'eccles': 23, 'ecclesiastes': 23,
    'sng': 24, 'cant': 24, 'song': 24, 'canticle': 24,
    'wis': 25, 'wisd': 25, 'wisdom': 25,
    'sir': 26, 'ecclus': 26, 'sirach': 26, 'ecclesiasticus': 26,

    // Prophets
    'isa': 27, 'isaias': 27, 'isaiah': 27,
    'jer': 28, 'jeremias': 28, 'jeremiah': 28,
    'lam': 29, 'lamentations': 29,
    'bar': 30, 'baruch': 30,
    'ezk': 31, 'ezech': 31, 'ezekiel': 31,
    'dan': 32, 'daniel': 32,
    'hos': 33, 'osee': 33, 'hosea': 33,
    'jol': 34, 'joel': 34,
    'amo': 35, 'amos': 35,
    'oba': 36, 'abd': 36, 'obadiah': 36,
    'jon': 37, 'jonas': 37, 'jonah': 37,
    'mic': 38, 'mich': 38, 'micah': 38,
    'nam': 39, 'nah': 39, 'nahum': 39,
    'hab': 40, 'habacuc': 40, 'habakkuk': 40,
    'zep': 41, 'soph': 41, 'zephaniah': 41,
    'hag': 42, 'agg': 42, 'haggai': 42,
    'zec': 43, 'zach': 43, 'zechariah': 43,
    'mal': 44, 'malachias': 44, 'malachi': 44,
    '1ma': 45, '1 mach': 45, '1 macc': 45, '1 maccabees': 45,
    '2ma': 46, '2 mach': 46, '2 macc': 46, '2 maccabees': 46,

    // NT
    'mat': 47, 'matt': 47, 'st. matt': 47, 'matthew': 47,
    'mrk': 48, 'mark': 48, 'st. mark': 48,
    'luk': 49, 'luke': 49, 'st. luke': 49,
    'jhn': 50, 'john': 50, 'st. john': 50,
    'act': 51, 'acts': 51,
    'rom': 52, 'romans': 52,
    '1co': 53, '1 cor': 53, '1 corinthians': 53,
    '2co': 54, '2 cor': 54, '2 corinthians': 54,
    'gal': 55, 'galatians': 55,
    'eph': 56, 'ephesians': 56,
    'php': 57, 'phil': 57, 'philippians': 57,
    'col': 58, 'colossians': 58,
    '1th': 59, '1 thess': 59, '1 thessalonians': 59,
    '2th': 60, '2 thess': 60, '2 thessalonians': 60,
    '1ti': 61, '1 tim': 61, '1 timothy': 61,
    '2ti': 62, '2 tim': 62, '2 timothy': 62,
    'tit': 63, 'titus': 63,
    'phm': 64, 'philem': 64, 'philemon': 64,
    'heb': 65, 'hebrews': 65,
    'jas': 66, 'james': 66,
    '1pe': 67, '1 pet': 67, '1 peter': 67,
    '2pe': 68, '2 pet': 68, '2 peter': 68,
    '1jn': 69, '1 john': 69,
    '2jn': 70, '2 john': 70,
    '3jn': 71, '3 john': 71,
    'jud': 72, 'jude': 72,
    'rev': 73, 'apoc': 73, 'apocalypse': 73, 'revelation': 73,
  };

  static final RegExp _citationRegex = RegExp(
    r'\(?\b((?:1|2|3|4)?\s*(?:St\.\s*)?[A-Z][a-z]{1,12}\.?)\s*([0-9ivxlcdm]+)[\:\.\,\s]+([0-9ivxlcdm]+)(?:\-([0-9ivxlcdm]+))?\)?',
    caseSensitive: true,
  );

  static List<CitationSegment> parse(String input) {
    if (input.isEmpty) return [const CitationSegment.text('')];

    final segments = <CitationSegment>[];
    int lastOffset = 0;

    for (final match in _citationRegex.allMatches(input)) {
      final rawBook = match.group(1)!.trim().replaceAll('.', '');
      final rawChap = match.group(2)!.trim();
      final rawVerse = match.group(3)!.trim();
      final rawEndVerse = match.group(4)?.trim();

      final bookKey = rawBook.toLowerCase();
      final bookNum = _aliasToBookNumber[bookKey];

      if (bookNum == null) {
        continue;
      }

      final bookMetadata = catholicBooks.firstWhere(
        (b) => b.bookNumber == bookNum,
        orElse: () => catholicBooks[0],
      );

      final chapter = int.tryParse(rawChap) ?? _romanToDecimal(rawChap);
      final verse = int.tryParse(rawVerse) ?? _romanToDecimal(rawVerse);
      final endVerse = rawEndVerse != null
          ? (int.tryParse(rawEndVerse) ?? _romanToDecimal(rawEndVerse))
          : null;

      if (chapter <= 0 || verse <= 0) continue;

      if (match.start > lastOffset) {
        segments.add(
          CitationSegment.text(input.substring(lastOffset, match.start)),
        );
      }

      final displayLabel = endVerse != null
          ? '${bookMetadata.bookName} $chapter:$verse-$endVerse'
          : '${bookMetadata.bookName} $chapter:$verse';

      final citation = BibleCitation(
        rawMatch: match.group(0)!,
        displayLabel: displayLabel,
        bookNumber: bookNum,
        bookName: bookMetadata.bookName,
        abbrev: bookMetadata.abbrev,
        chapter: chapter,
        verse: verse,
        endVerse: endVerse,
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
