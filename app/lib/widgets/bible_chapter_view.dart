import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/widgets/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/bible_ribbons_widget.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

class BibleChapterView extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final String primaryTranslation;
  final String compareTranslation;
  final BibleNumberingSystem numberingSystem;
  final Animation<double>? translationSelectorAnimation;
  final ScrollController? scrollController;
  final int? scrollToVerse;
  final int? highlightStartVerse;
  final int? highlightEndVerse;
  final String? navigationSessionId;
  final VoidCallback? onFavoriteSaved;
  final List<BibleRibbonBookmark>? bookmarks;

  const BibleChapterView({
    super.key,
    required this.book,
    required this.chapter,
    required this.primaryTranslation,
    required this.compareTranslation,
    this.numberingSystem = BibleNumberingSystem.vulgate,
    this.translationSelectorAnimation,
    this.scrollController,
    this.scrollToVerse,
    this.highlightStartVerse,
    this.highlightEndVerse,
    this.navigationSessionId,
    this.onFavoriteSaved,
    this.bookmarks,
  });

  @override
  State<BibleChapterView> createState() => _BibleChapterViewState();
}

class _BibleChapterViewState extends State<BibleChapterView>
    with AutomaticKeepAliveClientMixin {
  List<BibleVerse> _verses = [];
  List<BibleVerse> _compareVerses = [];
  List<UserComment> _comments = [];
  List<FavoritePassage> _favorites = [];
  bool _loading = true;
  String? _error;

  int? _firstSelectedVerseNumber;
  int? _lastSelectedVerseNumber;
  int? _temporaryHighlightStart;
  int? _temporaryHighlightEnd;
  String? _lastProcessedSessionId;
  Timer? _highlightTimer;

  final Map<int, GlobalKey> _verseKeys = {};

  @override
  bool get wantKeepAlive => true; // Cache adjacent chapters in memory

  @override
  void initState() {
    super.initState();
    _loadChapterData();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
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

  Future<void> _loadFavorites() async {
    try {
      final favorites = await BibleDatabaseHelper.db.getFavoritesForChapter(
        widget.book.bookNumber,
        widget.chapter,
      );
      if (mounted) {
        setState(() {
          _favorites = favorites;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    try {
      final comments = await BibleDatabaseHelper.db.getComments(
        documentId: widget.book.abbrev,
      );
      if (mounted) {
        setState(() {
          _comments = comments
              .where((c) => c.sectionIndex == widget.chapter)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadChapterData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      ReverseCitationService.ensureIndexed().then((_) {
        if (mounted) setState(() {});
      });
      final db = BibleDatabaseHelper.db;
      await _loadFavorites();
      await _loadComments();
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
        final targetVerse = _verses
            .where((v) => v.verseNumber == widget.scrollToVerse)
            .firstOrNull;
        final key = targetVerse != null ? _verseKeys[targetVerse.id] : null;
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });

      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 2), () {
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

    final selectedVerses =
        _verses
            .where((v) => v.verseNumber >= start && v.verseNumber <= end)
            .toList()
          ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
    final textPreview = selectedVerses.map((v) => v.verseText).join(' ');

    return ReaderSelectionActionBar(
      title: citation,
      selectedCount: count,
      itemLabel: 'verse',
      onSaveFavorite: () async {
        final favorite = FavoritePassagesCompanion.insert(
          bookNumber: widget.book.bookNumber,
          bookName: widget.book.bookName,
          chapter: widget.chapter,
          startVerse: start,
          endVerse: end,
          textPreview: textPreview,
        );

        await BibleDatabaseHelper.db.saveFavorite(favorite);
        await _loadFavorites();

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
      onAddComment: () => showAddCommentDialog(
        context: context,
        citation: citation,
        textPreview: textPreview,
        documentId: widget.book.abbrev,
        sectionIndex: widget.chapter,
        nodeId: '${widget.book.bookNumber}_${widget.chapter}_$start',
        onCommentSaved: () async {
          _clearSelection();
          await _loadComments();
        },
      ),
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
    );
  }

  String _getTranslationName(String code) {
    if (code == 'CPDV') return 'Catholic Public Domain Version (CPDV)';
    if (code == 'DRC') return 'Douay-Rheims Bible (DRC)';
    if (code == 'JUN') return 'Biblia de Jünemann (JUN)';
    if (code == 'TAM') return 'Torres Amat (TAM)';
    if (code == 'VUL') return 'Vulgata Clementina (VUL)';
    if (code == 'LXX') return 'Greek Septuagint (LXX)';
    if (code == 'ORIG') return 'Original Languages (ORIG)';
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

    final chapterCitations = ReverseCitationService.getChapterCitations(
      widget.book.bookNumber,
      widget.chapter,
    );

    return Stack(
      children: [
        SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            160.0, // space for bottom sheet + action bar
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              BiblePageRibbonsWidget(
                bookmarks: widget.bookmarks,
                bookNumber: widget.book.bookNumber,
                chapter: widget.chapter,
                top: -16.0,
                bottom: -16.0,
                left: -12.0,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.translationSelectorAnimation != null)
                    SizeTransition(
                      sizeFactor: widget.translationSelectorAnimation!,
                      alignment: Alignment.topCenter,
                      child: const SizedBox(height: 72.0),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BibleVerseResolver.formatChapterTitle(
                            bookNumber: widget.book.bookNumber,
                            bookName: widget.book.bookName,
                            chapter: widget.chapter,
                            numberingSystem: widget.numberingSystem,
                          ),
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
                        if (chapterCitations.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ActionChip(
                            avatar: Icon(
                              Icons.auto_stories_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              '${chapterCitations.length} Library Reference${chapterCitations.length > 1 ? "s" : ""} to ${widget.book.bookName} ${widget.chapter}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            backgroundColor: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            mouseCursor: SystemMouseCursors.click,
                            onPressed: () => showReverseCitationsModal(
                              context: context,
                              title:
                                  '${widget.book.bookName} ${widget.chapter}',
                              citations: chapterCitations,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  ..._verses.map((verse) {
                    final isSelected = _isVerseSelected(verse.verseNumber);
                    _verseKeys.putIfAbsent(verse.id, () => GlobalKey());

                    final verseCitations =
                        ReverseCitationService.getVerseCitations(
                          widget.book.bookNumber,
                          widget.chapter,
                          verse.verseNumber,
                        );

                    final nodeId =
                        '${verse.bookNumber}_${verse.chapter}_${verse.verseNumber}';
                    final verseComments = _comments
                        .where((c) => c.nodeId == nodeId)
                        .toList();

                    final matchingFavorites = _favorites
                        .where(
                          (fav) =>
                              verse.verseNumber >= fav.startVerse &&
                              verse.verseNumber <= fav.endVerse,
                        )
                        .toList();
                    final isFavorite = matchingFavorites.isNotEmpty;

                    BibleVerse? compareVerse;
                    if (_compareVerses.isNotEmpty) {
                      for (final cv in _compareVerses) {
                        if (cv.verseNumber == verse.verseNumber) {
                          compareVerse = cv;
                          break;
                        }
                      }
                    }

                    final verseDisplay = BibleVerseResolver.formatVerseDisplay(
                      bookNumber: widget.book.bookNumber,
                      chapter: widget.chapter,
                      verseNumber: verse.verseNumber,
                      numberingSystem: widget.numberingSystem,
                    );

                    return KeyedSubtree(
                      key: _verseKeys[verse.id],
                      child: BibleVerseRow(
                        verseNumber: verseDisplay.displayVerseNumber,
                        alternateVerseNumber: verseDisplay.alternateVerseNumber,
                        verseText: verse.verseText,
                        compareVerseText: compareVerse?.verseText,
                        isSelected: isSelected,
                        citationsCount: verseCitations.length,
                        commentsCount: verseComments.length,
                        isFavorite: isFavorite,
                        onTap: () => _onVerseTap(verse.verseNumber),
                        onLongPress: () => _onVerseLongPress(verse.verseNumber),
                        onTapCitations: () => showReverseCitationsModal(
                          context: context,
                          title:
                              '${widget.book.bookName} ${widget.chapter}:${verse.verseNumber}',
                          citations: verseCitations,
                        ),
                        onTapComments: () => showVerseCommentsModal(
                          context: context,
                          title:
                              '${widget.book.bookName} ${widget.chapter}:${verse.verseNumber}',
                          nodeId: nodeId,
                          textPreview: verse.verseText,
                          comments: verseComments,
                          onCommentsChanged: _loadComments,
                          onAddComment: () => showAddCommentDialog(
                            context: context,
                            citation:
                                '${widget.book.bookName} ${widget.chapter}:${verse.verseNumber}',
                            textPreview: verse.verseText,
                            documentId: widget.book.abbrev,
                            sectionIndex: widget.chapter,
                            nodeId: nodeId,
                            onCommentSaved: _loadComments,
                          ),
                        ),
                        onTapFavorite: () => showVerseFavoritesModal(
                          context: context,
                          title:
                              '${widget.book.bookName} ${widget.chapter}:${verse.verseNumber}',
                          favorites: matchingFavorites,
                          onFavoritesChanged: () async {
                            await _loadFavorites();
                            if (widget.onFavoriteSaved != null) {
                              widget.onFavoriteSaved!();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
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
