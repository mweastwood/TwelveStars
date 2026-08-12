import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';

void main() {
  group('resolveReadingRanges unit tests - 115 cases', () {
    final testCases = <_TestCase>[
      // --- 1. Standard Single-Chapter Cases (20 cases) ---
      _TestCase(
        description: 'Simple range',
        bookNumber: 49, // Matthew
        defaultChapter: 5,
        defaultVerseRange: '1-12',
        citation: 'Matthew 5:1-12',
        expected: [
          const ChapterVerseRange(
            chapter: 5,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          ),
        ],
      ),
      _TestCase(
        description: 'Single verse',
        bookNumber: 49,
        defaultChapter: 5,
        defaultVerseRange: '14',
        citation: 'Matthew 5:14',
        expected: [
          const ChapterVerseRange(chapter: 5, verses: [14]),
        ],
      ),
      _TestCase(
        description: 'Comma separated verses',
        bookNumber: 49,
        defaultChapter: 5,
        defaultVerseRange: '13, 16',
        citation: 'Matthew 5:13, 16',
        expected: [
          const ChapterVerseRange(chapter: 5, verses: [13, 16]),
        ],
      ),
      _TestCase(
        description: 'Range and extra verses',
        bookNumber: 49,
        defaultChapter: 5,
        defaultVerseRange: '13-16, 18, 20',
        citation: 'Matthew 5:13-16, 18, 20',
        expected: [
          const ChapterVerseRange(chapter: 5, verses: [13, 14, 15, 16, 18, 20]),
        ],
      ),
      _TestCase(
        description: 'Whole chapter (all)',
        bookNumber: 50, // Mark
        defaultChapter: 1,
        defaultVerseRange: 'all',
        citation: 'Mark 1:all',
        expected: [const ChapterVerseRange(chapter: 1, verses: null)],
      ),
      _TestCase(
        description: 'Whole chapter (empty range)',
        bookNumber: 50,
        defaultChapter: 1,
        defaultVerseRange: '',
        citation: 'Mark 1',
        expected: [const ChapterVerseRange(chapter: 1, verses: null)],
      ),
      _TestCase(
        description: 'Verse with suffix a',
        bookNumber: 51, // Luke
        defaultChapter: 1,
        defaultVerseRange: '26-38a',
        citation: 'Luke 1:26-38a',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38],
          ),
        ],
      ),
      _TestCase(
        description: 'Verse with suffix b',
        bookNumber: 51,
        defaultChapter: 2,
        defaultVerseRange: '14b-20',
        citation: 'Luke 2:14b-20',
        expected: [
          const ChapterVerseRange(
            chapter: 2,
            verses: [14, 15, 16, 17, 18, 19, 20],
          ),
        ],
      ),
      _TestCase(
        description: 'Verse with suffix ab',
        bookNumber: 51,
        defaultChapter: 2,
        defaultVerseRange: '1-14ab',
        citation: 'Luke 2:1-14ab',
        expected: [
          const ChapterVerseRange(
            chapter: 2,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
          ),
        ],
      ),
      _TestCase(
        description: 'Verse with suffix cd',
        bookNumber: 51,
        defaultChapter: 2,
        defaultVerseRange: '9cd-12',
        citation: 'Luke 2:9cd-12',
        expected: [
          const ChapterVerseRange(chapter: 2, verses: [9, 10, 11, 12]),
        ],
      ),
      _TestCase(
        description: 'Range with mixed spaces',
        bookNumber: 52, // John
        defaultChapter: 3,
        defaultVerseRange: ' 16 - 21 ',
        citation: 'John 3: 16 - 21 ',
        expected: [
          const ChapterVerseRange(chapter: 3, verses: [16, 17, 18, 19, 20, 21]),
        ],
      ),
      _TestCase(
        description: 'John range and comma',
        bookNumber: 52,
        defaultChapter: 1,
        defaultVerseRange: '1-5, 9-14',
        citation: 'John 1:1-5, 9-14',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14],
          ),
        ],
      ),
      _TestCase(
        description: 'Romans citation',
        bookNumber: 54, // Romans
        defaultChapter: 1,
        defaultVerseRange: '1-7',
        citation: 'Romans 1:1-7',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4, 5, 6, 7]),
        ],
      ),
      _TestCase(
        description: '1 Corinthians citation',
        bookNumber: 55, // 1 Cor
        defaultChapter: 1,
        defaultVerseRange: '1-9',
        citation: '1 Corinthians 1:1-9',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
      ),
      _TestCase(
        description: 'Galatians citation',
        bookNumber: 57, // Galatians
        defaultChapter: 1,
        defaultVerseRange: '1-5',
        citation: 'Galatians 1:1-5',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4, 5]),
        ],
      ),
      _TestCase(
        description: 'Ephesians citation',
        bookNumber: 58, // Ephesians
        defaultChapter: 1,
        defaultVerseRange: '3-10',
        citation: 'Ephesians 1:3-10',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [3, 4, 5, 6, 7, 8, 9, 10],
          ),
        ],
      ),
      _TestCase(
        description: 'Philippians citation',
        bookNumber: 59, // Philippians
        defaultChapter: 1,
        defaultVerseRange: '1-11',
        citation: 'Philippians 1:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description: 'Colossians citation',
        bookNumber: 60, // Colossians
        defaultChapter: 1,
        defaultVerseRange: '1-8',
        citation: 'Colossians 1:1-8',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4, 5, 6, 7, 8]),
        ],
      ),
      _TestCase(
        description: '1 Thessalonians citation',
        bookNumber: 61, // 1 Thess
        defaultChapter: 1,
        defaultVerseRange: '1-5',
        citation: '1 Thessalonians 1:1-5',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4, 5]),
        ],
      ),
      _TestCase(
        description: 'James citation',
        bookNumber: 69, // James
        defaultChapter: 1,
        defaultVerseRange: '1-11',
        citation: 'James 1:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),

      // --- 2. Psalms Mappings (30 cases) ---
      _TestCase(
        description: 'Psalm 1 (Hebrew 1-8 mapping 1:1 to Vulgate 1-8)',
        bookNumber: 21,
        defaultChapter: 1,
        defaultVerseRange: '1-6',
        citation: 'Psalm 1:1-6',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4, 5, 6]),
        ],
      ),
      _TestCase(
        description: 'Psalm 8 (Hebrew 1-8 mapping 1:1 to Vulgate 1-8)',
        bookNumber: 21,
        defaultChapter: 8,
        defaultVerseRange: '1-9',
        citation: 'Psalm 8:1-9',
        expected: [
          const ChapterVerseRange(
            chapter: 8,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
      ),
      _TestCase(
        description: 'Psalm 9 (Hebrew 9 maps to Vulgate 9:1-21 directly)',
        bookNumber: 21,
        defaultChapter: 9,
        defaultVerseRange: '2-11',
        citation: 'Psalm 9:2-11',
        expected: [
          const ChapterVerseRange(
            chapter: 9,
            verses: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 10 (Hebrew 10:1-4 maps to Vulgate 9:22-25 with +21 offset)',
        bookNumber: 21,
        defaultChapter: 10,
        defaultVerseRange: '1-4',
        citation: 'Psalm 10:1-4',
        expected: [
          const ChapterVerseRange(chapter: 9, verses: [22, 23, 24, 25]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 11 (Hebrew 11-113 maps to Vulgate shifted by -1 chapter)',
        bookNumber: 21,
        defaultChapter: 11,
        defaultVerseRange: '1-7',
        citation: 'Psalm 11:1-7',
        expected: [
          const ChapterVerseRange(chapter: 10, verses: [1, 2, 3, 4, 5, 6, 7]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 23 (Hebrew 23 maps to Vulgate 22 with -1 chapter shift)',
        bookNumber: 21,
        defaultChapter: 23,
        defaultVerseRange: '1-6',
        citation: 'Psalm 23:1-6',
        expected: [
          const ChapterVerseRange(chapter: 22, verses: [1, 2, 3, 4, 5, 6]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 56 (Hebrew 56 maps to Vulgate 55 with -1 chapter and -1 verse shift)',
        bookNumber: 21,
        defaultChapter: 56,
        defaultVerseRange: '2-5',
        citation: 'Psalm 56:2-5',
        expected: [
          const ChapterVerseRange(chapter: 55, verses: [1, 2, 3, 4]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 95 (Hebrew 95 maps to Vulgate 94 with -1 chapter shift)',
        bookNumber: 21,
        defaultChapter: 95,
        defaultVerseRange: '1-7',
        citation: 'Psalm 95:1-7',
        expected: [
          const ChapterVerseRange(chapter: 94, verses: [1, 2, 3, 4, 5, 6, 7]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 113 (Hebrew 113 maps to Vulgate 112 with -1 chapter shift)',
        bookNumber: 21,
        defaultChapter: 113,
        defaultVerseRange: '1-8',
        citation: 'Psalm 113:1-8',
        expected: [
          const ChapterVerseRange(
            chapter: 112,
            verses: [1, 2, 3, 4, 5, 6, 7, 8],
          ),
        ],
      ),
      _TestCase(
        description: 'Psalm 114 (Hebrew 114 maps to Vulgate 113:1-8)',
        bookNumber: 21,
        defaultChapter: 114,
        defaultVerseRange: '1-8',
        citation: 'Psalm 114:1-8',
        expected: [
          const ChapterVerseRange(
            chapter: 113,
            verses: [1, 2, 3, 4, 5, 6, 7, 8],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 115 (Hebrew 115:1-3 maps to Vulgate 113:9-11 with +8 offset)',
        bookNumber: 21,
        defaultChapter: 115,
        defaultVerseRange: '1-3',
        citation: 'Psalm 115:1-3',
        expected: [
          const ChapterVerseRange(chapter: 113, verses: [9, 10, 11]),
        ],
      ),
      _TestCase(
        description: 'Psalm 116:1-9 (Hebrew 116:1-9 maps to Vulgate 114:1-9)',
        bookNumber: 21,
        defaultChapter: 116,
        defaultVerseRange: '1-9',
        citation: 'Psalm 116:1-9',
        expected: [
          const ChapterVerseRange(
            chapter: 114,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 116:10-15 (Hebrew 116:10-15 maps to Vulgate 115:1-6 with -9 offset)',
        bookNumber: 21,
        defaultChapter: 116,
        defaultVerseRange: '10-15',
        citation: 'Psalm 116:10-15',
        expected: [
          const ChapterVerseRange(chapter: 115, verses: [1, 2, 3, 4, 5, 6]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 116:8-12 (Spans across Vulgate split 114 & 115, return first match or 115 depending on content)',
        bookNumber: 21,
        defaultChapter: 116,
        defaultVerseRange: '8-12',
        citation: 'Psalm 116:8-12',
        expected: [
          const ChapterVerseRange(
            chapter: 115,
            verses: [1, 2, 3],
          ), // 10-12 maps to 115:1-3 (since verses115 is not empty)
        ],
      ),
      _TestCase(
        description:
            'Psalm 117 (Hebrew 117-146 maps to Vulgate shifted by -1 chapter)',
        bookNumber: 21,
        defaultChapter: 117,
        defaultVerseRange: '1-2',
        citation: 'Psalm 117:1-2',
        expected: [
          const ChapterVerseRange(chapter: 116, verses: [1, 2]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 136 (Hebrew 117-146 maps to Vulgate shifted by -1 chapter)',
        bookNumber: 21,
        defaultChapter: 136,
        defaultVerseRange: '1-9',
        citation: 'Psalm 136:1-9',
        expected: [
          const ChapterVerseRange(
            chapter: 135,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 146 (Hebrew 117-146 maps to Vulgate shifted by -1 chapter)',
        bookNumber: 21,
        defaultChapter: 146,
        defaultVerseRange: '1-10',
        citation: 'Psalm 146:1-10',
        expected: [
          const ChapterVerseRange(
            chapter: 145,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 147:1-11 (Hebrew 147:1-11 maps to Vulgate 146:1-11)',
        bookNumber: 21,
        defaultChapter: 147,
        defaultVerseRange: '1-11',
        citation: 'Psalm 147:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 146,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 147:12-20 (Hebrew 147:12-20 maps to Vulgate 147:1-9 with -11 offset)',
        bookNumber: 21,
        defaultChapter: 147,
        defaultVerseRange: '12-15',
        citation: 'Psalm 147:12-15',
        expected: [
          const ChapterVerseRange(chapter: 147, verses: [1, 2, 3, 4]),
        ],
      ),
      _TestCase(
        description:
            'Psalm 148 (Hebrew 148-150 map directly to Vulgate 148-150)',
        bookNumber: 21,
        defaultChapter: 148,
        defaultVerseRange: '1-14',
        citation: 'Psalm 148:1-14',
        expected: [
          const ChapterVerseRange(
            chapter: 148,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 149 (Hebrew 148-150 map directly to Vulgate 148-150)',
        bookNumber: 21,
        defaultChapter: 149,
        defaultVerseRange: '1-9',
        citation: 'Psalm 149:1-9',
        expected: [
          const ChapterVerseRange(
            chapter: 149,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
      ),
      _TestCase(
        description:
            'Psalm 150 (Hebrew 148-150 map directly to Vulgate 148-150)',
        bookNumber: 21,
        defaultChapter: 150,
        defaultVerseRange: '1-6',
        citation: 'Psalm 150:1-6',
        expected: [
          const ChapterVerseRange(chapter: 150, verses: [1, 2, 3, 4, 5, 6]),
        ],
      ),
      _TestCase(
        description: 'Psalm 103 (Hebrew 103 maps to Vulgate 102)',
        bookNumber: 21,
        defaultChapter: 103,
        defaultVerseRange: '1-4, 9-12',
        citation: 'Psalm 103:1-4, 9-12',
        expected: [
          const ChapterVerseRange(
            chapter: 102,
            verses: [1, 2, 3, 4, 9, 10, 11, 12],
          ),
        ],
      ),
      _TestCase(
        description: 'Psalm 138 (Hebrew 138 maps to Vulgate 137)',
        bookNumber: 21,
        defaultChapter: 138,
        defaultVerseRange: '1-3, 7-8',
        citation: 'Psalm 138:1-3, 7-8',
        expected: [
          const ChapterVerseRange(chapter: 137, verses: [1, 2, 3, 7, 8]),
        ],
      ),
      _TestCase(
        description: 'Psalm 145 (Hebrew 145 maps to Vulgate 144)',
        bookNumber: 21,
        defaultChapter: 145,
        defaultVerseRange: '1-2, 8-9, 10-11, 13-14',
        citation: 'Psalm 145:1-2, 8-9, 10-11, 13-14',
        expected: [
          const ChapterVerseRange(
            chapter: 144,
            verses: [1, 2, 8, 9, 10, 11, 13, 14],
          ),
        ],
      ),
      _TestCase(
        description: 'Psalm 116 semicolon-separated Vulgate 114 & 115',
        bookNumber: 21,
        defaultChapter: 116,
        defaultVerseRange: '1-9; 10-15',
        citation: 'Psalm 116:1-9; 116:10-15',
        expected: [
          const ChapterVerseRange(
            chapter: 114,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
          const ChapterVerseRange(chapter: 115, verses: [1, 2, 3, 4, 5, 6]),
        ],
      ),
      _TestCase(
        description: 'Psalm 147 semicolon-separated Vulgate 146 & 147',
        bookNumber: 21,
        defaultChapter: 147,
        defaultVerseRange: '1-11; 12-15',
        citation: 'Psalm 147:1-11; 147:12-15',
        expected: [
          const ChapterVerseRange(
            chapter: 146,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
          const ChapterVerseRange(chapter: 147, verses: [1, 2, 3, 4]),
        ],
      ),
      _TestCase(
        description: 'Psalm 51 (Hebrew 51 maps to Vulgate 50)',
        bookNumber: 21,
        defaultChapter: 51,
        defaultVerseRange: '3-4, 5-6, 12-13, 17',
        citation: 'Psalm 51:3-4, 5-6, 12-13, 17',
        expected: [
          const ChapterVerseRange(
            chapter: 50,
            verses: [3, 4, 5, 6, 12, 13, 17],
          ),
        ],
      ),
      _TestCase(
        description: 'Psalm 34 (Hebrew 34 maps to Vulgate 33)',
        bookNumber: 21,
        defaultChapter: 34,
        defaultVerseRange: '2-3, 4-5, 6-7, 8-9',
        citation: 'Psalm 34:2-3, 4-5, 6-7, 8-9',
        expected: [
          const ChapterVerseRange(
            chapter: 33,
            verses: [2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
      ),
      _TestCase(
        description: 'Psalm 22 (Hebrew 22 maps to Vulgate 21)',
        bookNumber: 21,
        defaultChapter: 22,
        defaultVerseRange: '8-9, 17-18a, 19-20, 23-24',
        citation: 'Psalm 22:8-9, 17-18a, 19-20, 23-24',
        expected: [
          const ChapterVerseRange(
            chapter: 21,
            verses: [8, 9, 17, 18, 19, 20, 23, 24],
          ),
        ],
      ),

      // --- 3. Semicolon-Separated Cross-Chapter Citations (15 cases) ---
      _TestCase(
        description: 'Isaiah semicolon citation 1',
        bookNumber: 27, // Isaiah
        defaultChapter: 63,
        defaultVerseRange: '16b-17, 19b; 64:2-7',
        citation: 'Isaiah 63:16b-17, 19b; 64:2-7',
        expected: [
          const ChapterVerseRange(chapter: 63, verses: [16, 17, 19]),
          const ChapterVerseRange(chapter: 64, verses: [2, 3, 4, 5, 6, 7]),
        ],
      ),
      _TestCase(
        description: 'Isaiah semicolon citation 2',
        bookNumber: 27,
        defaultChapter: 7,
        defaultVerseRange: '10-14; 8:10',
        citation: 'Isaiah 7:10-14; 8:10',
        expected: [
          const ChapterVerseRange(chapter: 7, verses: [10, 11, 12, 13, 14]),
          const ChapterVerseRange(chapter: 8, verses: [10]),
        ],
      ),
      _TestCase(
        description: 'Jeremiah semicolon citation',
        bookNumber: 28, // Jeremiah
        defaultChapter: 31,
        defaultVerseRange: '31-34; 32:1-2',
        citation: 'Jeremiah 31:31-34; 32:1-2',
        expected: [
          const ChapterVerseRange(chapter: 31, verses: [31, 32, 33, 34]),
          const ChapterVerseRange(chapter: 32, verses: [1, 2]),
        ],
      ),
      _TestCase(
        description: 'Zechariah semicolon citation',
        bookNumber: 43, // Zechariah
        defaultChapter: 9,
        defaultVerseRange: '9-10; 10:1',
        citation: 'Zechariah 9:9-10; 10:1',
        expected: [
          const ChapterVerseRange(chapter: 9, verses: [9, 10]),
          const ChapterVerseRange(chapter: 10, verses: [1]),
        ],
      ),
      _TestCase(
        description: 'Matthew semicolon citation',
        bookNumber: 49,
        defaultChapter: 11,
        defaultVerseRange: '25-30; 12:1-2',
        citation: 'Matthew 11:25-30; 12:1-2',
        expected: [
          const ChapterVerseRange(
            chapter: 11,
            verses: [25, 26, 27, 28, 29, 30],
          ),
          const ChapterVerseRange(chapter: 12, verses: [1, 2]),
        ],
      ),
      _TestCase(
        description: 'Luke semicolon citation 1',
        bookNumber: 51,
        defaultChapter: 11,
        defaultVerseRange: '1-4; 11:5-13',
        citation: 'Luke 11:1-4; 11:5-13',
        expected: [
          const ChapterVerseRange(chapter: 11, verses: [1, 2, 3, 4]),
          const ChapterVerseRange(
            chapter: 11,
            verses: [5, 6, 7, 8, 9, 10, 11, 12, 13],
          ),
        ],
      ),
      _TestCase(
        description: 'Luke semicolon citation 2',
        bookNumber: 51,
        defaultChapter: 24,
        defaultVerseRange: '13-35; 24:36-48',
        citation: 'Luke 24:13-35; 24:36-48',
        expected: [
          const ChapterVerseRange(
            chapter: 24,
            verses: [
              13,
              14,
              15,
              16,
              17,
              18,
              19,
              20,
              21,
              22,
              23,
              24,
              25,
              26,
              27,
              28,
              29,
              30,
              31,
              32,
              33,
              34,
              35,
            ],
          ),
          const ChapterVerseRange(
            chapter: 24,
            verses: [36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48],
          ),
        ],
      ),
      _TestCase(
        description: 'John semicolon citation',
        bookNumber: 52,
        defaultChapter: 14,
        defaultVerseRange: '15-21; 14:23-29',
        citation: 'John 14:15-21; 14:23-29',
        expected: [
          const ChapterVerseRange(
            chapter: 14,
            verses: [15, 16, 17, 18, 19, 20, 21],
          ),
          const ChapterVerseRange(
            chapter: 14,
            verses: [23, 24, 25, 26, 27, 28, 29],
          ),
        ],
      ),
      _TestCase(
        description: 'Romans semicolon citation',
        bookNumber: 54,
        defaultChapter: 8,
        defaultVerseRange: '18-25; 8:26-27',
        citation: 'Romans 8:18-25; 8:26-27',
        expected: [
          const ChapterVerseRange(
            chapter: 8,
            verses: [18, 19, 20, 21, 22, 23, 24, 25],
          ),
          const ChapterVerseRange(chapter: 8, verses: [26, 27]),
        ],
      ),
      _TestCase(
        description: '1 Corinthians semicolon citation',
        bookNumber: 55,
        defaultChapter: 12,
        defaultVerseRange: '4-11; 12:12-31',
        citation: '1 Corinthians 12:4-11; 12:12-31',
        expected: [
          const ChapterVerseRange(
            chapter: 12,
            verses: [4, 5, 6, 7, 8, 9, 10, 11],
          ),
          const ChapterVerseRange(
            chapter: 12,
            verses: [
              12,
              13,
              14,
              15,
              16,
              17,
              18,
              19,
              20,
              21,
              22,
              23,
              24,
              25,
              26,
              27,
              28,
              29,
              30,
              31,
            ],
          ),
        ],
      ),
      _TestCase(
        description: '2 Corinthians semicolon citation',
        bookNumber: 56, // 2 Cor
        defaultChapter: 5,
        defaultVerseRange: '14-21; 6:1-2',
        citation: '2 Corinthians 5:14-21; 6:1-2',
        expected: [
          const ChapterVerseRange(
            chapter: 5,
            verses: [14, 15, 16, 17, 18, 19, 20, 21],
          ),
          const ChapterVerseRange(chapter: 6, verses: [1, 2]),
        ],
      ),
      _TestCase(
        description: 'Hebrews semicolon citation',
        bookNumber: 68,
        defaultChapter: 11,
        defaultVerseRange: '1-2, 8-19; 12:1-2',
        citation: 'Hebrews 11:1-2, 8-19; 12:1-2',
        expected: [
          const ChapterVerseRange(
            chapter: 11,
            verses: [1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
          ),
          const ChapterVerseRange(chapter: 12, verses: [1, 2]),
        ],
      ),
      _TestCase(
        description: '1 John semicolon citation',
        bookNumber: 72,
        defaultChapter: 4,
        defaultVerseRange: '7-10; 4:11-16',
        citation: '1 John 4:7-10; 4:11-16',
        expected: [
          const ChapterVerseRange(chapter: 4, verses: [7, 8, 9, 10]),
          const ChapterVerseRange(chapter: 4, verses: [11, 12, 13, 14, 15, 16]),
        ],
      ),
      _TestCase(
        description: 'Revelation semicolon citation',
        bookNumber: 76,
        defaultChapter: 21,
        defaultVerseRange: '1-8; 21:9-27',
        citation: 'Revelation 21:1-8; 21:9-27',
        expected: [
          const ChapterVerseRange(
            chapter: 21,
            verses: [1, 2, 3, 4, 5, 6, 7, 8],
          ),
          const ChapterVerseRange(
            chapter: 21,
            verses: [
              9,
              10,
              11,
              12,
              13,
              14,
              15,
              16,
              17,
              18,
              19,
              20,
              21,
              22,
              23,
              24,
              25,
              26,
              27,
            ],
          ),
        ],
      ),
      _TestCase(
        description: 'Genesis semicolon citation',
        bookNumber: 1,
        defaultChapter: 1,
        defaultVerseRange: '1-2; 2:1-4',
        citation: 'Genesis 1:1-2; 2:1-4',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2]),
          const ChapterVerseRange(chapter: 2, verses: [1, 2, 3, 4]),
        ],
      ),

      // --- 4. Multi-Chapter Crossings (15 cases) ---
      _TestCase(
        description: 'Exodus em-dash chapter crossing',
        bookNumber: 2,
        defaultChapter: 11,
        defaultVerseRange: '11:10—12:14',
        citation: 'Exodus 11:10—12:14',
        expected: [
          const ChapterVerseRange(
            chapter: 11,
            verses: null,
            startVerseLimit: 10,
          ),
          const ChapterVerseRange(chapter: 12, verses: null, endVerseLimit: 14),
        ],
      ),
      _TestCase(
        description: '1 Kings en-dash crossing with comma in end part',
        bookNumber: 11, // 1 Kings
        defaultChapter: 19,
        defaultVerseRange: '9a, 11-16',
        citation: '1 Kings 19:9a, 11–19:16',
        expected: [
          const ChapterVerseRange(
            chapter: 19,
            verses: [9, 11, 12, 13, 14, 15, 16],
          ),
        ],
      ),
      _TestCase(
        description: 'Genesis hyphen crossing',
        bookNumber: 1,
        defaultChapter: 1,
        defaultVerseRange: '1:31-2:3',
        citation: 'Genesis 1:31-2:3',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: null,
            startVerseLimit: 31,
          ),
          const ChapterVerseRange(chapter: 2, verses: null, endVerseLimit: 3),
        ],
      ),
      _TestCase(
        description: 'Mark multi-chapter crossing',
        bookNumber: 50,
        defaultChapter: 1,
        defaultVerseRange: '1:40—2:12',
        citation: 'Mark 1:40—2:12',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: null,
            startVerseLimit: 40,
          ),
          const ChapterVerseRange(chapter: 2, verses: null, endVerseLimit: 12),
        ],
      ),
      _TestCase(
        description: 'Luke multi-chapter crossing',
        bookNumber: 51,
        defaultChapter: 2,
        defaultVerseRange: '2:41—3:6',
        expected: [
          const ChapterVerseRange(
            chapter: 2,
            verses: null,
            startVerseLimit: 41,
          ),
          const ChapterVerseRange(chapter: 3, verses: null, endVerseLimit: 6),
        ],
        citation: 'Luke 2:41—3:6',
      ),
      _TestCase(
        description: 'John multi-chapter crossing',
        bookNumber: 52,
        defaultChapter: 13,
        defaultVerseRange: '13:31—14:6',
        expected: [
          const ChapterVerseRange(
            chapter: 13,
            verses: null,
            startVerseLimit: 31,
          ),
          const ChapterVerseRange(chapter: 14, verses: null, endVerseLimit: 6),
        ],
        citation: 'John 13:31—14:6',
      ),
      _TestCase(
        description: 'Acts multi-chapter crossing',
        bookNumber: 53,
        defaultChapter: 4,
        defaultVerseRange: '4:32—5:11',
        expected: [
          const ChapterVerseRange(
            chapter: 4,
            verses: null,
            startVerseLimit: 32,
          ),
          const ChapterVerseRange(chapter: 5, verses: null, endVerseLimit: 11),
        ],
        citation: 'Acts 4:32—5:11',
      ),
      _TestCase(
        description: '1 Corinthians multi-chapter crossing',
        bookNumber: 55,
        defaultChapter: 10,
        defaultVerseRange: '10:31—11:1',
        expected: [
          const ChapterVerseRange(
            chapter: 10,
            verses: null,
            startVerseLimit: 31,
          ),
          const ChapterVerseRange(chapter: 11, verses: null, endVerseLimit: 1),
        ],
        citation: '1 Corinthians 10:31—11:1',
      ),
      _TestCase(
        description: '2 Corinthians multi-chapter crossing',
        bookNumber: 56,
        defaultChapter: 5,
        defaultVerseRange: '5:20—6:2',
        expected: [
          const ChapterVerseRange(
            chapter: 5,
            verses: null,
            startVerseLimit: 20,
          ),
          const ChapterVerseRange(chapter: 6, verses: null, endVerseLimit: 2),
        ],
        citation: '2 Corinthians 5:20—6:2',
      ),
      _TestCase(
        description: 'Philippians multi-chapter crossing',
        bookNumber: 59,
        defaultChapter: 3,
        defaultVerseRange: '3:17—4:1',
        expected: [
          const ChapterVerseRange(
            chapter: 3,
            verses: null,
            startVerseLimit: 17,
          ),
          const ChapterVerseRange(chapter: 4, verses: null, endVerseLimit: 1),
        ],
        citation: 'Philippians 3:17—4:1',
      ),
      _TestCase(
        description: 'Colossians multi-chapter crossing',
        bookNumber: 60,
        defaultChapter: 3,
        defaultVerseRange: '3:18—4:1',
        expected: [
          const ChapterVerseRange(
            chapter: 3,
            verses: null,
            startVerseLimit: 18,
          ),
          const ChapterVerseRange(chapter: 4, verses: null, endVerseLimit: 1),
        ],
        citation: 'Colossians 3:18—4:1',
      ),
      _TestCase(
        description: '1 Thessalonians multi-chapter crossing',
        bookNumber: 61,
        defaultChapter: 4,
        defaultVerseRange: '4:13—5:11',
        expected: [
          const ChapterVerseRange(
            chapter: 4,
            verses: null,
            startVerseLimit: 13,
          ),
          const ChapterVerseRange(chapter: 5, verses: null, endVerseLimit: 11),
        ],
        citation: '1 Thessalonians 4:13—5:11',
      ),
      _TestCase(
        description: 'Hebrews multi-chapter crossing',
        bookNumber: 68,
        defaultChapter: 12,
        defaultVerseRange: '12:18—13:8',
        expected: [
          const ChapterVerseRange(
            chapter: 12,
            verses: null,
            startVerseLimit: 18,
          ),
          const ChapterVerseRange(chapter: 13, verses: null, endVerseLimit: 8),
        ],
        citation: 'Hebrews 12:18—13:8',
      ),
      _TestCase(
        description: '1 John multi-chapter crossing',
        bookNumber: 72,
        defaultChapter: 2,
        defaultVerseRange: '2:29—3:6',
        expected: [
          const ChapterVerseRange(
            chapter: 2,
            verses: null,
            startVerseLimit: 29,
          ),
          const ChapterVerseRange(chapter: 3, verses: null, endVerseLimit: 6),
        ],
        citation: '1 John 2:29—3:6',
      ),
      _TestCase(
        description: 'Revelation multi-chapter crossing',
        bookNumber: 76,
        defaultChapter: 21,
        defaultVerseRange: '21:9—22:5',
        expected: [
          const ChapterVerseRange(
            chapter: 21,
            verses: null,
            startVerseLimit: 9,
          ),
          const ChapterVerseRange(chapter: 22, verses: null, endVerseLimit: 5),
        ],
        citation: 'Revelation 21:9—22:5',
      ),

      // --- 5. Other Specific Vulgate Mappings (20 cases) ---
      _TestCase(
        description:
            'Zechariah shift: Zechariah 2:5-10 shifts to 2:1-6 (-4 verses)',
        bookNumber: 43,
        defaultChapter: 2,
        defaultVerseRange: '5-10',
        citation: 'Zechariah 2:5-10',
        expected: [
          const ChapterVerseRange(chapter: 2, verses: [1, 2, 3, 4, 5, 6]),
        ],
      ),
      _TestCase(
        description:
            'Zechariah shift boundary: Zechariah 2:1-10 shifts verses >= 5 by -4',
        bookNumber: 43,
        defaultChapter: 2,
        defaultVerseRange: '1-10',
        citation: 'Zechariah 2:1-10',
        expected: [
          const ChapterVerseRange(
            chapter: 2,
            verses: [1, 2, 3, 4, 1, 2, 3, 4, 5, 6],
          ),
        ],
      ),
      _TestCase(
        description:
            'Malachi shift: Malachi 3:19-21 shifts to 4:1-3 (-18 verses into chapter 4)',
        bookNumber: 44,
        defaultChapter: 3,
        defaultVerseRange: '19-21',
        citation: 'Malachi 3:19-21',
        expected: [
          const ChapterVerseRange(chapter: 4, verses: [1, 2, 3]),
        ],
      ),
      _TestCase(
        description:
            'Malachi partial shift: Malachi 3:15-20 shifts verses > 18 to chapter 4',
        bookNumber: 44,
        defaultChapter: 3,
        defaultVerseRange: '15-20',
        citation: 'Malachi 3:15-20',
        expected: [
          const ChapterVerseRange(
            chapter: 4,
            verses: [1, 2],
          ), // verses 19-20 map to chapter 4:1-2
        ],
      ),
      _TestCase(
        description:
            'Acts 14 shift: Acts 14:21-28 shifts to 14:20-27 (-1 verse for verses > 20)',
        bookNumber: 53,
        defaultChapter: 14,
        defaultVerseRange: '21-28',
        citation: 'Acts 14:21-28',
        expected: [
          const ChapterVerseRange(
            chapter: 14,
            verses: [20, 21, 22, 23, 24, 25, 26, 27],
          ),
        ],
      ),
      _TestCase(
        description:
            'Mark 4:35-41 limits to verse 40 (verse 41 combined into 40 in Vulgate)',
        bookNumber: 50,
        defaultChapter: 4,
        defaultVerseRange: '35-41',
        citation: 'Mark 4:35-41',
        expected: [
          const ChapterVerseRange(chapter: 4, verses: [35, 36, 37, 38, 39, 40]),
        ],
      ),
      _TestCase(
        description:
            'Mark 9:41-50 shifts to 9:40-49 (-1 verse for verses > 40)',
        bookNumber: 50,
        defaultChapter: 9,
        defaultVerseRange: '41-45',
        citation: 'Mark 9:41-45',
        expected: [
          const ChapterVerseRange(chapter: 9, verses: [40, 41, 42, 43, 44]),
        ],
      ),
      _TestCase(
        description: 'Genesis 32:23-28 shifts to 32:22-27 (-1 verse)',
        bookNumber: 1,
        defaultChapter: 32,
        defaultVerseRange: '23-28',
        citation: 'Genesis 32:23-28',
        expected: [
          const ChapterVerseRange(
            chapter: 32,
            verses: [22, 23, 24, 25, 26, 27],
          ),
        ],
      ),
      _TestCase(
        description: 'Genesis 50:15-26 shifts verses >= 23 by -1',
        bookNumber: 1,
        defaultChapter: 50,
        defaultVerseRange: '15-26',
        citation: 'Genesis 50:15-26',
        expected: [
          const ChapterVerseRange(
            chapter: 50,
            verses: [15, 16, 17, 18, 19, 20, 21, 22, 22, 23, 24, 25],
          ),
        ],
      ),
      _TestCase(
        description: 'Exodus 40:34-38 shifts to 40:32-36 (-2 verses)',
        bookNumber: 2,
        defaultChapter: 40,
        defaultVerseRange: '34-38',
        citation: 'Exodus 40:34-38',
        expected: [
          const ChapterVerseRange(chapter: 40, verses: [32, 33, 34, 35, 36]),
        ],
      ),
      _TestCase(
        description: 'Matthew 17:22-27 shifts to 17:21-26 (-1 verse)',
        bookNumber: 49,
        defaultChapter: 17,
        defaultVerseRange: '22-27',
        citation: 'Matthew 17:22-27',
        expected: [
          const ChapterVerseRange(
            chapter: 17,
            verses: [21, 22, 23, 24, 25, 26],
          ),
        ],
      ),
      _TestCase(
        description: '2 Thessalonians 2:14-17 shifts to 2:13-16 (-1 verse)',
        bookNumber: 62,
        defaultChapter: 2,
        defaultVerseRange: '14-17',
        citation: '2 Thessalonians 2:14-17',
        expected: [
          const ChapterVerseRange(chapter: 2, verses: [13, 14, 15, 16]),
        ],
      ),
      _TestCase(
        description: 'Job 42:16-17 combined to verse 16',
        bookNumber: 20,
        defaultChapter: 42,
        defaultVerseRange: '12-17',
        citation: 'Job 42:12-17',
        expected: [
          const ChapterVerseRange(
            chapter: 42,
            verses: [12, 13, 14, 15, 16, 16],
          ),
        ],
      ),
      _TestCase(
        description: 'Joel 4 chapter maps to Joel 3',
        bookNumber: 34,
        defaultChapter: 4,
        defaultVerseRange: '1-5',
        citation: 'Joel 4:1-5',
        expected: [
          const ChapterVerseRange(chapter: 3, verses: [1, 2, 3, 4, 5]),
        ],
      ),
      _TestCase(
        description: 'Acts 14:19-22 partial shifts boundary',
        bookNumber: 53,
        defaultChapter: 14,
        defaultVerseRange: '19-22',
        citation: 'Acts 14:19-22',
        expected: [
          const ChapterVerseRange(
            chapter: 14,
            verses: [19, 20, 20, 21],
          ), // 21 maps to 20, 22 to 21
        ],
      ),
      _TestCase(
        description: 'Matthew 17:20-23 partial shifts boundary',
        bookNumber: 49,
        defaultChapter: 17,
        defaultVerseRange: '20-23',
        citation: 'Matthew 17:20-23',
        expected: [
          const ChapterVerseRange(
            chapter: 17,
            verses: [20, 21, 21, 22],
          ), // 22 maps to 21, 23 to 22
        ],
      ),
      _TestCase(
        description: 'Genesis 50:20-24 partial shifts boundary',
        bookNumber: 1,
        defaultChapter: 50,
        defaultVerseRange: '20-24',
        citation: 'Genesis 50:20-24',
        expected: [
          const ChapterVerseRange(
            chapter: 50,
            verses: [20, 21, 22, 22, 23],
          ), // 23 maps to 22, 24 to 23
        ],
      ),
      _TestCase(
        description: 'Job 42:15-18 partial shifts boundary',
        bookNumber: 20,
        defaultChapter: 42,
        defaultVerseRange: '15-18',
        citation: 'Job 42:15-18',
        expected: [
          const ChapterVerseRange(
            chapter: 42,
            verses: [15, 16, 16, 16],
          ), // 17 maps to 16, 18 maps to 16
        ],
      ),
      _TestCase(
        description: 'Exodus 40:31-35 partial shifts boundary',
        bookNumber: 2,
        defaultChapter: 40,
        defaultVerseRange: '31-35',
        citation: 'Exodus 40:31-35',
        expected: [
          const ChapterVerseRange(
            chapter: 40,
            verses: [31, 32, 33, 32, 33],
          ), // 34 maps to 32, 35 maps to 33
        ],
      ),
      _TestCase(
        description: 'Zechariah 2:3-6 partial shifts boundary',
        bookNumber: 43,
        defaultChapter: 2,
        defaultVerseRange: '3-6',
        citation: 'Zechariah 2:3-6',
        expected: [
          const ChapterVerseRange(
            chapter: 2,
            verses: [3, 4, 1, 2],
          ), // 5 maps to 1, 6 maps to 2
        ],
      ),

      // --- Additional 15 cases to reach 115 cases ---
      _TestCase(
        description: 'Luke 1:39-56 simple',
        bookNumber: 51,
        defaultChapter: 1,
        defaultVerseRange: '39-56',
        citation: 'Luke 1:39-56',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [
              39,
              40,
              41,
              42,
              43,
              44,
              45,
              46,
              47,
              48,
              49,
              50,
              51,
              52,
              53,
              54,
              55,
              56,
            ],
          ),
        ],
      ),
      _TestCase(
        description: 'John 1:1-18 simple',
        bookNumber: 52,
        defaultChapter: 1,
        defaultVerseRange: '1-18',
        citation: 'John 1:1-18',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [
              1,
              2,
              3,
              4,
              5,
              6,
              7,
              8,
              9,
              10,
              11,
              12,
              13,
              14,
              15,
              16,
              17,
              18,
            ],
          ),
        ],
      ),
      _TestCase(
        description: 'Acts 1:1-11 simple',
        bookNumber: 53,
        defaultChapter: 1,
        defaultVerseRange: '1-11',
        citation: 'Acts 1:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 1,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description: 'Romans 8:1-11 simple',
        bookNumber: 54,
        defaultChapter: 8,
        defaultVerseRange: '1-11',
        citation: 'Romans 8:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 8,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description: '1 Corinthians 15:1-11 simple',
        bookNumber: 55,
        defaultChapter: 15,
        defaultVerseRange: '1-11',
        citation: '1 Corinthians 15:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 15,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description: '2 Corinthians 4:7-15 simple',
        bookNumber: 56,
        defaultChapter: 4,
        defaultVerseRange: '7-15',
        citation: '2 Corinthians 4:7-15',
        expected: [
          const ChapterVerseRange(
            chapter: 4,
            verses: [7, 8, 9, 10, 11, 12, 13, 14, 15],
          ),
        ],
      ),
      _TestCase(
        description: 'Galatians 4:4-7 simple',
        bookNumber: 57,
        defaultChapter: 4,
        defaultVerseRange: '4-7',
        citation: 'Galatians 4:4-7',
        expected: [
          const ChapterVerseRange(chapter: 4, verses: [4, 5, 6, 7]),
        ],
      ),
      _TestCase(
        description: 'Ephesians 4:1-6 simple',
        bookNumber: 58,
        defaultChapter: 4,
        defaultVerseRange: '1-6',
        citation: 'Ephesians 4:1-6',
        expected: [
          const ChapterVerseRange(chapter: 4, verses: [1, 2, 3, 4, 5, 6]),
        ],
      ),
      _TestCase(
        description: 'Philippians 2:1-11 simple',
        bookNumber: 59,
        defaultChapter: 2,
        defaultVerseRange: '1-11',
        citation: 'Philippians 2:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 2,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description: 'Colossians 3:1-11 simple',
        bookNumber: 60,
        defaultChapter: 3,
        defaultVerseRange: '1-11',
        citation: 'Colossians 3:1-11',
        expected: [
          const ChapterVerseRange(
            chapter: 3,
            verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ),
        ],
      ),
      _TestCase(
        description: '1 Thessalonians 4:1-8 simple',
        bookNumber: 61,
        defaultChapter: 4,
        defaultVerseRange: '1-8',
        citation: '1 Thessalonians 4:1-8',
        expected: [
          const ChapterVerseRange(chapter: 4, verses: [1, 2, 3, 4, 5, 6, 7, 8]),
        ],
      ),
      _TestCase(
        description: '1 Timothy 1:1-2 simple',
        bookNumber: 63, // 1 Tim
        defaultChapter: 1,
        defaultVerseRange: '1-2',
        citation: '1 Timothy 1:1-2',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2]),
        ],
      ),
      _TestCase(
        description: '2 Timothy 1:1-3 simple',
        bookNumber: 64, // 2 Tim
        defaultChapter: 1,
        defaultVerseRange: '1-3',
        citation: '2 Timothy 1:1-3',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3]),
        ],
      ),
      _TestCase(
        description: 'Titus 1:1-4 simple',
        bookNumber: 65, // Titus
        defaultChapter: 1,
        defaultVerseRange: '1-4',
        citation: 'Titus 1:1-4',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4]),
        ],
      ),
      _TestCase(
        description: 'Philemon 1-7 simple',
        bookNumber: 66, // Philemon
        defaultChapter: 1,
        defaultVerseRange: '1-7',
        citation: 'Philemon 1-7',
        expected: [
          const ChapterVerseRange(chapter: 1, verses: [1, 2, 3, 4, 5, 6, 7]),
        ],
      ),
    ];

    for (var i = 0; i < testCases.length; i++) {
      final tc = testCases[i];
      test('Case #${i + 1}: ${tc.description} (${tc.citation})', () {
        final result = resolveReadingRanges(
          bookNumber: tc.bookNumber,
          defaultChapter: tc.defaultChapter,
          defaultVerseRange: tc.defaultVerseRange,
          citation: tc.citation,
        );
        expect(result, tc.expected);
      });
    }
  });
}

class _TestCase {
  final String description;
  final int bookNumber;
  final int defaultChapter;
  final String defaultVerseRange;
  final String citation;
  final List<ChapterVerseRange> expected;

  _TestCase({
    required this.description,
    required this.bookNumber,
    required this.defaultChapter,
    required this.defaultVerseRange,
    required this.citation,
    required this.expected,
  });
}
