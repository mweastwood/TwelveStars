import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/widgets/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

class MassReadingCard extends StatefulWidget {
  final LectionaryReading reading;
  final double fontSize;

  const MassReadingCard({
    super.key,
    required this.reading,
    this.fontSize = 16.0,
  });

  @override
  State<MassReadingCard> createState() => _MassReadingCardState();
}

class _MassReadingCardState extends State<MassReadingCard> {
  bool _isExpanded = true;
  bool _isLoading = false;
  List<BibleVerse>? _verses;
  List<UserComment> _comments = [];
  String? _errorMessage;

  String? _loadedTranslation;
  int? _firstSelectedVerseIndex;
  int? _lastSelectedVerseIndex;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  @override
  void didUpdateWidget(MassReadingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reading != widget.reading ||
        oldWidget.fontSize != widget.fontSize) {
      _firstSelectedVerseIndex = null;
      _lastSelectedVerseIndex = null;
      _loadVerses(force: true);
    }
  }

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

  Future<void> _loadComments() async {
    try {
      final bookMeta = catholicBooks.firstWhere(
        (b) => b.bookNumber == widget.reading.bookNumber,
        orElse: () =>
            throw Exception('Book ${widget.reading.bookName} not found'),
      );
      final comments = await BibleDatabaseHelper.db.getComments(
        documentId: bookMeta.abbrev,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadVerses({bool force = false}) async {
    final settings = await PrayerDatabase.loadSettings();
    final translation = settings.primaryBibleTranslation;

    if (_verses != null && _loadedTranslation == translation && !force) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      ReverseCitationService.ensureIndexed().then((_) {
        if (mounted) setState(() {});
      });

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

      await _loadComments();

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
          _loadedTranslation = translation;
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
      if (!_isExpanded) {
        _clearSelection();
      }
    });
    if (_isExpanded) {
      _loadVerses();
    }
  }

  bool _isVerseSelected(int index) {
    if (_firstSelectedVerseIndex != null && _lastSelectedVerseIndex != null) {
      final start = min(_firstSelectedVerseIndex!, _lastSelectedVerseIndex!);
      final end = max(_firstSelectedVerseIndex!, _lastSelectedVerseIndex!);
      return index >= start && index <= end;
    }
    return false;
  }

  void _onVerseLongPress(int index) {
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _firstSelectedVerseIndex = index;
      _lastSelectedVerseIndex = index;
    });
  }

  void _onVerseTap(int index) {
    if (_firstSelectedVerseIndex != null) {
      setState(() {
        _lastSelectedVerseIndex = index;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _firstSelectedVerseIndex = null;
      _lastSelectedVerseIndex = null;
    });
  }

  Widget _buildSelectionActionBar(ThemeData theme) {
    if (_firstSelectedVerseIndex == null ||
        _lastSelectedVerseIndex == null ||
        _verses == null ||
        _verses!.isEmpty) {
      return const SizedBox.shrink();
    }

    final start = min(_firstSelectedVerseIndex!, _lastSelectedVerseIndex!);
    final end = max(_firstSelectedVerseIndex!, _lastSelectedVerseIndex!);
    final count = end - start + 1;
    final selectedVerses = _verses!.sublist(start, end + 1);
    final firstV = selectedVerses.first;
    final lastV = selectedVerses.last;

    final String citation;
    if (count == 1) {
      citation = '${firstV.bookName} ${firstV.chapter}:${firstV.verseNumber}';
    } else if (firstV.chapter == lastV.chapter) {
      citation =
          '${firstV.bookName} ${firstV.chapter}:${firstV.verseNumber}-${lastV.verseNumber}';
    } else {
      citation =
          '${firstV.bookName} ${firstV.chapter}:${firstV.verseNumber} - ${lastV.chapter}:${lastV.verseNumber}';
    }

    final textPreview = selectedVerses.map((v) => v.verseText).join(' ');

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: ReaderSelectionActionBar(
        title: citation,
        selectedCount: count,
        itemLabel: 'verse',
        onSaveFavorite: () async {
          final favorite = FavoritePassagesCompanion.insert(
            bookNumber: firstV.bookNumber,
            bookName: firstV.bookName,
            chapter: firstV.chapter,
            startVerse: firstV.verseNumber,
            endVerse: lastV.verseNumber,
            textPreview: textPreview,
          );

          await BibleDatabaseHelper.db.saveFavorite(favorite);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved $citation to Favorites'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _clearSelection();
          }
        },
        onAddComment: () {
          final bookMeta = catholicBooks.firstWhere(
            (b) => b.bookNumber == widget.reading.bookNumber,
          );
          showAddCommentDialog(
            context: context,
            citation: citation,
            textPreview: textPreview,
            documentId: bookMeta.abbrev,
            sectionIndex: firstV.chapter,
            nodeId:
                '${firstV.bookNumber}_${firstV.chapter}_${firstV.verseNumber}',
            onCommentSaved: () async {
              _clearSelection();
              await _loadComments();
            },
          );
        },
        onCopy: () async {
          final versesText = selectedVerses
              .map((v) {
                return count == 1
                    ? v.verseText
                    : '${v.verseNumber} ${v.verseText}';
              })
              .join(count == 1 ? '' : '\n');

          final clipboardContent = '$citation\n$versesText';
          await Clipboard.setData(ClipboardData(text: clipboardContent));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied $citation to clipboard'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _clearSelection();
          }
        },
        onClearSelection: _clearSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      _readingIcon,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _readingTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.reading.citation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
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
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            // Expanded content
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Loading scripture...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Text(
                  'Error loading scripture: $_errorMessage',
                  style: TextStyle(color: theme.colorScheme.error),
                )
              else if (_verses == null || _verses!.isEmpty)
                const Text('No verses found for this reading range.')
              else ...[
                ..._verses!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final verse = entry.value;
                  final isSelected = _isVerseSelected(index);

                  final verseCitations =
                      ReverseCitationService.getVerseCitations(
                        verse.bookNumber,
                        verse.chapter,
                        verse.verseNumber,
                      );

                  final nodeId =
                      '${verse.bookNumber}_${verse.chapter}_${verse.verseNumber}';
                  final verseComments = _comments
                      .where((c) => c.nodeId == nodeId)
                      .toList();

                  return BibleVerseRow(
                    verseNumber: verse.verseNumber,
                    verseText: verse.verseText,
                    isSelected: isSelected,
                    fontSize: widget.fontSize,
                    citationsCount: verseCitations.length,
                    commentsCount: verseComments.length,
                    onTap: () => _onVerseTap(index),
                    onLongPress: () => _onVerseLongPress(index),
                    onTapCitations: () => showReverseCitationsModal(
                      context: context,
                      title:
                          '${verse.bookName} ${verse.chapter}:${verse.verseNumber}',
                      citations: verseCitations,
                    ),
                    onTapComments: () {
                      final bookMeta = catholicBooks.firstWhere(
                        (b) => b.bookNumber == widget.reading.bookNumber,
                      );
                      showVerseCommentsModal(
                        context: context,
                        title:
                            '${verse.bookName} ${verse.chapter}:${verse.verseNumber}',
                        nodeId: nodeId,
                        textPreview: verse.verseText,
                        comments: verseComments,
                        onCommentsChanged: _loadComments,
                        onAddComment: () => showAddCommentDialog(
                          context: context,
                          citation:
                              '${verse.bookName} ${verse.chapter}:${verse.verseNumber}',
                          textPreview: verse.verseText,
                          documentId: bookMeta.abbrev,
                          sectionIndex: verse.chapter,
                          nodeId: nodeId,
                          onCommentSaved: _loadComments,
                        ),
                      );
                    },
                  );
                }),
                if (_firstSelectedVerseIndex != null)
                  _buildSelectionActionBar(theme),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
