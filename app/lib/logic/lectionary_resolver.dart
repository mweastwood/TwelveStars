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
  // 1. Psalms mapping (Book 21)
  // The Hebrew (NABRE/Modern) Psalms numbering differs from the Greek/Latin Vulgate (CPDV) numbering.
  if (bookNumber == 21) {
    // Hebrew Psalms 1-8 map 1:1 to Vulgate Psalms 1-8 (same numbering).
    if (chapter >= 1 && chapter <= 8) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: verses,
      );
    }
    // Hebrew Psalms 9 & 10 are combined into Vulgate Psalm 9.
    // Hebrew 9:1-20 maps directly to Vulgate 9:1-21.
    // Hebrew 10:1-18 maps to Vulgate 9:22-39 (with a +21 verse offset).
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
    // Hebrew Psalm 56 has a unique verse shift of -1 because the Hebrew version counts
    // the title superscription as verse 1, while the Vulgate does not.
    if (chapter == 56) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: 55,
        verses: verses.map((v) => v - 1).toList(),
      );
    }
    // Hebrew Psalms 11 to 113 are shifted by -1 chapter in the Vulgate (e.g., Hebrew 23 -> Vulgate 22).
    if (chapter >= 11 && chapter <= 113) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter - 1,
        verses: verses,
      );
    }
    // Hebrew Psalms 114 & 115 are combined into Vulgate Psalm 113.
    // Hebrew 114:1-8 maps to Vulgate 113:1-8.
    // Hebrew 115:1-18 maps to Vulgate 113:9-26 (with a +8 verse offset).
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
    // Hebrew Psalm 116 is split into two Vulgate Psalms:
    // Hebrew 116:1-9 maps to Vulgate Psalm 114:1-9.
    // Hebrew 116:10-19 maps to Vulgate Psalm 115:1-10 (with a -9 verse offset).
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
    // Hebrew Psalms 117 to 146 are shifted by -1 chapter in the Vulgate (e.g., Hebrew 117 -> Vulgate 116).
    if (chapter >= 117 && chapter <= 146) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter - 1,
        verses: verses,
      );
    }
    // Hebrew Psalm 147 is split into two Vulgate Psalms:
    // Hebrew 147:1-11 maps to Vulgate Psalm 146:1-11.
    // Hebrew 147:12-20 maps to Vulgate Psalm 147:1-9 (with a -11 verse offset).
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
    // Hebrew Psalms 148 to 150 map directly to Vulgate Psalms 148 to 150 (same numbering).
    if (chapter >= 148 && chapter <= 150) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: verses,
      );
    }
  }

  // 2. Zechariah mapping
  // Hebrew Zechariah 2:5-17 maps to Vulgate Zechariah 2:1-13 (shifted by -4 verses).
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
  // Hebrew Malachi has 3 chapters; Vulgate Malachi has 4 chapters.
  // Hebrew Malachi 3:19-24 maps to Vulgate Malachi 4:1-6 (shifted by -18 verses into chapter 4).
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

  // 4. Acts mapping
  // In Acts 14, modern verses 20 and 21 are combined into CPDV verse 20.
  // Consequently, modern verses 21-28 map to CPDV verses 20-27 (shifted by -1 verse).
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

  // 5. Mark mapping
  if (bookNumber == 50) {
    // In Mark 4, modern verses 40 and 41 (stilling the storm) are combined in the Vulgate,
    // so modern 4:35-41 maps to CPDV 4:35-40 (verse 41 does not exist in CPDV).
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
    // In Mark 9, modern verses 40 and 41 are combined into CPDV verse 40,
    // shifting subsequent verses by -1 (modern 9:41-50 maps to CPDV 9:40-49).
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

  // 6. Genesis mapping
  if (bookNumber == 1) {
    // In Genesis 32, the wrestling with the angel starts at modern verse 23,
    // which corresponds to Vulgate verse 22 (shifted by -1 verse).
    if (chapter == 32) {
      return BibleReference(
        bookNumber: bookNumber,
        chapter: chapter,
        verses: verses.map((v) => v - 1).toList(),
      );
    }
    // In Genesis 50, modern verses 22 and 23 are combined into CPDV verse 22,
    // shifting subsequent verses 23-26 by -1 (modern 50:15-26 maps to CPDV 50:15-25).
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

  // 7. Exodus mapping
  // In Exodus 40, modern verses 32 and 33 are combined into CPDV verse 31,
  // and modern verses 34 and 35 are combined into CPDV verse 33, causing
  // modern verses 34-38 to map to CPDV verses 32-36 (shifted by -2 verses).
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

  // 8. Matthew mapping
  // In Matthew 17, modern verses 20 and 21 are combined into CPDV verse 20,
  // shifting subsequent verses 22-27 by -1 (modern 17:22-27 maps to CPDV 17:21-26).
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

  // 9. 2 Thessalonians mapping
  // In 2 Thessalonians 2, modern verses 10 and 11 are combined into CPDV verse 10,
  // shifting subsequent verses 14-17 by -1 (modern 2:14-17 maps to CPDV 2:13-16).
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

  // 10. Job mapping
  // In Job 42, modern verses 16 and 17 (Job's death) are combined into CPDV verse 16,
  // so modern verse 17 maps to CPDV verse 16.
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

  // 11. Joel mapping
  // Modern Joel has 4 chapters, whereas Vulgate Joel has 3 chapters.
  // Modern Joel 4 maps to Vulgate Joel 3.
  if (bookNumber == 34 && chapter == 4) {
    return BibleReference(bookNumber: bookNumber, chapter: 3, verses: verses);
  }

  return BibleReference(
    bookNumber: bookNumber,
    chapter: chapter,
    verses: verses,
  );
}
