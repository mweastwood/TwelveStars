import 'data/bible_verse_shift_rules.dart';
import 'prayers.dart';

export 'data/bible_verse_shift_rules.dart';
export 'prayers.dart' show BibleNumberingSystem;

class BibleVerseResolver {
  /// Resolves Vulgate Psalm chapter to Masoretic/Hebrew Psalm chapter number
  static int vulgateToMasoreticPsalm(int vulgatePsalm) {
    if (vulgatePsalm <= 8) {
      return vulgatePsalm;
    }
    if (vulgatePsalm == 9) {
      return 9;
    }
    if (vulgatePsalm >= 10 && vulgatePsalm <= 112) {
      return vulgatePsalm + 1;
    }
    if (vulgatePsalm == 113) {
      return 114;
    }
    if (vulgatePsalm == 114 || vulgatePsalm == 115) {
      return 116;
    }
    if (vulgatePsalm >= 116 && vulgatePsalm <= 145) {
      return vulgatePsalm + 1;
    }
    if (vulgatePsalm == 146 || vulgatePsalm == 147) {
      return 147;
    }
    if (vulgatePsalm >= 148 && vulgatePsalm <= 150) {
      return vulgatePsalm;
    }
    return vulgatePsalm;
  }

  /// Resolves Masoretic/Hebrew Psalm chapter to Vulgate Psalm chapter number
  static int masoreticToVulgatePsalm(int masoreticPsalm) {
    if (masoreticPsalm <= 8) {
      return masoreticPsalm;
    }
    if (masoreticPsalm == 9 || masoreticPsalm == 10) {
      return 9;
    }
    if (masoreticPsalm >= 11 && masoreticPsalm <= 113) {
      return masoreticPsalm - 1;
    }
    if (masoreticPsalm == 114 || masoreticPsalm == 115) {
      return 113;
    }
    if (masoreticPsalm == 116) {
      return 114;
    }
    if (masoreticPsalm >= 117 && masoreticPsalm <= 146) {
      return masoreticPsalm - 1;
    }
    if (masoreticPsalm == 147) {
      return 146;
    }
    if (masoreticPsalm >= 148 && masoreticPsalm <= 150) {
      return masoreticPsalm;
    }
    return masoreticPsalm;
  }

  /// Resolves Vulgate chapter and verse to Masoretic/Modern chapter and verse
  static ({int chapter, int verse}) vulgateToMasoreticVerse({
    required int bookNumber,
    required int chapter,
    required int verse,
  }) {
    if (bookNumber == 21) {
      if (chapter <= 8) {
        return (chapter: chapter, verse: verse);
      }
      if (chapter == 9) {
        return verse <= 21
            ? (chapter: 9, verse: verse)
            : (chapter: 10, verse: verse - 21);
      }
      if (chapter >= 10 && chapter <= 112) {
        return (chapter: chapter + 1, verse: verse);
      }
      if (chapter == 113) {
        return verse <= 8
            ? (chapter: 114, verse: verse)
            : (chapter: 115, verse: verse - 8);
      }
      if (chapter == 114) {
        return (chapter: 116, verse: verse);
      }
      if (chapter == 115) {
        return (chapter: 116, verse: verse + 9);
      }
      if (chapter >= 116 && chapter <= 145) {
        return (chapter: chapter + 1, verse: verse);
      }
      if (chapter == 146) {
        return (chapter: 147, verse: verse);
      }
      if (chapter == 147) {
        return (chapter: 147, verse: verse + 11);
      }
      return (chapter: chapter, verse: verse);
    }

    final rules = kBookShiftRules[bookNumber];
    if (rules != null) {
      for (final rule in rules) {
        final matched = rule.matchVulgate(chapter, verse);
        if (matched != null) return matched;
      }
    }
    return (chapter: chapter, verse: verse);
  }

  /// Resolves Masoretic/Modern chapter and verse to Vulgate chapter and verse
  static ({int chapter, int verse}) masoreticToVulgateVerse({
    required int bookNumber,
    required int chapter,
    required int verse,
  }) {
    if (bookNumber == 21) {
      if (chapter <= 8) {
        return (chapter: chapter, verse: verse);
      }
      if (chapter == 9) {
        return (chapter: 9, verse: verse);
      }
      if (chapter == 10) {
        return (chapter: 9, verse: verse + 21);
      }
      if (chapter >= 11 && chapter <= 113) {
        return (chapter: chapter - 1, verse: verse);
      }
      if (chapter == 114) {
        return (chapter: 113, verse: verse);
      }
      if (chapter == 115) {
        return (chapter: 113, verse: verse + 8);
      }
      if (chapter == 116) {
        return verse <= 9
            ? (chapter: 114, verse: verse)
            : (chapter: 115, verse: verse - 9);
      }
      if (chapter >= 117 && chapter <= 146) {
        return (chapter: chapter - 1, verse: verse);
      }
      if (chapter == 147) {
        return verse <= 11
            ? (chapter: 146, verse: verse)
            : (chapter: 147, verse: verse - 11);
      }
      return (chapter: chapter, verse: verse);
    }

    final rules = kBookShiftRules[bookNumber];
    if (rules != null) {
      for (final rule in rules) {
        final matched = rule.matchMasoretic(chapter, verse);
        if (matched != null) return matched;
      }
    }
    return (chapter: chapter, verse: verse);
  }

  /// Resolves a whole Masoretic/Modern chapter to its primary Vulgate chapter.
  static int masoreticToVulgateChapter({
    required int bookNumber,
    required int chapter,
  }) {
    if (bookNumber == 21 && chapter >= 1 && chapter <= 150) {
      return masoreticToVulgatePsalm(chapter);
    }
    final rules = kBookShiftRules[bookNumber];
    if (rules != null) {
      final hasSameChapter = rules.any(
        (r) => r.masoreticChapter == chapter && r.vulgateChapter == chapter,
      );
      if (hasSameChapter) {
        return chapter;
      }
    }
    return masoreticToVulgateVerse(
      bookNumber: bookNumber,
      chapter: chapter,
      verse: 1,
    ).chapter;
  }

  /// Resolves a Masoretic/Modern chapter and verse to all corresponding Vulgate
  /// chapters and verses (including additional Vulgate verses when a single
  /// Modern verse was split across multiple Vulgate verses).
  static List<({int chapter, int verse})> masoreticToVulgateVerses({
    required int bookNumber,
    required int chapter,
    required int verse,
  }) {
    final primary = masoreticToVulgateVerse(
      bookNumber: bookNumber,
      chapter: chapter,
      verse: verse,
    );
    final result = <({int chapter, int verse})>[primary];
    final rules = kBookShiftRules[bookNumber];
    if (rules != null) {
      for (final rule in rules) {
        if (!rule.isBijective &&
            rule.includeVulgate &&
            !rule.includeMasoretic &&
            rule.masoreticChapter == chapter &&
            verse >= rule.masoreticStart &&
            verse <= rule.masoreticEnd) {
          for (int v = rule.vulgateStart; v <= rule.vulgateEnd; v++) {
            final entry = (chapter: rule.vulgateChapter, verse: v);
            if (!result.contains(entry)) {
              result.add(entry);
            }
          }
        }
      }
    }
    return result;
  }

  /// Resolves a Modern/NABRE lectionary chapter and verse list to one or more
  /// Vulgate/CPDV chapter-verse ranges, applying [kBookShiftRules] globally
  /// while accounting for Catholic lectionary conventions.
  static List<({int chapter, List<int> verses})> mapLectionaryToVulgateRanges({
    required int bookNumber,
    required int chapter,
    required List<int> verses,
  }) {
    // 1. Psalms (Book 21)
    if (bookNumber == 21 && chapter >= 1 && chapter <= 150) {
      // Hebrew Psalm 56 counts the superscription as verse 1; CPDV Psalm 55 does not.
      if (chapter == 56) {
        return [
          (
            chapter: 55,
            verses: verses.map((v) => v > 1 ? v - 1 : 1).toSet().toList(),
          ),
        ];
      }
      final baseChapter = masoreticToVulgatePsalm(chapter);
      if (verses.isEmpty) {
        return [(chapter: baseChapter, verses: verses)];
      }
      final List<int> primaryVerses = [];
      final List<int> secondaryVerses = [];
      for (final v in verses) {
        final mapped = masoreticToVulgateVerse(
          bookNumber: 21,
          chapter: chapter,
          verse: v,
        );
        if (mapped.chapter == baseChapter) {
          primaryVerses.add(mapped.verse);
        } else {
          secondaryVerses.add(mapped.verse);
        }
      }
      if (primaryVerses.isNotEmpty && secondaryVerses.isNotEmpty) {
        return [
          (chapter: baseChapter, verses: primaryVerses),
          (chapter: baseChapter + 1, verses: secondaryVerses),
        ];
      }
      if (secondaryVerses.isNotEmpty) {
        return [(chapter: baseChapter + 1, verses: secondaryVerses)];
      }
      return [(chapter: baseChapter, verses: primaryVerses)];
    }

    // 2. Catholic Lectionary (NABRE) chapters that already follow Vulgate
    // numbering (unlike Protestant/KJV numbering in kBookShiftRules):
    // - Daniel 3 (32:3): NABRE includes the Deuterocanonical canticle (v24-90)
    // - Hosea 14 (33:14): NABRE numbers Hosea 14 as 14:1-10 (matching Vulgate)
    // - Jonah 2 (37:2): NABRE numbers Jonah 2 as 2:1-11 (matching Vulgate)
    if ((bookNumber == 32 && chapter == 3) ||
        (bookNumber == 33 && chapter == 14) ||
        (bookNumber == 37 && chapter == 2)) {
      return [(chapter: chapter, verses: verses)];
    }

    // 3. Single-chapter clamping conventions
    if (bookNumber == 1 && chapter == 32) {
      return [
        (
          chapter: 32,
          verses: verses.map((v) => v > 1 ? v - 1 : 1).toSet().toList(),
        ),
      ];
    }
    if (bookNumber == 43 && chapter == 2) {
      return [
        (
          chapter: 2,
          verses: [
            for (final v in verses)
              v >= 5
                  ? masoreticToVulgateVerse(
                      bookNumber: 43,
                      chapter: 2,
                      verse: v,
                    ).verse
                  : v,
          ],
        ),
      ];
    }
    if (bookNumber == 50 && chapter == 4) {
      return [
        (
          chapter: 4,
          verses: [
            for (final v in verses)
              if (v <= 40) v,
          ],
        ),
      ];
    }

    // 4. Whole-chapter citation (empty verse list)
    if (verses.isEmpty) {
      final mappedChapter = masoreticToVulgateChapter(
        bookNumber: bookNumber,
        chapter: chapter,
      );
      return [(chapter: mappedChapter, verses: verses)];
    }

    // 5. General rule-driven mapping across all books in kBookShiftRules
    final List<({int chapter, List<int> verses})> ranges = [];
    for (final v in verses) {
      final mappedList = masoreticToVulgateVerses(
        bookNumber: bookNumber,
        chapter: chapter,
        verse: v,
      );
      for (final mapped in mappedList) {
        if (ranges.isNotEmpty && ranges.last.chapter == mapped.chapter) {
          ranges.last.verses.add(mapped.verse);
        } else {
          final existingIdx = ranges.indexWhere(
            (r) => r.chapter == mapped.chapter,
          );
          if (existingIdx != -1) {
            ranges[existingIdx].verses.add(mapped.verse);
          } else {
            ranges.add((chapter: mapped.chapter, verses: [mapped.verse]));
          }
        }
      }
    }

    return ranges.isNotEmpty ? ranges : [(chapter: chapter, verses: verses)];
  }

  /// Resolves a Modern/NABRE lectionary chapter and verse list to Vulgate/CPDV
  /// coordinates, applying shared Psalm/OT chapter shifts as well as CPDV
  /// verse-merge adjustments.
  static ({int chapter, List<int> verses}) mapLectionaryToVulgate({
    required int bookNumber,
    required int chapter,
    required List<int> verses,
  }) {
    final ranges = mapLectionaryToVulgateRanges(
      bookNumber: bookNumber,
      chapter: chapter,
      verses: verses,
    );
    return ranges.first;
  }

  /// Formats chapter title for display in Bible tab and chapter header
  static String formatChapterTitle({
    required int bookNumber,
    required String bookName,
    required int chapter,
    required BibleNumberingSystem numberingSystem,
  }) {
    if (bookNumber != 21) {
      return '$bookName $chapter';
    }
    final vulgateNum = chapter;
    final masoreticNum = vulgateToMasoreticPsalm(vulgateNum);
    switch (numberingSystem) {
      case BibleNumberingSystem.vulgate:
        return '$bookName $vulgateNum';
      case BibleNumberingSystem.modern:
        return '$bookName $masoreticNum';
      case BibleNumberingSystem.dual:
        if (vulgateNum == masoreticNum) {
          return '$bookName $vulgateNum';
        }
        return '$bookName $vulgateNum (Modern $masoreticNum)';
    }
  }

  /// Formats chapter label for the chapter picker grid
  static String formatChapterPickerLabel({
    required int bookNumber,
    required int chapter,
    required BibleNumberingSystem numberingSystem,
  }) {
    if (bookNumber != 21) {
      return '$chapter';
    }
    final vulgateNum = chapter;
    final masoreticNum = vulgateToMasoreticPsalm(vulgateNum);
    switch (numberingSystem) {
      case BibleNumberingSystem.vulgate:
        return '$vulgateNum';
      case BibleNumberingSystem.modern:
        return '$masoreticNum';
      case BibleNumberingSystem.dual:
        if (vulgateNum == masoreticNum) {
          return '$vulgateNum';
        }
        return '$vulgateNum ($masoreticNum)';
    }
  }

  /// Formats verse display number and alternate number according to active numbering system
  static ({int displayVerseNumber, String? alternateVerseNumber})
  formatVerseDisplay({
    required int bookNumber,
    required int chapter,
    required int verseNumber,
    required BibleNumberingSystem numberingSystem,
  }) {
    final masoretic = vulgateToMasoreticVerse(
      bookNumber: bookNumber,
      chapter: chapter,
      verse: verseNumber,
    );

    switch (numberingSystem) {
      case BibleNumberingSystem.vulgate:
        return (displayVerseNumber: verseNumber, alternateVerseNumber: null);
      case BibleNumberingSystem.modern:
        return (
          displayVerseNumber: masoretic.verse,
          alternateVerseNumber: null,
        );
      case BibleNumberingSystem.dual:
        // In Psalms (bookNumber == 21), the psalm chapter shift is already conveyed in
        // the chapter title (e.g. "Psalms 22 (Modern 23)"), so alternate verse numbers are
        // only shown when the verse number itself diverges within the psalm.
        if (bookNumber == 21) {
          if (verseNumber == masoretic.verse) {
            return (
              displayVerseNumber: verseNumber,
              alternateVerseNumber: null,
            );
          }
          return (
            displayVerseNumber: verseNumber,
            alternateVerseNumber: '${masoretic.verse}',
          );
        }

        if (masoretic.chapter == chapter && masoretic.verse == verseNumber) {
          return (displayVerseNumber: verseNumber, alternateVerseNumber: null);
        }

        final altLabel = masoretic.chapter != chapter
            ? '${masoretic.chapter}:${masoretic.verse}'
            : '${masoretic.verse}';
        return (
          displayVerseNumber: verseNumber,
          alternateVerseNumber: altLabel,
        );
    }
  }
}
