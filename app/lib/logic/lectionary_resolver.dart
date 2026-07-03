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
  final List<int> verses = [];
  final parts = trimmed.split(',');
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
