import 'bible_numbering_mapper.dart';

class BibleReference {
  final int bookNumber;
  final int chapter;
  final List<int> verses;

  BibleReference({
    required this.bookNumber,
    required this.chapter,
    required this.verses,
  });
}

List<int> parseVerseRange(String rangeStr) {
  final trimmed = rangeStr.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') {
    return const [];
  }
  final orIndex = trimmed.toLowerCase().indexOf(' or ');
  final primary = orIndex != -1
      ? trimmed.substring(0, orIndex).trim()
      : trimmed;
  final List<int> verses = [];
  final parts = primary.split(',');
  for (final part in parts) {
    final cleanPart = part.trim().replaceAll('–', '-').replaceAll('—', '-');
    if (cleanPart.contains('-')) {
      final subParts = cleanPart.split('-');
      if (subParts.length == 2) {
        final start = int.tryParse(subParts[0].trim());
        final end = int.tryParse(subParts[1].trim());
        if (start != null && end != null) {
          for (int i = start; i <= end; i++) {
            verses.add(i);
          }
        }
      }
    } else {
      final val = int.tryParse(cleanPart);
      if (val != null) {
        verses.add(val);
      }
    }
  }
  return verses;
}

final RegExp _alphaRegex = RegExp(r'[a-zA-Z]');
final RegExp _trailingDigitsRegex = RegExp(r'\d+$');
final RegExp _nonDigitsRegex = RegExp(r'[^\d]');
final RegExp _chapterCrossingRegex = RegExp(r'[\—\–\-]\s*(\d+)\s*\:');

String cleanVerseStr(String str) {
  final orIndex = str.toLowerCase().indexOf(' or ');
  final primary = orIndex != -1 ? str.substring(0, orIndex).trim() : str.trim();
  final clean = primary
      .replaceAll(' and ', ',')
      .replaceAll('&', ',')
      .replaceAll(';', ',');
  return clean.replaceAll(_alphaRegex, '');
}

BibleReference mapModernToVulgate(
  int bookNumber,
  int chapter,
  List<int> verses,
) {
  final mapped = BibleVerseResolver.mapLectionaryToVulgate(
    bookNumber: bookNumber,
    chapter: chapter,
    verses: verses,
  );
  return BibleReference(
    bookNumber: bookNumber,
    chapter: mapped.chapter,
    verses: mapped.verses,
  );
}

class ChapterVerseRange {
  final int chapter;

  /// Specific verses to include. If null, means the whole chapter,
  /// unless [startVerseLimit] or [endVerseLimit] is set.
  final List<int>? verses;

  /// If set, include all verses >= [startVerseLimit].
  final int? startVerseLimit;

  /// If set, include all verses <= [endVerseLimit].
  final int? endVerseLimit;

  const ChapterVerseRange({
    required this.chapter,
    this.verses,
    this.startVerseLimit,
    this.endVerseLimit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterVerseRange &&
          runtimeType == other.runtimeType &&
          chapter == other.chapter &&
          _listEquals(verses, other.verses) &&
          startVerseLimit == other.startVerseLimit &&
          endVerseLimit == other.endVerseLimit;

  @override
  int get hashCode =>
      chapter.hashCode ^
      (verses != null ? Object.hashAll(verses!) : 0) ^
      startVerseLimit.hashCode ^
      endVerseLimit.hashCode;

  @override
  String toString() {
    return 'ChapterVerseRange(chapter: $chapter, verses: $verses, startVerseLimit: $startVerseLimit, endVerseLimit: $endVerseLimit)';
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<ChapterVerseRange> resolveReadingRanges({
  required int bookNumber,
  required int defaultChapter,
  required String defaultVerseRange,
  required String citation,
}) {
  final orIndex = citation.toLowerCase().indexOf(' or ');
  final primaryCitation = orIndex != -1
      ? citation.substring(0, orIndex).trim()
      : citation;

  // Semicolon-separated cross-chapter citations (e.g., "Isaiah 63:16b-17, 19b; 64:2-7")
  if (primaryCitation.contains(';')) {
    final parts = primaryCitation.split(';');
    final List<ChapterVerseRange> result = [];

    // Process the first part
    final part1 = parts[0].trim();
    final colonIndex1 = part1.indexOf(':');
    if (colonIndex1 != -1) {
      final chapterPart = part1.substring(0, colonIndex1);
      final chapterMatch = _trailingDigitsRegex.firstMatch(chapterPart.trim());
      if (chapterMatch != null) {
        final ch1 = int.parse(chapterMatch.group(0)!);
        final versesStr1 = part1.substring(colonIndex1 + 1);
        final rawVerses1 = parseVerseRange(cleanVerseStr(versesStr1));
        final mappedRef1 = mapModernToVulgate(bookNumber, ch1, rawVerses1);
        result.add(
          ChapterVerseRange(
            chapter: mappedRef1.chapter,
            verses: mappedRef1.verses,
          ),
        );
      }
    }

    // Process subsequent parts
    for (int i = 1; i < parts.length; i++) {
      final part2 = parts[i].trim();
      final colonIndex2 = part2.indexOf(':');
      if (colonIndex2 != -1) {
        final ch2Str = part2
            .substring(0, colonIndex2)
            .replaceAll(_nonDigitsRegex, '');
        final ch2 = int.tryParse(ch2Str);
        if (ch2 != null) {
          final versesStr2 = part2.substring(colonIndex2 + 1);
          final rawVerses2 = parseVerseRange(cleanVerseStr(versesStr2));
          final mappedRef2 = mapModernToVulgate(bookNumber, ch2, rawVerses2);
          result.add(
            ChapterVerseRange(
              chapter: mappedRef2.chapter,
              verses: mappedRef2.verses,
            ),
          );
        }
      }
    }

    if (result.isNotEmpty) {
      return result;
    }
  }

  // Multi-chapter crossings (e.g. "Exodus 11:10—12:14", "2 Corinthians 3:15 - 4:1, 3-6")
  final crossingMatch = _chapterCrossingRegex.firstMatch(primaryCitation);
  if (crossingMatch != null) {
    final leftPart = primaryCitation.substring(0, crossingMatch.start).trim();
    final rightPart = primaryCitation.substring(crossingMatch.start + 1).trim();

    final colonIndex = rightPart.indexOf(':');
    if (colonIndex != -1) {
      final endChapterVal = int.tryParse(crossingMatch.group(1)!);

      if (endChapterVal != null) {
        // Parse start chapter and verses from leftPart of the citation
        int startChapterVal = defaultChapter;
        List<int> initialVersesList = const [];
        final leftColonIndex = leftPart.indexOf(':');
        if (leftColonIndex != -1) {
          final leftChapterPart = leftPart.substring(0, leftColonIndex);
          final leftChapterMatch = _trailingDigitsRegex.firstMatch(
            leftChapterPart.trim(),
          );
          if (leftChapterMatch != null) {
            startChapterVal = int.parse(leftChapterMatch.group(0)!);
          }
          final leftVersesStr = leftPart.substring(leftColonIndex + 1);
          initialVersesList = parseVerseRange(cleanVerseStr(leftVersesStr));
        } else {
          final cleanRange = cleanVerseStr(defaultVerseRange);
          initialVersesList = parseVerseRange(cleanRange);
        }

        final mappedRef = mapModernToVulgate(
          bookNumber,
          startChapterVal,
          initialVersesList,
        );

        final mappedEndRef = mapModernToVulgate(
          bookNumber,
          endChapterVal,
          const [],
        );
        final endChapter = mappedEndRef.chapter;

        if (endChapter != mappedRef.chapter) {
          final endVersesPart = rightPart.substring(colonIndex + 1);
          final endVerseStr = cleanVerseStr(endVersesPart);
          final rawEndVerses = parseVerseRange(endVerseStr);
          final mappedEndVerseRef = mapModernToVulgate(
            bookNumber,
            endChapterVal,
            rawEndVerses,
          );
          final endVerses = mappedEndVerseRef.verses;

          final startVerses = mappedRef.verses;
          final List<ChapterVerseRange> result = [];

          // 1. Add first chapter verses
          if (startVerses.isNotEmpty) {
            final startVerseLimit = startVerses.last;
            final specificVerses = startVerses.sublist(
              0,
              startVerses.length - 1,
            );
            result.add(
              ChapterVerseRange(
                chapter: mappedRef.chapter,
                verses: specificVerses.isNotEmpty ? specificVerses : null,
                startVerseLimit: startVerseLimit,
              ),
            );
          }

          // 2. Add intermediate chapters
          for (int c = mappedRef.chapter + 1; c < endChapter; c++) {
            result.add(ChapterVerseRange(chapter: c));
          }

          // 3. Add second chapter verses
          if (endVerses.isNotEmpty) {
            final hasCommaOrMultiple =
                endVerseStr.contains(',') ||
                (rawEndVerses.length > 1 && rawEndVerses.first != 1);
            if (hasCommaOrMultiple) {
              result.add(
                ChapterVerseRange(chapter: endChapter, verses: endVerses),
              );
            } else {
              final endVerseLimit = endVerses.last;
              result.add(
                ChapterVerseRange(
                  chapter: endChapter,
                  endVerseLimit: endVerseLimit,
                ),
              );
            }
          }

          return result;
        }
      }
    }
  }

  // Single chapter case:
  final cleanRange = cleanVerseStr(defaultVerseRange);
  final initialVersesList = parseVerseRange(cleanRange);
  final mappedRef = mapModernToVulgate(
    bookNumber,
    defaultChapter,
    initialVersesList,
  );
  return [
    ChapterVerseRange(
      chapter: mappedRef.chapter,
      verses: mappedRef.verses.isNotEmpty ? mappedRef.verses : null,
    ),
  ];
}
