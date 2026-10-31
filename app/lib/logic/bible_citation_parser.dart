import 'bible_metadata.dart';

export 'bible_numbering_mapper.dart'
    show BibleNumberingSystem, BibleVerseResolver;

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

  static final RegExp _citationRegex = RegExp(
    r'\(?\b((?:[1-4]\s*)?(?:St\.\s*|Saint\s*)?[A-Z][a-zA-Z]{1,16}(?:\s+of\s+[A-Za-z]+)?)'
    r'(?:'
    r'(?:\.?\s+|\.)([ivxlcdmIVXLCDM]+)'
    r'|'
    r'\.?\s*(\d{1,3})'
    r')'
    r'(?:\s*\[[0-9ivxlcdmIVXLCDM]{1,7}(?::\d{1,3}(?:\s*[\-\u2013\u2014]\s*\d{1,3})?)?\])?'
    r'('
    r'[\:\.\,\s]+([0-9ivxlcdmIVXLCDM]+)'
    r'(?:\s*[\-\u2013\u2014]\s*([0-9ivxlcdmIVXLCDM]+))?'
    r')?'
    r'\)?(?![a-zA-Z0-9])',
    caseSensitive: true,
  );

  static final RegExp _saintPrefixRegex = RegExp(r'^(?:st|saint)\s+');

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
      final rawVerseSuffix = match.group(4);
      final rawVerse = match.group(5)?.trim();
      final rawEndVerse = match.group(6)?.trim();

      var bookKey = rawBook
          .toLowerCase()
          .replaceAll(_saintPrefixRegex, '')
          .trim();
      final bookNum = catholicBookAliases[bookKey];

      if (bookNum == null) {
        continue;
      }

      final bookMetadata = catholicBooksByNumber[bookNum] ?? catholicBooks[0];

      final int chapter;
      if (rawRomanChap != null) {
        if (!_strictRomanRegex.hasMatch(rawRomanChap)) continue;
        chapter = _romanToDecimal(rawRomanChap);
      } else if (rawArabicChap != null) {
        chapter = int.tryParse(rawArabicChap) ?? 0;
      } else {
        continue;
      }

      final maxChapters = bookNum == 34 ? 4 : bookMetadata.chaptersCount;
      if (chapter < 1 || chapter > maxChapters) {
        continue;
      }

      int? verse;
      bool ignoreVerseSuffix = false;
      if (rawVerse != null) {
        verse = int.tryParse(rawVerse);
        if (verse == null &&
            rawRomanChap != null &&
            _strictRomanRegex.hasMatch(rawVerse)) {
          verse = _romanToDecimal(rawVerse);
        }
        if (verse == null) {
          ignoreVerseSuffix = true;
        } else if (verse < 1 || verse > 200) {
          continue;
        }
      }

      int? endVerse;
      if (!ignoreVerseSuffix && rawEndVerse != null) {
        endVerse = int.tryParse(rawEndVerse);
        if (endVerse == null &&
            rawRomanChap != null &&
            _strictRomanRegex.hasMatch(rawEndVerse)) {
          endVerse = _romanToDecimal(rawEndVerse);
        }
        if (endVerse == null ||
            endVerse < 1 ||
            endVerse > 200 ||
            (verse != null && endVerse < verse)) {
          continue;
        }
      }

      int matchStart = match.start;
      int matchEnd = match.end;
      String rawMatch = match.group(0)!;
      if (ignoreVerseSuffix && rawVerseSuffix != null) {
        if (rawMatch.endsWith(')')) {
          matchEnd -= rawVerseSuffix.length + 1;
          rawMatch = rawMatch.substring(
            0,
            rawMatch.length - rawVerseSuffix.length - 1,
          );
        } else {
          matchEnd -= rawVerseSuffix.length;
          rawMatch = rawMatch.substring(
            0,
            rawMatch.length - rawVerseSuffix.length,
          );
        }
      }
      final hasLeadingParen = rawMatch.startsWith('(');
      final hasTrailingParen = rawMatch.endsWith(')');
      if (hasLeadingParen && !hasTrailingParen) {
        matchStart += 1;
        rawMatch = rawMatch.substring(1);
      } else if (!hasLeadingParen && hasTrailingParen) {
        matchEnd -= 1;
        rawMatch = rawMatch.substring(0, rawMatch.length - 1);
      }

      if (matchStart > lastOffset) {
        segments.add(
          CitationSegment.text(input.substring(lastOffset, matchStart)),
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
        rawMatch: rawMatch,
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
      lastOffset = matchEnd;
    }

    if (lastOffset < input.length) {
      segments.add(CitationSegment.text(input.substring(lastOffset)));
    }

    return segments.isEmpty ? [CitationSegment.text(input)] : segments;
  }
}
