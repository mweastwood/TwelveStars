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
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 50,
        masoreticStart: 22,
        masoreticEnd: 23,
        vulgateChapter: 50,
        vulgateVerse: 22,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 50,
        vulgateStart: 23,
        masoreticChapter: 50,
        masoreticStart: 24,
        count: 3,
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
      _VerseShiftRule.bijective(
        vulgateChapter: 40,
        vulgateStart: 32,
        masoreticChapter: 40,
        masoreticStart: 34,
        count: 5,
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
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 42,
        masoreticStart: 16,
        masoreticEnd: 18,
        vulgateChapter: 42,
        vulgateVerse: 16,
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
    // Sirach / Ecclesiasticus (26)
    26: [
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 2,
        vulgateStart: 10,
        vulgateEnd: 12,
        masoreticChapter: 2,
        masoreticVerse: 10,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 13,
        masoreticChapter: 2,
        masoreticStart: 11,
        count: 11,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 3,
        vulgateStart: 2,
        masoreticChapter: 3,
        masoreticStart: 1,
        count: 6,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 3,
        vulgateStart: 9,
        masoreticChapter: 3,
        masoreticStart: 7,
        count: 8,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 3,
        vulgateStart: 17,
        vulgateEnd: 17,
        masoreticChapter: 3,
        masoreticVerse: 14,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 3,
        vulgateStart: 18,
        masoreticChapter: 3,
        masoreticStart: 16,
        count: 3,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 3,
        vulgateStart: 21,
        masoreticChapter: 3,
        masoreticStart: 20,
        count: 5,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 3,
        vulgateStart: 27,
        masoreticChapter: 3,
        masoreticStart: 25,
        count: 7,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 12,
        masoreticChapter: 4,
        masoreticStart: 11,
        count: 7,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 4,
        vulgateStart: 19,
        vulgateEnd: 19,
        masoreticChapter: 4,
        masoreticVerse: 17,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 20,
        masoreticChapter: 4,
        masoreticStart: 18,
        count: 1,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 4,
        vulgateStart: 21,
        vulgateEnd: 21,
        masoreticChapter: 4,
        masoreticVerse: 18,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 4,
        vulgateStart: 22,
        masoreticChapter: 4,
        masoreticStart: 19,
        count: 13,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 5,
        vulgateStart: 5,
        vulgateEnd: 5,
        masoreticChapter: 5,
        masoreticVerse: 4,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 5,
        vulgateStart: 6,
        masoreticChapter: 5,
        masoreticStart: 5,
        count: 3,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 5,
        vulgateStart: 9,
        vulgateEnd: 9,
        masoreticChapter: 5,
        masoreticVerse: 7,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 5,
        vulgateStart: 10,
        masoreticChapter: 5,
        masoreticStart: 8,
        count: 8,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 15,
        vulgateStart: 16,
        masoreticChapter: 15,
        masoreticStart: 15,
        count: 6,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 27,
        vulgateStart: 5,
        masoreticChapter: 27,
        masoreticStart: 4,
        count: 4,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 27,
        vulgateStart: 33,
        masoreticChapter: 27,
        masoreticStart: 30,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 28,
        vulgateStart: 8,
        masoreticChapter: 28,
        masoreticStart: 7,
        count: 1,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 28,
        vulgateStart: 9,
        vulgateEnd: 9,
        masoreticChapter: 28,
        masoreticVerse: 7,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 35,
        vulgateStart: 2,
        vulgateEnd: 3,
        masoreticChapter: 35,
        masoreticVerse: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 35,
        vulgateStart: 4,
        masoreticChapter: 35,
        masoreticStart: 2,
        count: 9,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 35,
        vulgateStart: 13,
        vulgateEnd: 13,
        masoreticChapter: 35,
        masoreticVerse: 10,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 35,
        vulgateStart: 14,
        masoreticChapter: 35,
        masoreticStart: 11,
        count: 5,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 35,
        vulgateStart: 20,
        masoreticChapter: 35,
        masoreticStart: 16,
        count: 7,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 36,
        vulgateStart: 2,
        vulgateEnd: 2,
        masoreticChapter: 36,
        masoreticVerse: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 36,
        vulgateStart: 13,
        masoreticChapter: 36,
        masoreticStart: 10,
        count: 6,
      ),
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 36,
        masoreticStart: 16,
        masoreticEnd: 17,
        vulgateChapter: 36,
        vulgateVerse: 19,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 42,
        vulgateStart: 26,
        vulgateEnd: 26,
        masoreticChapter: 42,
        masoreticVerse: 25,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 47,
        vulgateStart: 12,
        vulgateEnd: 13,
        masoreticChapter: 47,
        masoreticVerse: 11,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 48,
        vulgateStart: 15,
        vulgateEnd: 15,
        masoreticChapter: 48,
        masoreticVerse: 14,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 51,
        vulgateStart: 17,
        masoreticChapter: 51,
        masoreticStart: 12,
        count: 8,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 51,
        vulgateStart: 25,
        masoreticChapter: 51,
        masoreticStart: 20,
        count: 1,
      ),
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 51,
        vulgateStart: 26,
        vulgateEnd: 28,
        masoreticChapter: 51,
        masoreticVerse: 20,
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
    // Matthew (49)
    49: [
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 17,
        masoreticStart: 21,
        masoreticEnd: 22,
        vulgateChapter: 17,
        vulgateVerse: 21,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 17,
        vulgateStart: 22,
        masoreticChapter: 17,
        masoreticStart: 23,
        count: 5,
      ),
    ],
    // Mark (50)
    50: [
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 4,
        masoreticStart: 40,
        masoreticEnd: 41,
        vulgateChapter: 4,
        vulgateVerse: 40,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 8,
        vulgateStart: 39,
        masoreticChapter: 9,
        masoreticStart: 1,
        count: 1,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 9,
        vulgateStart: 1,
        masoreticChapter: 9,
        masoreticStart: 2,
        count: 49,
      ),
    ],
    // John (52)
    52: [
      _VerseShiftRule.vulgateOnly(
        vulgateChapter: 6,
        vulgateStart: 52,
        vulgateEnd: 52,
        masoreticChapter: 6,
        masoreticVerse: 51,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 6,
        vulgateStart: 53,
        masoreticChapter: 6,
        masoreticStart: 52,
        count: 20,
      ),
    ],
    // Acts (53)
    53: [
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 14,
        masoreticStart: 20,
        masoreticEnd: 21,
        vulgateChapter: 14,
        vulgateVerse: 20,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 14,
        vulgateStart: 21,
        masoreticChapter: 14,
        masoreticStart: 22,
        count: 7,
      ),
    ],
    // 2 Thessalonians (62)
    62: [
      _VerseShiftRule.masoreticOnly(
        masoreticChapter: 2,
        masoreticStart: 13,
        masoreticEnd: 14,
        vulgateChapter: 2,
        vulgateVerse: 13,
      ),
      _VerseShiftRule.bijective(
        vulgateChapter: 2,
        vulgateStart: 14,
        masoreticChapter: 2,
        masoreticStart: 15,
        count: 3,
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
    final rules = _bookShiftRules[bookNumber];
    if (rules != null) {
      for (final rule in rules) {
        if (!rule._isBijective &&
            rule._includeVulgate &&
            !rule._includeMasoretic &&
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
  /// Vulgate/CPDV chapter-verse ranges, applying [_bookShiftRules] globally
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
      if (secondaryVerses.isNotEmpty) {
        return [(chapter: baseChapter + 1, verses: secondaryVerses)];
      }
      return [(chapter: baseChapter, verses: primaryVerses)];
    }

    // 2. Catholic Lectionary (NABRE) chapters that already follow Vulgate
    // numbering (unlike Protestant/KJV numbering in _bookShiftRules):
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
      final mappedChapter = masoreticToVulgateVerse(
        bookNumber: bookNumber,
        chapter: chapter,
        verse: 1,
      ).chapter;
      return [(chapter: mappedChapter, verses: verses)];
    }

    // 5. General rule-driven mapping across all books in _bookShiftRules
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
