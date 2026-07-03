import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';

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
