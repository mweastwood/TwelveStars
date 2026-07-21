import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/prayer_database.dart';

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
      final settings = await PrayerDatabase.loadSettings();
      final translation = settings.primaryBibleTranslation;

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
        translation: translation,
      );

      final ranges = resolveReadingRanges(
        bookNumber: widget.reading.bookNumber,
        defaultChapter: widget.reading.chapter,
        defaultVerseRange: widget.reading.verseRange,
        citation: widget.reading.citation,
      );

      Expression<bool> predicate = const Constant(false);
      for (final range in ranges) {
        Expression<bool> rangePredicate = db.bibleVerses.chapter.equals(
          range.chapter,
        );

        if (range.verses != null) {
          if (range.startVerseLimit != null) {
            rangePredicate =
                rangePredicate &
                (db.bibleVerses.verseNumber.isIn(range.verses!) |
                    db.bibleVerses.verseNumber.isBiggerOrEqualValue(
                      range.startVerseLimit!,
                    ));
          } else {
            rangePredicate =
                rangePredicate & db.bibleVerses.verseNumber.isIn(range.verses!);
          }
        } else if (range.startVerseLimit != null) {
          rangePredicate =
              rangePredicate &
              db.bibleVerses.verseNumber.isBiggerOrEqualValue(
                range.startVerseLimit!,
              );
        } else if (range.endVerseLimit != null) {
          rangePredicate =
              rangePredicate &
              db.bibleVerses.verseNumber.isSmallerOrEqualValue(
                range.endVerseLimit!,
              );
        }

        predicate = predicate | rangePredicate;
      }

      final verses =
          await (db.select(db.bibleVerses)
                ..where(
                  (t) =>
                      t.translationCode.equals(translation) &
                      t.bookNumber.equals(widget.reading.bookNumber) &
                      predicate,
                )
                ..orderBy([
                  (t) => OrderingTerm(expression: t.chapter),
                  (t) => OrderingTerm(expression: t.verseNumber),
                ]))
              .get();

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
                                  textScaler: TextScaler.noScaling,
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
