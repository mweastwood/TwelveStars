import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

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

class MassReadingCard extends StatefulWidget {
  final LectionaryReading reading;

  const MassReadingCard({super.key, required this.reading});

  @override
  State<MassReadingCard> createState() => _MassReadingCardState();
}

class _MassReadingCardState extends State<MassReadingCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  List<BibleVerse>? _verses;
  String? _errorMessage;

  String get _readingTitle {
    switch (widget.reading.readingType) {
      case 'first':
        return 'First Reading';
      case 'second':
        return 'Second Reading';
      case 'psalm':
        return 'Responsorial Psalm';
      case 'gospel':
        return 'Gospel';
      default:
        return 'Reading';
    }
  }

  IconData get _readingIcon {
    switch (widget.reading.readingType) {
      case 'first':
      case 'second':
        return Icons.menu_book;
      case 'psalm':
        return Icons.music_note;
      case 'gospel':
        return Icons.auto_stories;
      default:
        return Icons.book;
    }
  }

  Future<void> _loadVerses() async {
    if (_verses != null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = BibleDatabaseHelper.db;
      final bookMeta = catholicBooks.firstWhere(
        (b) => b.bookNumber == widget.reading.bookNumber,
        orElse: () =>
            throw Exception('Book ${widget.reading.bookName} not found'),
      );
      await db.ensureBookPopulated(
        bookMeta.bookNumber,
        bookMeta.bookName,
        bookMeta.abbrev,
      );

      final cleanRange = cleanVerseStr(widget.reading.verseRange);
      final initialVersesList = parseVerseRange(cleanRange);
      final mappedRef = mapModernToVulgate(
        widget.reading.bookNumber,
        widget.reading.chapter,
        initialVersesList,
      );

      final citation = widget.reading.citation;
      List<BibleVerse> verses = [];

      // 1. Semicolon-separated cross-chapter citations (e.g. "Isaiah 63:16b-17, 19b; 64:2-7")
      if (citation.contains(';')) {
        final parts = citation.split(';');
        Expression<bool> predicate = const Constant(false);

        for (final part in parts) {
          final trimmedPart = part.trim();
          final colonIndex = trimmedPart.indexOf(':');
          if (colonIndex != -1) {
            final chapterPart = trimmedPart.substring(0, colonIndex);
            final chapterMatch = RegExp(r'\d+$').firstMatch(chapterPart.trim());
            if (chapterMatch != null) {
              final ch = int.parse(chapterMatch.group(0)!);
              final versesStr = trimmedPart.substring(colonIndex + 1);
              final rawVerses = parseVerseRange(cleanVerseStr(versesStr));
              final mappedRefPart = mapModernToVulgate(
                widget.reading.bookNumber,
                ch,
                rawVerses,
              );

              predicate =
                  predicate |
                  (db.bibleVerses.chapter.equals(mappedRefPart.chapter) &
                      db.bibleVerses.verseNumber.isIn(mappedRefPart.verses));
            }
          }
        }

        verses =
            await (db.select(db.bibleVerses)
                  ..where(
                    (t) =>
                        t.translationCode.equals('CPDV') &
                        t.bookNumber.equals(widget.reading.bookNumber) &
                        predicate,
                  )
                  ..orderBy([
                    (t) => OrderingTerm(expression: t.chapter),
                    (t) => OrderingTerm(expression: t.verseNumber),
                  ]))
                .get();
      }
      // 2. Multi-chapter crossings (e.g. "Exodus 11:10—12:14")
      else if (citation.contains('—') || citation.contains('–')) {
        String dash = citation.contains('—') ? '—' : '–';
        final parts = citation.split(dash);
        if (parts.length == 2) {
          final rightPart = parts[1].trim();

          if (rightPart.contains(':')) {
            final rightSubParts = rightPart.split(':');
            final endChapterStr = rightSubParts[0].replaceAll(
              RegExp(r'[^\d]'),
              '',
            );
            final endChapterVal = int.tryParse(endChapterStr);

            if (endChapterVal != null) {
              final mappedEndRef = mapModernToVulgate(
                widget.reading.bookNumber,
                endChapterVal,
                const [],
              );
              final endChapter = mappedEndRef.chapter;

              if (endChapter != mappedRef.chapter) {
                final endVerseStr = cleanVerseStr(rightSubParts[1]);
                final rawEndVerses = parseVerseRange(endVerseStr);
                final mappedEndVerseRef = mapModernToVulgate(
                  widget.reading.bookNumber,
                  endChapterVal,
                  rawEndVerses,
                );
                final endVerses = mappedEndVerseRef.verses;

                final startVerses = mappedRef.verses;
                Expression<bool> predicate = const Constant(false);

                // Add first chapter verses
                if (startVerses.isNotEmpty) {
                  final startVerseLimit = startVerses.last;
                  final specificVerses = startVerses.sublist(
                    0,
                    startVerses.length - 1,
                  );

                  if (specificVerses.isNotEmpty) {
                    predicate =
                        predicate |
                        (db.bibleVerses.chapter.equals(mappedRef.chapter) &
                            (db.bibleVerses.verseNumber.isIn(specificVerses) |
                                db.bibleVerses.verseNumber.isBiggerOrEqualValue(
                                  startVerseLimit,
                                )));
                  } else {
                    predicate =
                        predicate |
                        (db.bibleVerses.chapter.equals(mappedRef.chapter) &
                            db.bibleVerses.verseNumber.isBiggerOrEqualValue(
                              startVerseLimit,
                            ));
                  }
                }

                // Add intermediate chapters
                for (int c = mappedRef.chapter + 1; c < endChapter; c++) {
                  predicate = predicate | db.bibleVerses.chapter.equals(c);
                }

                // Add second chapter verses
                if (endVerses.isNotEmpty) {
                  final hasCommaOrMultiple =
                      rightSubParts[1].contains(',') ||
                      rightSubParts[1].contains('and');
                  if (hasCommaOrMultiple) {
                    predicate =
                        predicate |
                        (db.bibleVerses.chapter.equals(endChapter) &
                            db.bibleVerses.verseNumber.isIn(endVerses));
                  } else {
                    final endVerseLimit = endVerses.last;
                    predicate =
                        predicate |
                        (db.bibleVerses.chapter.equals(endChapter) &
                            db.bibleVerses.verseNumber.isSmallerOrEqualValue(
                              endVerseLimit,
                            ));
                  }
                }

                verses =
                    await (db.select(db.bibleVerses)
                          ..where(
                            (t) =>
                                t.translationCode.equals('CPDV') &
                                t.bookNumber.equals(widget.reading.bookNumber) &
                                predicate,
                          )
                          ..orderBy([
                            (t) => OrderingTerm(expression: t.chapter),
                            (t) => OrderingTerm(expression: t.verseNumber),
                          ]))
                        .get();
              }
            }
          }
        }
      }

      // 3. Fallback/Single chapter case
      if (verses.isEmpty) {
        if (mappedRef.verses.isEmpty) {
          verses = await db.getChapterVerses(
            'CPDV',
            widget.reading.bookNumber,
            mappedRef.chapter,
          );
        } else {
          verses =
              await (db.select(db.bibleVerses)
                    ..where(
                      (t) =>
                          t.translationCode.equals('CPDV') &
                          t.bookNumber.equals(widget.reading.bookNumber) &
                          t.chapter.equals(mappedRef.chapter) &
                          t.verseNumber.isIn(mappedRef.verses),
                    )
                    ..orderBy([(t) => OrderingTerm(expression: t.verseNumber)]))
                  .get();
        }
      }

      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _loadVerses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    _readingIcon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _readingTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.reading.citation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              // Expanded content
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_errorMessage != null)
                  Text(
                    'Error loading scripture: $_errorMessage',
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                else if (_verses == null || _verses!.isEmpty)
                  const Text('No verses found for this reading range.')
                else
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurface,
                      ),
                      children: _verses!.map((v) {
                        return TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text(
                                  '${v.verseNumber}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: '${v.verseText} '),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
