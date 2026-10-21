import 'prayers.dart';

export 'prayers.dart' show BibleNumberingSystem;

class _VerseShiftRule {
  final int vulgateChapter;
  final int vulgateStart;
  final int vulgateEnd;
  final int masoreticChapter;
  final int masoreticStart;
  final int masoreticEnd;
  final bool _includeVulgate;
  final bool _includeMasoretic;
  final bool _isBijective;

  const _VerseShiftRule.bijective({
    required this.vulgateChapter,
    required this.vulgateStart,
    required this.masoreticChapter,
    required this.masoreticStart,
    required int count,
  }) : vulgateEnd = vulgateStart + count - 1,
       masoreticEnd = masoreticStart + count - 1,
       _includeVulgate = true,
       _includeMasoretic = true,
       _isBijective = true;

  const _VerseShiftRule.vulgateOnly({
    required this.vulgateChapter,
    required this.vulgateStart,
    required this.vulgateEnd,
    required this.masoreticChapter,
    required int masoreticVerse,
  }) : masoreticStart = masoreticVerse,
       masoreticEnd = masoreticVerse,
       _includeVulgate = true,
       _includeMasoretic = false,
       _isBijective = false;

  const _VerseShiftRule.masoreticOnly({
    required this.masoreticChapter,
    required this.masoreticStart,
    required this.masoreticEnd,
    required this.vulgateChapter,
    required int vulgateVerse,
  }) : vulgateStart = vulgateVerse,
       vulgateEnd = vulgateVerse,
       _includeVulgate = false,
       _includeMasoretic = true,
       _isBijective = false;

  ({int chapter, int verse})? matchVulgate(int chapter, int verse) {
    if (!_includeVulgate ||
        chapter != vulgateChapter ||
        verse < vulgateStart ||
        verse > vulgateEnd) {
      return null;
    }
    if (_isBijective) {
      return (
        chapter: masoreticChapter,
        verse: masoreticStart + (verse - vulgateStart),
      );
    }
    return (chapter: masoreticChapter, verse: masoreticStart);
  }

  ({int chapter, int verse})? matchMasoretic(int chapter, int verse) {
    if (!_includeMasoretic ||
        chapter != masoreticChapter ||
        verse < masoreticStart ||
        verse > masoreticEnd) {
      return null;
    }
    if (_isBijective) {
      return (
        chapter: vulgateChapter,
        verse: vulgateStart + (verse - masoreticStart),
      );
    }
    return (chapter: vulgateChapter, verse: vulgateStart);
  }
}

class BibleVerseResolver {
  static const Map<int, List<_VerseShiftRule>> _bookShiftRules = {
    // Genesis (1)
    1: [
      _VerseShiftRule.bijective(
        vulgateChapter: 31,
        vulgateStart: 55,
        masoreticChapter: 32,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 32,
        vulgateStart: 1,
        masoreticChapter: 32,
        masoreticStart: 2,
        count: 32,
      ),
    ],
    // Exodus (2)
    2: [
      _VerseShiftRule.bijective(
        vulgateChapter: 8,
        vulgateStart: 1,
        masoreticChapter: 7,
        masoreticStart: 26,
        count: 4,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 8,
        vulgateStart: 5,
        masoreticChapter: 8,
        masoreticStart: 1,
        count: 28,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 22,
        vulgateStart: 1,
        masoreticChapter: 21,
        masoreticStart: 37,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 22,
        vulgateStart: 2,
        masoreticChapter: 22,
        masoreticStart: 1,
        count: 30,
      ),
    ],
    // Leviticus (3)
    3: [
      _VerseShiftRule.bijective(
        vulgateChapter: 6,
        vulgateStart: 1,
        masoreticChapter: 5,
        masoreticStart: 20,
        count: 7,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 6,
        vulgateStart: 8,
        masoreticChapter: 6,
        masoreticStart: 1,
        count: 23,
      ),
    ],
    // Numbers (4)
    4: [
      _VerseShiftRule.bijective(
        vulgateChapter: 16,
        vulgateStart: 36,
        masoreticChapter: 17,
        masoreticStart: 1,
        count: 15,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 17,
        vulgateStart: 1,
        masoreticChapter: 17,
        masoreticStart: 16,
        count: 13,
      ),
    ],
    // Deuteronomy (5)
    5: [
      _VerseShiftRule.bijective(
        vulgateChapter: 12,
        vulgateStart: 32,
        masoreticChapter: 13,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 13,
        vulgateStart: 1,
        masoreticChapter: 13,
        masoreticStart: 2,
        count: 18,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 22,
        vulgateStart: 30,
        masoreticChapter: 23,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 23,
        vulgateStart: 1,
        masoreticChapter: 23,
        masoreticStart: 2,
        count: 25,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 29,
        vulgateStart: 1,
        masoreticChapter: 28,
        masoreticStart: 69,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 29,
        vulgateStart: 2,
        masoreticChapter: 29,
        masoreticStart: 1,
        count: 28,
      ),
    ],
    // 1 Samuel (9)
    9: [
      _VerseShiftRule.bijective(
        vulgateChapter: 20,
        vulgateStart: 43,
        masoreticChapter: 21,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 21,
        vulgateStart: 1,
        masoreticChapter: 21,
        masoreticStart: 2,
        count: 15,
      ),
    ],
    // 2 Samuel (10)
    10: [
      _VerseShiftRule.bijective(
        vulgateChapter: 18,
        vulgateStart: 33,
        masoreticChapter: 19,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 19,
        vulgateStart: 1,
        masoreticChapter: 19,
        masoreticStart: 2,
        count: 43,
      ),
    ],
    // 1 Kings (11)
    11: [
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 21,
        masoreticChapter: 5,
        masoreticStart: 1,
        count: 14,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 5,
        vulgateStart: 1,
        masoreticChapter: 5,
        masoreticStart: 15,
        count: 18,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 22,
        vulgateStart: 44,
        vulgateEnd: 44,
        masoreticChapter: 22,
        masoreticVerse: 43,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 22,
        vulgateStart: 45,
        masoreticChapter: 22,
        masoreticStart: 44,
        count: 10,
      ),
    ],
    // 2 Kings (12)
    12: [
      _VerseShiftRule.bijective(
        vulgateChapter: 11,
        vulgateStart: 21,
        masoreticChapter: 12,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 12,
        vulgateStart: 1,
        masoreticChapter: 12,
        masoreticStart: 2,
        count: 21,
      ),
    ],
    // 1 Chronicles (13)
    13: [
      _VerseShiftRule.bijective(
        vulgateChapter: 6,
        vulgateStart: 1,
        masoreticChapter: 5,
        masoreticStart: 27,
        count: 15,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 6,
        vulgateStart: 16,
        masoreticChapter: 6,
        masoreticStart: 1,
        count: 66,
      ),
    ],
    // 2 Chronicles (14)
    14: [
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 1,
        masoreticChapter: 1,
        masoreticStart: 18,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 2,
        masoreticChapter: 2,
        masoreticStart: 1,
        count: 17,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 14,
        vulgateStart: 1,
        masoreticChapter: 13,
        masoreticStart: 23,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 14,
        vulgateStart: 2,
        masoreticChapter: 14,
        masoreticStart: 1,
        count: 14,
      ),
    ],
    // Nehemiah (16)
    16: [
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 1,
        masoreticChapter: 3,
        masoreticStart: 33,
        count: 6,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 7,
        masoreticChapter: 4,
        masoreticStart: 1,
        count: 17,
      ),
    ],
    // Job (20)
    20: [
      _VerseShiftRule.bijective(
        vulgateChapter: 39,
        vulgateStart: 31,
        masoreticChapter: 40,
        masoreticStart: 1,
        count: 5,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 40,
        vulgateStart: 1,
        masoreticChapter: 40,
        masoreticStart: 6,
        count: 19,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 40,
        vulgateStart: 20,
        masoreticChapter: 41,
        masoreticStart: 1,
        count: 9,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 41,
        vulgateStart: 1,
        masoreticChapter: 41,
        masoreticStart: 10,
        count: 25,
      ),
    ],
    // Ecclesiastes (23)
    23: [
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 17,
        masoreticChapter: 5,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 5,
        vulgateStart: 1,
        masoreticChapter: 5,
        masoreticStart: 2,
        count: 19,
      ),
    ],
    // Canticle of Canticles (24)
    24: [
      _VerseShiftRule.bijective(
        vulgateChapter: 7,
        vulgateStart: 1,
        masoreticChapter: 6,
        masoreticStart: 13,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 7,
        vulgateStart: 2,
        masoreticChapter: 7,
        masoreticStart: 1,
        count: 12,
      ),
    ],
    // Isaiah (27)
    27: [
      _VerseShiftRule.bijective(
        vulgateChapter: 9,
        vulgateStart: 1,
        masoreticChapter: 8,
        masoreticStart: 23,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 9,
        vulgateStart: 2,
        masoreticChapter: 9,
        masoreticStart: 1,
        count: 20,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 64,
        vulgateStart: 1,
        vulgateEnd: 1,
        masoreticChapter: 63,
        masoreticVerse: 19,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 64,
        vulgateStart: 2,
        masoreticChapter: 64,
        masoreticStart: 1,
        count: 11,
      ),
    ],
    // Jeremiah (28)
    28: [
      _VerseShiftRule.bijective(
        vulgateChapter: 9,
        vulgateStart: 1,
        masoreticChapter: 8,
        masoreticStart: 23,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 9,
        vulgateStart: 2,
        masoreticChapter: 9,
        masoreticStart: 1,
        count: 25,
      ),
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 37,
        masoreticStart: 12,
        masoreticEnd: 12,
        vulgateChapter: 37,
        vulgateVerse: 11,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 37,
        vulgateStart: 12,
        masoreticChapter: 37,
        masoreticStart: 13,
        count: 9,
      ),
    ],
    // Ezekiel (31)
    31: [
      _VerseShiftRule.bijective(
        vulgateChapter: 20,
        vulgateStart: 45,
        masoreticChapter: 21,
        masoreticStart: 1,
        count: 5,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 21,
        vulgateStart: 1,
        masoreticChapter: 21,
        masoreticStart: 6,
        count: 32,
      ),
    ],
    // Daniel (32)
    // Note: DRC Daniel 3:24-90 is the Greek addition (Song of the Three) and has no MT counterpart.
    32: [
      _VerseShiftRule.bijective(
        vulgateChapter: 3,
        vulgateStart: 91,
        masoreticChapter: 3,
        masoreticStart: 24,
        count: 10,
      ),
    ],
    // Hosea (33)
    33: [
      _VerseShiftRule.bijective(
        vulgateChapter: 1,
        vulgateStart: 10,
        masoreticChapter: 2,
        masoreticStart: 1,
        count: 2,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 1,
        masoreticChapter: 2,
        masoreticStart: 3,
        count: 23,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 2,
        vulgateStart: 24,
        vulgateEnd: 24,
        masoreticChapter: 2,
        masoreticVerse: 25,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 11,
        vulgateStart: 12,
        masoreticChapter: 12,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 12,
        vulgateStart: 1,
        masoreticChapter: 12,
        masoreticStart: 2,
        count: 14,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 14,
        vulgateStart: 1,
        masoreticChapter: 13,
        masoreticStart: 16,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 14,
        vulgateStart: 2,
        masoreticChapter: 14,
        masoreticStart: 1,
        count: 9,
      ),
    ],
    // Joel (34)
    34: [
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 28,
        masoreticChapter: 3,
        masoreticStart: 1,
        count: 5,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 3,
        vulgateStart: 1,
        masoreticChapter: 4,
        masoreticStart: 1,
        count: 21,
      ),
    ],
    // Jonah (37)
    37: [
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 1,
        masoreticChapter: 1,
        masoreticStart: 17,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 2,
        masoreticChapter: 2,
        masoreticStart: 1,
        count: 10,
      ),
    ],
    // Micah (38)
    38: [
      _VerseShiftRule.bijective(
        vulgateChapter: 5,
        vulgateStart: 1,
        masoreticChapter: 4,
        masoreticStart: 14,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 5,
        vulgateStart: 2,
        masoreticChapter: 5,
        masoreticStart: 1,
        count: 9,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 5,
        vulgateStart: 11,
        vulgateEnd: 11,
        masoreticChapter: 5,
        masoreticVerse: 10,
      ),
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 5,
        masoreticStart: 10,
        masoreticEnd: 11,
        vulgateChapter: 5,
        vulgateVerse: 11,
      ),
    ],
    // Nahum (39)
    39: [
      _VerseShiftRule.bijective(
        vulgateChapter: 1,
        vulgateStart: 15,
        masoreticChapter: 2,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 1,
        masoreticChapter: 2,
        masoreticStart: 2,
        count: 13,
      ),
    ],
    // Haggai (42)
    42: [
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 1,
        masoreticChapter: 1,
        masoreticStart: 15,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 2,
        masoreticChapter: 2,
        masoreticStart: 1,
        count: 23,
      ),
    ],
    // Zechariah (43)
    43: [
      _VerseShiftRule.bijective(
        vulgateChapter: 1,
        vulgateStart: 18,
        masoreticChapter: 2,
        masoreticStart: 1,
        count: 4,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 1,
        masoreticChapter: 2,
        masoreticStart: 5,
        count: 13,
      ),
    ],
    // Malachi (44)
    44: [
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 1,
        masoreticChapter: 3,
        masoreticStart: 19,
        count: 6,
      ),
    ],
  };

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

    final rules = _bookShiftRules[bookNumber];
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

    final rules = _bookShiftRules[bookNumber];
    if (rules != null) {
      for (final rule in rules) {
        final matched = rule.matchMasoretic(chapter, verse);
        if (matched != null) return matched;
      }
    }
    return (chapter: chapter, verse: verse);
  }

  /// Resolves a Modern/NABRE lectionary chapter and verse list to Vulgate/CPDV
  /// coordinates, applying shared Psalm/OT chapter shifts as well as CPDV
  /// verse-merge adjustments.
  static ({int chapter, List<int> verses}) mapLectionaryToVulgate({
    required int bookNumber,
    required int chapter,
    required List<int> verses,
  }) {
    // 1. Psalms (Book 21)
    if (bookNumber == 21 && chapter >= 1 && chapter <= 150) {
      // Hebrew Psalm 56 counts the superscription as verse 1; CPDV Psalm 55 does not.
      if (chapter == 56) {
        return (chapter: 55, verses: verses.map((v) => v - 1).toList());
      }
      final baseChapter = masoreticToVulgatePsalm(chapter);
      if (verses.isEmpty) {
        return (chapter: baseChapter, verses: verses);
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
      if (secondaryVerses.isNotEmpty) {
        return (chapter: baseChapter + 1, verses: secondaryVerses);
      }
      return (chapter: baseChapter, verses: primaryVerses);
    }

    // 2. Zechariah 2 (Hebrew 2:5-17 shifts by -4 to Vulgate 2:1-13)
    if (bookNumber == 43 && chapter == 2) {
      return (
        chapter: chapter,
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
      );
    }

    // 3. Malachi 3 (Hebrew 3:19-24 shifts into Vulgate 4:1-6)
    if (bookNumber == 44 && chapter == 3) {
      final List<int> versesCh3 = [];
      final List<int> versesCh4 = [];
      for (final v in verses) {
        final mapped = masoreticToVulgateVerse(
          bookNumber: 44,
          chapter: 3,
          verse: v,
        );
        if (mapped.chapter == 4) {
          versesCh4.add(mapped.verse);
        } else {
          versesCh3.add(mapped.verse);
        }
      }
      return versesCh4.isEmpty
          ? (chapter: 3, verses: versesCh3)
          : (chapter: 4, verses: versesCh4);
    }

    // 4. Joel 4 (Modern Joel 4 maps to Vulgate Joel 3)
    if (bookNumber == 34 && chapter == 4) {
      final mappedChapter = masoreticToVulgateVerse(
        bookNumber: 34,
        chapter: 4,
        verse: 1,
      ).chapter;
      return (chapter: mappedChapter, verses: verses);
    }

    // 5. CPDV-specific lectionary verse merges
    if (bookNumber == 53 && chapter == 14) {
      return (
        chapter: 14,
        verses: [for (final v in verses) v <= 20 ? v : v - 1],
      );
    }
    if (bookNumber == 50) {
      if (chapter == 4) {
        return (
          chapter: chapter,
          verses: [
            for (final v in verses)
              if (v <= 40) v,
          ],
        );
      }
      if (chapter == 9) {
        return (
          chapter: chapter,
          verses: [for (final v in verses) v <= 40 ? v : v - 1],
        );
      }
    }
    if (bookNumber == 1) {
      if (chapter == 32) {
        return (chapter: chapter, verses: verses.map((v) => v - 1).toList());
      }
      if (chapter == 50) {
        return (
          chapter: chapter,
          verses: [for (final v in verses) v >= 23 ? v - 1 : v],
        );
      }
    }
    if (bookNumber == 2 && chapter == 40) {
      return (
        chapter: chapter,
        verses: [for (final v in verses) v >= 34 ? v - 2 : v],
      );
    }
    if (bookNumber == 49 && chapter == 17) {
      return (
        chapter: chapter,
        verses: [for (final v in verses) v >= 22 ? v - 1 : v],
      );
    }
    if (bookNumber == 62 && chapter == 2) {
      return (
        chapter: chapter,
        verses: [for (final v in verses) v >= 14 ? v - 1 : v],
      );
    }
    if (bookNumber == 20 && chapter == 42) {
      return (
        chapter: chapter,
        verses: [for (final v in verses) v >= 17 ? 16 : v],
      );
    }

    return (chapter: chapter, verses: verses);
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
