enum VerseShiftType { bijective, vulgateOnly, masoreticOnly }

class VerseShiftRule {
  final VerseShiftType type;
  final int vulgateChapter;
  final int vulgateStart;
  final int vulgateEnd;
  final int masoreticChapter;
  final int masoreticStart;
  final int masoreticEnd;

  const VerseShiftRule.bijective({
    required this.vulgateChapter,
    required this.vulgateStart,
    required this.masoreticChapter,
    required this.masoreticStart,
    required int count,
  }) : type = VerseShiftType.bijective,
       vulgateEnd = vulgateStart + count - 1,
       masoreticEnd = masoreticStart + count - 1;

  const VerseShiftRule.vulgateOnly({
    required this.vulgateChapter,
    required this.vulgateStart,
    required this.vulgateEnd,
    required this.masoreticChapter,
    required int masoreticVerse,
  }) : type = VerseShiftType.vulgateOnly,
       masoreticStart = masoreticVerse,
       masoreticEnd = masoreticVerse;

  const VerseShiftRule.masoreticOnly({
    int? chapter,
    int? masoreticChapter,
    required this.masoreticStart,
    int? masoreticEnd,
    int? count,
    int? vulgateChapter,
    int? vulgateVerse,
    int? fallbackVulgateVerse,
  }) : type = VerseShiftType.masoreticOnly,
       masoreticChapter = masoreticChapter ?? chapter ?? 0,
       masoreticEnd = masoreticEnd ?? (masoreticStart + (count ?? 1) - 1),
       vulgateChapter = vulgateChapter ?? chapter ?? masoreticChapter ?? 0,
       vulgateStart = vulgateVerse ?? fallbackVulgateVerse ?? 0,
       vulgateEnd = vulgateVerse ?? fallbackVulgateVerse ?? 0;

  bool get isBijective => type == VerseShiftType.bijective;

  bool get includeVulgate =>
      type == VerseShiftType.bijective || type == VerseShiftType.vulgateOnly;

  bool get includeMasoretic =>
      type == VerseShiftType.bijective || type == VerseShiftType.masoreticOnly;

  ({int chapter, int verse})? matchVulgate(int chapter, int verse) {
    if (!includeVulgate ||
        chapter != vulgateChapter ||
        verse < vulgateStart ||
        verse > vulgateEnd) {
      return null;
    }
    if (isBijective) {
      return (
        chapter: masoreticChapter,
        verse: masoreticStart + (verse - vulgateStart),
      );
    }
    return (chapter: masoreticChapter, verse: masoreticStart);
  }

  ({int chapter, int verse})? matchMasoretic(int chapter, int verse) {
    if (!includeMasoretic ||
        chapter != masoreticChapter ||
        verse < masoreticStart ||
        verse > masoreticEnd) {
      return null;
    }
    if (isBijective) {
      return (
        chapter: vulgateChapter,
        verse: vulgateStart + (verse - masoreticStart),
      );
    }
    return (chapter: vulgateChapter, verse: vulgateStart);
  }
}

const Map<int, List<VerseShiftRule>> kBookShiftRules = {
  // Genesis (1)
  1: [
    VerseShiftRule.bijective(
      vulgateChapter: 31,
      vulgateStart: 55,
      masoreticChapter: 32,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 32,
      vulgateStart: 1,
      masoreticChapter: 32,
      masoreticStart: 2,
      count: 32,
    ),
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 50,
      masoreticStart: 22,
      masoreticEnd: 23,
      vulgateChapter: 50,
      vulgateVerse: 22,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 50,
      vulgateStart: 23,
      masoreticChapter: 50,
      masoreticStart: 24,
      count: 3,
    ),
  ],
  // Exodus (2)
  2: [
    VerseShiftRule.bijective(
      vulgateChapter: 8,
      vulgateStart: 1,
      masoreticChapter: 7,
      masoreticStart: 26,
      count: 4,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 8,
      vulgateStart: 5,
      masoreticChapter: 8,
      masoreticStart: 1,
      count: 28,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 22,
      vulgateStart: 1,
      masoreticChapter: 21,
      masoreticStart: 37,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 22,
      vulgateStart: 2,
      masoreticChapter: 22,
      masoreticStart: 1,
      count: 30,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 40,
      vulgateStart: 32,
      masoreticChapter: 40,
      masoreticStart: 34,
      count: 5,
    ),
  ],
  // Leviticus (3)
  3: [
    VerseShiftRule.bijective(
      vulgateChapter: 6,
      vulgateStart: 1,
      masoreticChapter: 5,
      masoreticStart: 20,
      count: 7,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 6,
      vulgateStart: 8,
      masoreticChapter: 6,
      masoreticStart: 1,
      count: 23,
    ),
  ],
  // Numbers (4)
  4: [
    VerseShiftRule.bijective(
      vulgateChapter: 16,
      vulgateStart: 36,
      masoreticChapter: 17,
      masoreticStart: 1,
      count: 15,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 17,
      vulgateStart: 1,
      masoreticChapter: 17,
      masoreticStart: 16,
      count: 13,
    ),
  ],
  // Deuteronomy (5)
  5: [
    VerseShiftRule.bijective(
      vulgateChapter: 12,
      vulgateStart: 32,
      masoreticChapter: 13,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 13,
      vulgateStart: 1,
      masoreticChapter: 13,
      masoreticStart: 2,
      count: 18,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 22,
      vulgateStart: 30,
      masoreticChapter: 23,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 23,
      vulgateStart: 1,
      masoreticChapter: 23,
      masoreticStart: 2,
      count: 25,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 29,
      vulgateStart: 1,
      masoreticChapter: 28,
      masoreticStart: 69,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 29,
      vulgateStart: 2,
      masoreticChapter: 29,
      masoreticStart: 1,
      count: 28,
    ),
  ],
  // 1 Samuel (9)
  9: [
    VerseShiftRule.bijective(
      vulgateChapter: 20,
      vulgateStart: 43,
      masoreticChapter: 21,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 21,
      vulgateStart: 1,
      masoreticChapter: 21,
      masoreticStart: 2,
      count: 15,
    ),
  ],
  // 2 Samuel (10)
  10: [
    VerseShiftRule.bijective(
      vulgateChapter: 18,
      vulgateStart: 33,
      masoreticChapter: 19,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 19,
      vulgateStart: 1,
      masoreticChapter: 19,
      masoreticStart: 2,
      count: 43,
    ),
  ],
  // 1 Kings (11)
  11: [
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 21,
      masoreticChapter: 5,
      masoreticStart: 1,
      count: 14,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 5,
      vulgateStart: 1,
      masoreticChapter: 5,
      masoreticStart: 15,
      count: 18,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 22,
      vulgateStart: 44,
      vulgateEnd: 44,
      masoreticChapter: 22,
      masoreticVerse: 43,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 22,
      vulgateStart: 45,
      masoreticChapter: 22,
      masoreticStart: 44,
      count: 10,
    ),
  ],
  // 2 Kings (12)
  12: [
    VerseShiftRule.bijective(
      vulgateChapter: 11,
      vulgateStart: 21,
      masoreticChapter: 12,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 12,
      vulgateStart: 1,
      masoreticChapter: 12,
      masoreticStart: 2,
      count: 21,
    ),
  ],
  // 1 Chronicles (13)
  13: [
    VerseShiftRule.bijective(
      vulgateChapter: 6,
      vulgateStart: 1,
      masoreticChapter: 5,
      masoreticStart: 27,
      count: 15,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 6,
      vulgateStart: 16,
      masoreticChapter: 6,
      masoreticStart: 1,
      count: 66,
    ),
  ],
  // 2 Chronicles (14)
  14: [
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 1,
      masoreticChapter: 1,
      masoreticStart: 18,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 2,
      masoreticChapter: 2,
      masoreticStart: 1,
      count: 17,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 14,
      vulgateStart: 1,
      masoreticChapter: 13,
      masoreticStart: 23,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 14,
      vulgateStart: 2,
      masoreticChapter: 14,
      masoreticStart: 1,
      count: 14,
    ),
  ],
  // Nehemiah (16)
  16: [
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 1,
      masoreticChapter: 3,
      masoreticStart: 33,
      count: 6,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 7,
      masoreticChapter: 4,
      masoreticStart: 1,
      count: 17,
    ),
  ],
  // Job (20)
  20: [
    VerseShiftRule.bijective(
      vulgateChapter: 39,
      vulgateStart: 31,
      masoreticChapter: 40,
      masoreticStart: 1,
      count: 5,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 40,
      vulgateStart: 1,
      masoreticChapter: 40,
      masoreticStart: 6,
      count: 19,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 40,
      vulgateStart: 20,
      masoreticChapter: 41,
      masoreticStart: 1,
      count: 9,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 41,
      vulgateStart: 1,
      masoreticChapter: 41,
      masoreticStart: 10,
      count: 25,
    ),
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 42,
      masoreticStart: 16,
      masoreticEnd: 18,
      vulgateChapter: 42,
      vulgateVerse: 16,
    ),
  ],
  // Ecclesiastes (23)
  23: [
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 17,
      masoreticChapter: 5,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 5,
      vulgateStart: 1,
      masoreticChapter: 5,
      masoreticStart: 2,
      count: 19,
    ),
  ],
  // Canticle of Canticles (24)
  24: [
    VerseShiftRule.bijective(
      vulgateChapter: 7,
      vulgateStart: 1,
      masoreticChapter: 6,
      masoreticStart: 13,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 7,
      vulgateStart: 2,
      masoreticChapter: 7,
      masoreticStart: 1,
      count: 12,
    ),
  ],
  // Sirach / Ecclesiasticus (26)
  26: [
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 2,
      vulgateStart: 10,
      vulgateEnd: 12,
      masoreticChapter: 2,
      masoreticVerse: 10,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 13,
      masoreticChapter: 2,
      masoreticStart: 11,
      count: 11,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 3,
      vulgateStart: 2,
      masoreticChapter: 3,
      masoreticStart: 1,
      count: 8,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 3,
      vulgateStart: 10,
      vulgateEnd: 10,
      masoreticChapter: 3,
      masoreticVerse: 8,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 3,
      vulgateStart: 11,
      masoreticChapter: 3,
      masoreticStart: 9,
      count: 6,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 3,
      vulgateStart: 17,
      vulgateEnd: 17,
      masoreticChapter: 3,
      masoreticVerse: 14,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 3,
      vulgateStart: 18,
      masoreticChapter: 3,
      masoreticStart: 16,
      count: 3,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 3,
      vulgateStart: 21,
      masoreticChapter: 3,
      masoreticStart: 20,
      count: 5,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 3,
      vulgateStart: 26,
      vulgateEnd: 26,
      masoreticChapter: 3,
      masoreticVerse: 24,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 3,
      vulgateStart: 27,
      masoreticChapter: 3,
      masoreticStart: 25,
      count: 7,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 3,
      vulgateStart: 34,
      vulgateEnd: 34,
      masoreticChapter: 3,
      masoreticVerse: 31,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 12,
      masoreticChapter: 4,
      masoreticStart: 11,
      count: 7,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 4,
      vulgateStart: 19,
      vulgateEnd: 19,
      masoreticChapter: 4,
      masoreticVerse: 17,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 20,
      masoreticChapter: 4,
      masoreticStart: 18,
      count: 1,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 4,
      vulgateStart: 21,
      vulgateEnd: 21,
      masoreticChapter: 4,
      masoreticVerse: 18,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 22,
      masoreticChapter: 4,
      masoreticStart: 19,
      count: 15,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 5,
      vulgateStart: 5,
      vulgateEnd: 5,
      masoreticChapter: 5,
      masoreticVerse: 4,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 5,
      vulgateStart: 6,
      masoreticChapter: 5,
      masoreticStart: 5,
      count: 3,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 5,
      vulgateStart: 9,
      vulgateEnd: 9,
      masoreticChapter: 5,
      masoreticVerse: 7,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 5,
      vulgateStart: 10,
      masoreticChapter: 5,
      masoreticStart: 8,
      count: 9,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 15,
      vulgateStart: 15,
      vulgateEnd: 15,
      masoreticChapter: 15,
      masoreticVerse: 14,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 15,
      vulgateStart: 16,
      masoreticChapter: 15,
      masoreticStart: 15,
      count: 7,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 27,
      vulgateStart: 4,
      vulgateEnd: 4,
      masoreticChapter: 27,
      masoreticVerse: 3,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 27,
      vulgateStart: 5,
      masoreticChapter: 27,
      masoreticStart: 4,
      count: 18,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 27,
      vulgateStart: 23,
      vulgateEnd: 24,
      masoreticChapter: 27,
      masoreticVerse: 21,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 27,
      vulgateStart: 25,
      masoreticChapter: 27,
      masoreticStart: 22,
      count: 2,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 27,
      vulgateStart: 27,
      vulgateEnd: 27,
      masoreticChapter: 27,
      masoreticVerse: 23,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 27,
      vulgateStart: 28,
      masoreticChapter: 27,
      masoreticStart: 25,
      count: 6,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 28,
      vulgateStart: 7,
      vulgateEnd: 7,
      masoreticChapter: 28,
      masoreticVerse: 6,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 28,
      vulgateStart: 8,
      masoreticChapter: 28,
      masoreticStart: 7,
      count: 1,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 28,
      vulgateStart: 9,
      vulgateEnd: 9,
      masoreticChapter: 28,
      masoreticVerse: 7,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 28,
      vulgateStart: 10,
      masoreticChapter: 28,
      masoreticStart: 8,
      count: 7,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 28,
      vulgateStart: 17,
      vulgateEnd: 18,
      masoreticChapter: 28,
      masoreticVerse: 14,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 28,
      vulgateStart: 19,
      masoreticChapter: 28,
      masoreticStart: 15,
      count: 12,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 35,
      vulgateStart: 2,
      vulgateEnd: 3,
      masoreticChapter: 35,
      masoreticVerse: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 35,
      vulgateStart: 4,
      masoreticChapter: 35,
      masoreticStart: 2,
      count: 9,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 35,
      vulgateStart: 13,
      vulgateEnd: 13,
      masoreticChapter: 35,
      masoreticVerse: 10,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 35,
      vulgateStart: 14,
      masoreticChapter: 35,
      masoreticStart: 11,
      count: 5,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 35,
      vulgateStart: 19,
      vulgateEnd: 19,
      masoreticChapter: 35,
      masoreticVerse: 15,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 35,
      vulgateStart: 20,
      masoreticChapter: 35,
      masoreticStart: 16,
      count: 7,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 36,
      vulgateStart: 2,
      vulgateEnd: 2,
      masoreticChapter: 36,
      masoreticVerse: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 36,
      vulgateStart: 3,
      masoreticChapter: 36,
      masoreticStart: 2,
      count: 6,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 36,
      vulgateStart: 9,
      vulgateEnd: 9,
      masoreticChapter: 36,
      masoreticVerse: 7,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 36,
      vulgateStart: 10,
      masoreticChapter: 36,
      masoreticStart: 8,
      count: 2,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 36,
      vulgateStart: 12,
      vulgateEnd: 12,
      masoreticChapter: 36,
      masoreticVerse: 9,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 36,
      vulgateStart: 13,
      masoreticChapter: 36,
      masoreticStart: 10,
      count: 6,
    ),
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 36,
      masoreticStart: 16,
      masoreticEnd: 17,
      vulgateChapter: 36,
      vulgateVerse: 19,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 36,
      vulgateStart: 19,
      vulgateEnd: 19,
      masoreticChapter: 36,
      masoreticVerse: 17,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 36,
      vulgateStart: 20,
      masoreticChapter: 36,
      masoreticStart: 18,
      count: 9,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 42,
      vulgateStart: 26,
      vulgateEnd: 26,
      masoreticChapter: 42,
      masoreticVerse: 25,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 47,
      vulgateStart: 12,
      vulgateEnd: 13,
      masoreticChapter: 47,
      masoreticVerse: 11,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 47,
      vulgateStart: 14,
      masoreticChapter: 47,
      masoreticStart: 12,
      count: 18,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 48,
      vulgateStart: 15,
      vulgateEnd: 15,
      masoreticChapter: 48,
      masoreticVerse: 14,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 48,
      vulgateStart: 16,
      masoreticChapter: 48,
      masoreticStart: 15,
      count: 13,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 51,
      vulgateStart: 2,
      vulgateEnd: 2,
      masoreticChapter: 51,
      masoreticVerse: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 51,
      vulgateStart: 3,
      masoreticChapter: 51,
      masoreticStart: 2,
      count: 2,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 51,
      vulgateStart: 5,
      vulgateEnd: 5,
      masoreticChapter: 51,
      masoreticVerse: 3,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 51,
      vulgateStart: 6,
      masoreticChapter: 51,
      masoreticStart: 4,
      count: 3,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 51,
      vulgateStart: 9,
      vulgateEnd: 9,
      masoreticChapter: 51,
      masoreticVerse: 6,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 51,
      vulgateStart: 10,
      masoreticChapter: 51,
      masoreticStart: 7,
      count: 2,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 51,
      vulgateStart: 12,
      vulgateEnd: 12,
      masoreticChapter: 51,
      masoreticVerse: 8,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 51,
      vulgateStart: 13,
      masoreticChapter: 51,
      masoreticStart: 9,
      count: 3,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 51,
      vulgateStart: 16,
      vulgateEnd: 16,
      masoreticChapter: 51,
      masoreticVerse: 11,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 51,
      vulgateStart: 17,
      masoreticChapter: 51,
      masoreticStart: 12,
      count: 8,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 51,
      vulgateStart: 25,
      masoreticChapter: 51,
      masoreticStart: 20,
      count: 1,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 51,
      vulgateStart: 26,
      vulgateEnd: 28,
      masoreticChapter: 51,
      masoreticVerse: 20,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 51,
      vulgateStart: 29,
      masoreticChapter: 51,
      masoreticStart: 21,
      count: 10,
    ),
  ],
  // Isaiah (27)
  27: [
    VerseShiftRule.bijective(
      vulgateChapter: 9,
      vulgateStart: 1,
      masoreticChapter: 8,
      masoreticStart: 23,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 9,
      vulgateStart: 2,
      masoreticChapter: 9,
      masoreticStart: 1,
      count: 20,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 64,
      vulgateStart: 1,
      vulgateEnd: 1,
      masoreticChapter: 63,
      masoreticVerse: 19,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 64,
      vulgateStart: 2,
      masoreticChapter: 64,
      masoreticStart: 1,
      count: 11,
    ),
  ],
  // Jeremiah (28)
  28: [
    VerseShiftRule.bijective(
      vulgateChapter: 9,
      vulgateStart: 1,
      masoreticChapter: 8,
      masoreticStart: 23,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 9,
      vulgateStart: 2,
      masoreticChapter: 9,
      masoreticStart: 1,
      count: 25,
    ),
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 37,
      masoreticStart: 12,
      masoreticEnd: 12,
      vulgateChapter: 37,
      vulgateVerse: 11,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 37,
      vulgateStart: 12,
      masoreticChapter: 37,
      masoreticStart: 13,
      count: 9,
    ),
  ],
  // Ezekiel (31)
  31: [
    VerseShiftRule.bijective(
      vulgateChapter: 20,
      vulgateStart: 45,
      masoreticChapter: 21,
      masoreticStart: 1,
      count: 5,
    ),
    VerseShiftRule.bijective(
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
    VerseShiftRule.bijective(
      vulgateChapter: 3,
      vulgateStart: 91,
      masoreticChapter: 3,
      masoreticStart: 24,
      count: 10,
    ),
  ],
  // Hosea (33)
  33: [
    VerseShiftRule.bijective(
      vulgateChapter: 1,
      vulgateStart: 10,
      masoreticChapter: 2,
      masoreticStart: 1,
      count: 2,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 1,
      masoreticChapter: 2,
      masoreticStart: 3,
      count: 23,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 2,
      vulgateStart: 24,
      vulgateEnd: 24,
      masoreticChapter: 2,
      masoreticVerse: 25,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 11,
      vulgateStart: 12,
      masoreticChapter: 12,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 12,
      vulgateStart: 1,
      masoreticChapter: 12,
      masoreticStart: 2,
      count: 14,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 14,
      vulgateStart: 1,
      masoreticChapter: 13,
      masoreticStart: 16,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 14,
      vulgateStart: 2,
      masoreticChapter: 14,
      masoreticStart: 1,
      count: 9,
    ),
  ],
  // Joel (34)
  34: [
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 28,
      masoreticChapter: 3,
      masoreticStart: 1,
      count: 5,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 3,
      vulgateStart: 1,
      masoreticChapter: 4,
      masoreticStart: 1,
      count: 21,
    ),
  ],
  // Jonah (37)
  37: [
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 1,
      masoreticChapter: 1,
      masoreticStart: 17,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 2,
      masoreticChapter: 2,
      masoreticStart: 1,
      count: 10,
    ),
  ],
  // Micah (38)
  38: [
    VerseShiftRule.bijective(
      vulgateChapter: 5,
      vulgateStart: 1,
      masoreticChapter: 4,
      masoreticStart: 14,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 5,
      vulgateStart: 2,
      masoreticChapter: 5,
      masoreticStart: 1,
      count: 9,
    ),
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 5,
      vulgateStart: 11,
      vulgateEnd: 11,
      masoreticChapter: 5,
      masoreticVerse: 10,
    ),
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 5,
      masoreticStart: 10,
      masoreticEnd: 11,
      vulgateChapter: 5,
      vulgateVerse: 11,
    ),
  ],
  // Nahum (39)
  39: [
    VerseShiftRule.bijective(
      vulgateChapter: 1,
      vulgateStart: 15,
      masoreticChapter: 2,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 1,
      masoreticChapter: 2,
      masoreticStart: 2,
      count: 13,
    ),
  ],
  // Haggai (42)
  42: [
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 1,
      masoreticChapter: 1,
      masoreticStart: 15,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 2,
      masoreticChapter: 2,
      masoreticStart: 1,
      count: 23,
    ),
  ],
  // Zechariah (43)
  43: [
    VerseShiftRule.bijective(
      vulgateChapter: 1,
      vulgateStart: 18,
      masoreticChapter: 2,
      masoreticStart: 1,
      count: 4,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 1,
      masoreticChapter: 2,
      masoreticStart: 5,
      count: 13,
    ),
  ],
  // Malachi (44)
  44: [
    VerseShiftRule.bijective(
      vulgateChapter: 4,
      vulgateStart: 1,
      masoreticChapter: 3,
      masoreticStart: 19,
      count: 6,
    ),
  ],
  // Matthew (49)
  49: [
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 17,
      masoreticStart: 21,
      masoreticEnd: 22,
      vulgateChapter: 17,
      vulgateVerse: 21,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 17,
      vulgateStart: 22,
      masoreticChapter: 17,
      masoreticStart: 23,
      count: 5,
    ),
  ],
  // Mark (50)
  50: [
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 4,
      masoreticStart: 40,
      masoreticEnd: 41,
      vulgateChapter: 4,
      vulgateVerse: 40,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 8,
      vulgateStart: 39,
      masoreticChapter: 9,
      masoreticStart: 1,
      count: 1,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 9,
      vulgateStart: 1,
      masoreticChapter: 9,
      masoreticStart: 2,
      count: 49,
    ),
  ],
  // John (52)
  52: [
    VerseShiftRule.vulgateOnly(
      vulgateChapter: 6,
      vulgateStart: 52,
      vulgateEnd: 52,
      masoreticChapter: 6,
      masoreticVerse: 51,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 6,
      vulgateStart: 53,
      masoreticChapter: 6,
      masoreticStart: 52,
      count: 20,
    ),
  ],
  // Acts (53)
  53: [
    // Acts 7: Masoretic 7:55-56 merged into Vulgate 7:55; Masoretic 7:57-60 = Vulgate 7:56-59.
    VerseShiftRule.masoreticOnly(
      chapter: 7,
      masoreticStart: 55,
      count: 2,
      fallbackVulgateVerse: 55,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 7,
      vulgateStart: 56,
      masoreticChapter: 7,
      masoreticStart: 57,
      count: 4,
    ),
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 14,
      masoreticStart: 20,
      masoreticEnd: 21,
      vulgateChapter: 14,
      vulgateVerse: 20,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 14,
      vulgateStart: 21,
      masoreticChapter: 14,
      masoreticStart: 22,
      count: 7,
    ),
  ],
  // 2 Thessalonians (62)
  62: [
    VerseShiftRule.masoreticOnly(
      masoreticChapter: 2,
      masoreticStart: 13,
      masoreticEnd: 14,
      vulgateChapter: 2,
      vulgateVerse: 13,
    ),
    VerseShiftRule.bijective(
      vulgateChapter: 2,
      vulgateStart: 14,
      masoreticChapter: 2,
      masoreticStart: 15,
      count: 3,
    ),
  ],
};
