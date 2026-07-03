import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';

class ChapterVersePair {
  final int chapter;
  final int verse;

  ChapterVersePair(this.chapter, this.verse);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterVersePair &&
          runtimeType == other.runtimeType &&
          chapter == other.chapter &&
          verse == other.verse;

  @override
  int get hashCode => chapter.hashCode ^ verse.hashCode;

  @override
  String toString() => '$chapter:$verse';
}

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

String cleanVerseStr(String str) {
  String clean = str
      .replaceAll(' and ', ',')
      .replaceAll('&', ',')
      .replaceAll(';', ',');
  return clean.replaceAll(RegExp(r'[a-zA-Z]'), '');
}

BibleReference mapModernToVulgate(
  int bookNumber,
  int chapter,
  List<int> verses,
) {
  // 1. Psalms mapping
  if (bookNumber == 21) {
    if (chapter >= 1 && chapter <= 8) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: verses,
      );
    }
    if (chapter == 9 || chapter == 10) {
      final List<int> mappedVerses = [];
      for (final v in verses) {
        if (chapter == 9) {
          mappedVerses.add(v);
        } else {
          mappedVerses.add(v + 21);
        }
      }
      return BibleReference(
        bookNumber: bookNumber,
        chapter: 9,
        verses: mappedVerses,
      );
    }
    if (chapter == 56) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: 55,
        verses: verses.map((v) => v - 1).toList(),
      );
    }
    if (chapter >= 11 && chapter <= 113) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter - 1,
        verses: verses,
      );
    }
    if (chapter == 114 || chapter == 115) {
      final List<int> mappedVerses = [];
      for (final v in verses) {
        if (chapter == 114) {
          mappedVerses.add(v);
        } else {
          mappedVerses.add(v + 8);
        }
      }
      return BibleReference(
        bookNumber: bookNumber,
        chapter: 113,
        verses: mappedVerses,
      );
    }
    if (chapter == 116) {
      final List<int> verses114 = [];
      final List<int> verses115 = [];
      for (final v in verses) {
        if (v < 10) {
          verses114.add(v);
        } else {
          verses115.add(v - 9);
        }
      }
      if (verses115.isEmpty) {
        return BibleReference(
          bookNumber: bookNumber,
          chapter: 114,
          verses: verses114,
        );
      } else {
        return BibleReference(
          bookNumber: bookNumber,
          chapter: 115,
          verses: verses115,
        );
      }
    }
    if (chapter >= 117 && chapter <= 146) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter - 1,
        verses: verses,
      );
    }
    if (chapter == 147) {
      final List<int> verses146 = [];
      final List<int> verses147 = [];
      for (final v in verses) {
        if (v <= 11) {
          verses146.add(v);
        } else {
          verses147.add(v - 11);
        }
      }
      if (verses147.isEmpty) {
        return BibleReference(
          bookNumber: bookNumber,
          chapter: 146,
          verses: verses146,
        );
      } else {
        return BibleReference(
          bookNumber: bookNumber,
          chapter: 147,
          verses: verses147,
        );
      }
    }
    if (chapter >= 148 && chapter <= 150) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: verses,
      );
    }
  }

  // 2. Zechariah mapping
  if (bookNumber == 43 && chapter == 2) {
    final List<int> mappedVerses = [];
    for (final v in verses) {
      if (v >= 5) {
        mappedVerses.add(v - 4);
      } else {
        mappedVerses.add(v);
      }
    }
    return BibleReference(
      bookNumber: bookNumber,
      chapter: chapter,
      verses: mappedVerses,
    );
  }

  // 3. Malachi mapping
  if (bookNumber == 44 && chapter == 3) {
    final List<int> versesCh3 = [];
    final List<int> versesCh4 = [];
    for (final v in verses) {
      if (v <= 18) {
        versesCh3.add(v);
      } else {
        versesCh4.add(v - 18);
      }
    }
    if (versesCh4.isEmpty) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: 3,
        verses: versesCh3,
      );
    } else {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: 4,
        verses: versesCh4,
      );
    }
  }

  // 4. Acts mapping (Acts 14)
  if (bookNumber == 53 && chapter == 14) {
    final List<int> mappedVerses = [];
    for (final v in verses) {
      if (v <= 20) {
        mappedVerses.add(v);
      } else {
        mappedVerses.add(v - 1);
      }
    }
    return BibleReference(
      bookNumber: bookNumber,
      chapter: 14,
      verses: mappedVerses,
    );
  }

  // 5. Mark mapping (Mark 4:35-41 -> 35-40, Mark 9:41-50 -> 40-49)
  if (bookNumber == 50) {
    if (chapter == 4) {
      final List<int> mapped = [];
      for (final v in verses) {
        if (v <= 40) {
          mapped.add(v);
        }
      }
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: mapped,
      );
    }
    if (chapter == 9) {
      final List<int> mapped = [];
      for (final v in verses) {
        if (v <= 40) {
          mapped.add(v);
        } else {
          mapped.add(v - 1);
        }
      }
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: mapped,
      );
    }
  }

  // 6. Genesis mapping (Gen 32, Gen 50)
  if (bookNumber == 1) {
    if (chapter == 32) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: verses.map((v) => v - 1).toList(),
      );
    }
    if (chapter == 50) {
      final List<int> mapped = [];
      for (final v in verses) {
        if (v >= 23) {
          mapped.add(v - 1);
        } else {
          mapped.add(v);
        }
      }
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: mapped,
      );
    }
  }

  // 7. Exodus mapping (Exo 40)
  if (bookNumber == 2 && chapter == 40) {
    final List<int> mapped = [];
    for (final v in verses) {
      if (v >= 34) {
        mapped.add(v - 2);
      } else {
        mapped.add(v);
      }
    }
    return BibleReference(
      bookNumber: bookNumber,
      chapter: chapter,
      verses: mapped,
    );
  }

  // 8. Matthew mapping (Matt 17)
  if (bookNumber == 49 && chapter == 17) {
    final List<int> mapped = [];
    for (final v in verses) {
      if (v >= 22) {
        mapped.add(v - 1);
      } else {
        mapped.add(v);
      }
    }
    return BibleReference(
      bookNumber: bookNumber,
      chapter: chapter,
      verses: mapped,
    );
  }

  // 9. 2 Thessalonians mapping (2 Thes 2)
  if (bookNumber == 62 && chapter == 2) {
    final List<int> mapped = [];
    for (final v in verses) {
      if (v >= 14) {
        mapped.add(v - 1);
      } else {
        mapped.add(v);
      }
    }
    return BibleReference(
      bookNumber: bookNumber,
      chapter: chapter,
      verses: mapped,
    );
  }

  // 10. Job mapping (Job 42)
  if (bookNumber == 20 && chapter == 42) {
    final List<int> mapped = [];
    for (final v in verses) {
      if (v >= 17) {
        mapped.add(16);
      } else {
        mapped.add(v);
      }
    }
    return BibleReference(
      bookNumber: bookNumber,
      chapter: chapter,
      verses: mapped,
    );
  }

  // 11. Joel mapping (Joel 4 -> Joel 3)
  if (bookNumber == 34 && chapter == 4) {
    return BibleReference(bookNumber: bookNumber, chapter: 3, verses: verses);
  }

  return BibleReference(
    bookNumber: bookNumber,
    chapter: chapter,
    verses: verses,
  );
}

List<ChapterVersePair> resolveVersesForReading(
  int bookNumber,
  int startChapter,
  String verseRangeStr,
  String citation,
  List<Map<String, dynamic>> allBookVerses,
) {
  // Semicolon-separated cross-chapter citations (e.g., "Isaiah 63:16b-17, 19b; 64:2-7")
  if (citation.contains(';')) {
    final parts = citation.split(';');
    final List<ChapterVersePair> result = [];

    // Process the first part
    final part1 = parts[0].trim();
    final colonIndex1 = part1.indexOf(':');
    if (colonIndex1 != -1) {
      final chapterPart = part1.substring(0, colonIndex1);
      final chapterMatch = RegExp(r'\d+$').firstMatch(chapterPart.trim());
      if (chapterMatch != null) {
        final ch1 = int.parse(chapterMatch.group(0)!);
        final versesStr1 = part1.substring(colonIndex1 + 1);
        final rawVerses1 = parseVerseRange(cleanVerseStr(versesStr1));
        final mappedRef1 = mapModernToVulgate(bookNumber, ch1, rawVerses1);
        for (final v in mappedRef1.verses) {
          result.add(ChapterVersePair(mappedRef1.chapter, v));
        }
      }
    }

    // Process subsequent parts
    for (int i = 1; i < parts.length; i++) {
      final part2 = parts[i].trim();
      final colonIndex2 = part2.indexOf(':');
      if (colonIndex2 != -1) {
        final ch2Str = part2
            .substring(0, colonIndex2)
            .replaceAll(RegExp(r'[^\d]'), '');
        final ch2 = int.tryParse(ch2Str);
        if (ch2 != null) {
          final versesStr2 = part2.substring(colonIndex2 + 1);
          final rawVerses2 = parseVerseRange(cleanVerseStr(versesStr2));
          final mappedRef2 = mapModernToVulgate(bookNumber, ch2, rawVerses2);
          for (final v in mappedRef2.verses) {
            result.add(ChapterVersePair(mappedRef2.chapter, v));
          }
        }
      }
    }

    if (result.isNotEmpty) {
      return result;
    }
  }

  final cleanRange = cleanVerseStr(verseRangeStr);
  final initialVersesList = parseVerseRange(cleanRange);
  final mappedRef = mapModernToVulgate(
    bookNumber,
    startChapter,
    initialVersesList,
  );

  if (citation.contains('—') ||
      citation.contains('–') ||
      citation.contains('-')) {
    String dash = '—';
    if (citation.contains('—')) {
      dash = '—';
    } else if (citation.contains('–')) {
      dash = '–';
    } else {
      dash = '-';
    }
    final parts = citation.split(dash);
    if (parts.length == 2) {
      final rightPart = parts[1].trim();

      if (rightPart.contains(':')) {
        final rightSubParts = rightPart.split(':');
        final endChapterStr = rightSubParts[0].replaceAll(RegExp(r'[^\d]'), '');
        final endChapterVal = int.tryParse(endChapterStr);

        if (endChapterVal != null) {
          final mappedEndRef = mapModernToVulgate(
            bookNumber,
            endChapterVal,
            const [],
          );
          final endChapter = mappedEndRef.chapter;

          if (endChapter != mappedRef.chapter) {
            final endVerseStr = cleanVerseStr(rightSubParts[1]);
            final rawEndVerses = parseVerseRange(endVerseStr);
            final mappedEndVerseRef = mapModernToVulgate(
              bookNumber,
              endChapterVal,
              rawEndVerses,
            );
            final endVerses = mappedEndVerseRef.verses;

            final startVerses = mappedRef.verses;
            final List<ChapterVersePair> result = [];

            // 1. Add first chapter verses
            if (startVerses.isNotEmpty) {
              final startVerseLimit = startVerses.last;
              final specificVerses = startVerses.sublist(
                0,
                startVerses.length - 1,
              );

              final ch1Verses = allBookVerses
                  .where((v) => v['chapter'] == mappedRef.chapter)
                  .map((v) => v['verseNumber'] as int)
                  .toList();
              for (final v in ch1Verses) {
                if (specificVerses.contains(v) || v >= startVerseLimit) {
                  result.add(ChapterVersePair(mappedRef.chapter, v));
                }
              }
            }

            // 2. Add intermediate chapters
            for (int c = mappedRef.chapter + 1; c < endChapter; c++) {
              final chVerses = allBookVerses
                  .where((v) => v['chapter'] == c)
                  .map((v) => v['verseNumber'] as int)
                  .toList();
              for (final v in chVerses) {
                result.add(ChapterVersePair(c, v));
              }
            }

            // 3. Add second chapter verses
            if (endVerses.isNotEmpty) {
              final hasCommaOrMultiple =
                  rightSubParts[1].contains(',') ||
                  rightSubParts[1].contains('and');
              if (hasCommaOrMultiple) {
                for (final v in endVerses) {
                  result.add(ChapterVersePair(endChapter, v));
                }
              } else {
                final endVerseLimit = endVerses.last;
                final ch2Verses = allBookVerses
                    .where((v) => v['chapter'] == endChapter)
                    .map((v) => v['verseNumber'] as int)
                    .toList();
                for (final v in ch2Verses) {
                  if (v <= endVerseLimit) {
                    result.add(ChapterVersePair(endChapter, v));
                  }
                }
              }
            }

            return result;
          }
        }
      }
    }
  }

  // Single chapter case:
  final List<ChapterVersePair> result = [];
  if (mappedRef.verses.isEmpty) {
    final chVerses = allBookVerses
        .where((v) => v['chapter'] == mappedRef.chapter)
        .map((v) => v['verseNumber'] as int)
        .toList();
    for (final v in chVerses) {
      result.add(ChapterVersePair(mappedRef.chapter, v));
    }
  } else {
    for (final v in mappedRef.verses) {
      result.add(ChapterVersePair(mappedRef.chapter, v));
    }
  }
  return result;
}

void main() {
  test(
    'verify every daily/sunday lectionary reading can be parsed and resolved successfully',
    () async {
      // 1. Read lectionary.json
      final file = File('assets/bible/lectionary.json');
      final content = await file.readAsString();
      final List<dynamic> lectionary = jsonDecode(content);

      // Cache for loaded USFM verses
      final Map<int, List<Map<String, dynamic>>> bookVersesCache = {};

      List<Map<String, dynamic>> getBookVerses(
        int bookNumber,
        String bookName,
      ) {
        if (bookVersesCache.containsKey(bookNumber)) {
          return bookVersesCache[bookNumber]!;
        }
        final bookMeta = catholicBooks.firstWhere(
          (b) => b.bookNumber == bookNumber,
        );
        final numStr = bookNumber.toString().padLeft(2, '0');
        final usfmFile = File(
          'assets/bible/cpdv/usfm/$numStr-${bookMeta.abbrev}-ENG[B]CPDV2009[pd].p.sfm',
        );
        if (!usfmFile.existsSync()) {
          throw Exception('USFM file not found: ${usfmFile.path}');
        }
        final usfmContent = usfmFile.readAsStringSync();
        final parsed = UsfmParser.parse(
          usfmContent,
          'CPDV',
          bookNumber,
          bookName,
        );
        bookVersesCache[bookNumber] = parsed;
        return parsed;
      }

      final List<String> failures = [];

      for (final entry in lectionary) {
        final key = entry['reading_key'] as String;
        final type = entry['reading_type'] as String;
        final bookNumber = entry['book_number'] as int;
        final bookName = entry['book_name'] as String;
        final chapter = entry['chapter'] as int;
        final verseRangeStr = entry['verse_range'] as String;
        final citation = entry['citation'] as String;

        try {
          final allVerses = getBookVerses(bookNumber, bookName);
          final resolvedPairs = resolveVersesForReading(
            bookNumber,
            chapter,
            verseRangeStr,
            citation,
            allVerses,
          );

          // Filter the verses in the book matching the resolved pairs
          final Set<ChapterVersePair> resolvedSet = resolvedPairs.toSet();
          final matchedVerses = allVerses
              .where(
                (v) => resolvedSet.contains(
                  ChapterVersePair(
                    v['chapter'] as int,
                    v['verseNumber'] as int,
                  ),
                ),
              )
              .toList();

          if (matchedVerses.isEmpty) {
            failures.add(
              'Failed to resolve verses for key: $key, type: $type, citation: "$citation" (resolved pairs: $resolvedPairs returned empty)',
            );
          } else if (resolvedPairs.isNotEmpty &&
              matchedVerses.length != resolvedPairs.length) {
            final foundPairs = matchedVerses
                .map(
                  (v) => ChapterVersePair(
                    v['chapter'] as int,
                    v['verseNumber'] as int,
                  ),
                )
                .toSet();
            final missing = resolvedPairs
                .where((pair) => !foundPairs.contains(pair))
                .toList();
            if (missing.isNotEmpty) {
              failures.add('Missing verses $missing for citation: "$citation"');
            }
          }
        } catch (e) {
          failures.add('Error processing "$citation" ($key, $type): $e');
        }
      }

      if (failures.isNotEmpty) {
        fail(
          'Found ${failures.length} parsing/resolution failures:\n${failures.take(50).join('\n')}\n...',
        );
      }
    },
  );
}
