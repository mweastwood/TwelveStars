import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

class BibleChapterView extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final String primaryTranslation;
  final String compareTranslation;
  final int? scrollToVerse;
  final int? highlightStartVerse;
  final int? highlightEndVerse;
  final String? navigationSessionId;
  final VoidCallback? onFavoriteSaved;

  const BibleChapterView({
    super.key,
    required this.book,
    required this.chapter,
    required this.primaryTranslation,
    required this.compareTranslation,
    this.scrollToVerse,
    this.highlightStartVerse,
    this.highlightEndVerse,
    this.navigationSessionId,
    this.onFavoriteSaved,
  });

  @override
  State<BibleChapterView> createState() => _BibleChapterViewState();
}

class _BibleChapterViewState extends State<BibleChapterView>
    with AutomaticKeepAliveClientMixin {
  List<BibleVerse> _verses = [];
  List<BibleVerse> _compareVerses = [];
  bool _loading = true;
  String? _error;

  int? _firstSelectedVerseNumber;
  int? _lastSelectedVerseNumber;
  int? _temporaryHighlightStart;
  int? _temporaryHighlightEnd;
  String? _lastProcessedSessionId;

  final Map<int, GlobalKey> _verseKeys = {};

  @override
  bool get wantKeepAlive => true; // Cache adjacent chapters in memory

  @override
  void initState() {
    super.initState();
    _loadChapterData();
  }

  @override
  void didUpdateWidget(BibleChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.bookNumber != widget.book.bookNumber ||
        oldWidget.chapter != widget.chapter ||
        oldWidget.primaryTranslation != widget.primaryTranslation ||
        oldWidget.compareTranslation != widget.compareTranslation) {
      _firstSelectedVerseNumber = null;
      _lastSelectedVerseNumber = null;
      _loadChapterData();
    } else if (widget.navigationSessionId != oldWidget.navigationSessionId) {
      _scrollToAndHighlightTarget();
    }
  }

  Future<void> _loadChapterData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = BibleDatabaseHelper.db;
      // Load primary translation
      await db.ensureBookPopulated(
        widget.book.bookNumber,
        widget.book.bookName,
        widget.book.abbrev,
        translation: widget.primaryTranslation,
      );
      final verses = await db.getChapterVerses(
        widget.primaryTranslation,
        widget.book.bookNumber,
        widget.chapter,
      );

      // Load compare translation if needed
      List<BibleVerse> compareVerses = [];
      if (widget.compareTranslation != 'none') {
        await db.ensureBookPopulated(
          widget.book.bookNumber,
          widget.book.bookName,
          widget.book.abbrev,
          translation: widget.compareTranslation,
        );
        compareVerses = await db.getChapterVerses(
          widget.compareTranslation,
          widget.book.bookNumber,
          widget.chapter,
        );
      }

      if (mounted) {
        setState(() {
          _verses = verses;
          _compareVerses = compareVerses;
          _loading = false;
        });
        _scrollToAndHighlightTarget();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _scrollToAndHighlightTarget() {
    if (widget.scrollToVerse != null &&
        widget.navigationSessionId != _lastProcessedSessionId) {
      _lastProcessedSessionId = widget.navigationSessionId;
      _temporaryHighlightStart = widget.highlightStartVerse;
      _temporaryHighlightEnd = widget.highlightEndVerse;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _verseKeys[widget.scrollToVerse];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _temporaryHighlightStart = null;
            _temporaryHighlightEnd = null;
          });
        }
      });
    }
  }

  bool _isVerseSelected(int verseNumber) {
    if (_firstSelectedVerseNumber != null && _lastSelectedVerseNumber != null) {
      final start = min(_firstSelectedVerseNumber!, _lastSelectedVerseNumber!);
      final end = max(_firstSelectedVerseNumber!, _lastSelectedVerseNumber!);
      return verseNumber >= start && verseNumber <= end;
    }
    if (_temporaryHighlightStart != null && _temporaryHighlightEnd != null) {
      final start = min(_temporaryHighlightStart!, _temporaryHighlightEnd!);
      final end = max(_temporaryHighlightStart!, _temporaryHighlightEnd!);
      return verseNumber >= start && verseNumber <= end;
    }
    return false;
  }

  void _onVerseLongPress(int verseNumber) {
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _firstSelectedVerseNumber = verseNumber;
      _lastSelectedVerseNumber = verseNumber;
    });
  }

  void _onVerseTap(int verseNumber) {
    if (_firstSelectedVerseNumber != null) {
      setState(() {
        _lastSelectedVerseNumber = verseNumber;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _firstSelectedVerseNumber = null;
      _lastSelectedVerseNumber = null;
    });
  }

  Widget _buildSelectionActionBar(ThemeData theme) {
    final start = min(_firstSelectedVerseNumber!, _lastSelectedVerseNumber!);
    final end = max(_firstSelectedVerseNumber!, _lastSelectedVerseNumber!);
    final count = end - start + 1;
    final citation = count == 1
        ? '${widget.book.bookName} ${widget.chapter}:$start'
        : '${widget.book.bookName} ${widget.chapter}:$start-$end';

    return Card(
      elevation: 6,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    citation,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$count verse${count > 1 ? "s" : ""} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.star),
              label: const Text('Save'),
              onPressed: () async {
                final selectedVerses = _verses
                    .where(
                      (v) => v.verseNumber >= start && v.verseNumber <= end,
                    )
                    .toList();
                final textPreview = selectedVerses
                    .map((v) => v.verseText)
                    .join(' ');

                final favorite = FavoritePassagesCompanion.insert(
                  bookNumber: widget.book.bookNumber,
                  bookName: widget.book.bookName,
                  chapter: widget.chapter,
                  startVerse: start,
                  endVerse: end,
                  textPreview: textPreview,
                );

                await BibleDatabaseHelper.db.saveFavorite(favorite);

                if (widget.onFavoriteSaved != null) {
                  widget.onFavoriteSaved!();
                }

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
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.content_copy),
              tooltip: 'Copy selection',
              onPressed: () async {
                final selectedVerses =
                    _verses
                        .where(
                          (v) => v.verseNumber >= start && v.verseNumber <= end,
                        )
                        .toList()
                      ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));

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
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
              tooltip: 'Cancel selection',
            ),
          ],
        ),
      ),
    );
  }

  String _getTranslationName(String code) {
    if (code == 'CPDV') return 'Catholic Public Domain Version (CPDV)';
    if (code == 'DRC') return 'Douay-Rheims Bible (DRC)';
    if (code == 'JUN') return 'Biblia de Jünemann (JUN)';
    if (code == 'TAM') return 'Torres Amat (TAM)';
    return code;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error loading Bible: $_error'));
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            160.0, // space for bottom sheet + action bar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.book.bookName} ${widget.chapter}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.compareTranslation == 'none'
                    ? _getTranslationName(widget.primaryTranslation)
                    : '${_getTranslationName(widget.primaryTranslation)}  |  ${_getTranslationName(widget.compareTranslation)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.outline,
                ),
              ),
              const Divider(height: 24),
              ..._verses.map((verse) {
                final isSelected = _isVerseSelected(verse.verseNumber);
                _verseKeys.putIfAbsent(verse.verseNumber, () => GlobalKey());

                BibleVerse? compareVerse;
                if (_compareVerses.isNotEmpty) {
                  for (final cv in _compareVerses) {
                    if (cv.verseNumber == verse.verseNumber) {
                      compareVerse = cv;
                      break;
                    }
                  }
                }

                return GestureDetector(
                  key: _verseKeys[verse.verseNumber],
                  onLongPress: () => _onVerseLongPress(verse.verseNumber),
                  onTap: () => _onVerseTap(verse.verseNumber),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.4,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${verse.verseNumber}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_compareVerses.isEmpty)
                          Expanded(
                            child: Text(
                              verse.verseText,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          )
                        else ...[
                          Expanded(
                            child: Text(
                              verse.verseText,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              compareVerse?.verseText ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        if (_firstSelectedVerseNumber != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 88, // float 16px above collapsed bottom sheet (72px)
            child: _buildSelectionActionBar(theme),
          ),
      ],
    );
  }
}
