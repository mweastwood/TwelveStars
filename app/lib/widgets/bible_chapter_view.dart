import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reader/bible_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/reader/reader_selection_controller.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/bible_ribbons_widget.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

class BibleChapterView extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final String primaryTranslation;
  final String compareTranslation;
  final BibleNumberingSystem numberingSystem;
  final double fontSize;
  final Animation<double>? translationSelectorAnimation;
  final ScrollController? scrollController;
  final int? scrollToVerse;
  final int? highlightStartVerse;
  final int? highlightEndVerse;
  final String? navigationSessionId;
  final VoidCallback? onFavoriteSaved;
  final List<BibleRibbonBookmark>? bookmarks;
  final ValueChanged<bool>? onSelectionChanged;

  const BibleChapterView({
    super.key,
    required this.book,
    required this.chapter,
    required this.primaryTranslation,
    required this.compareTranslation,
    this.numberingSystem = BibleNumberingSystem.vulgate,
    this.fontSize = 16.0,
    this.translationSelectorAnimation,
    this.scrollController,
    this.scrollToVerse,
    this.highlightStartVerse,
    this.highlightEndVerse,
    this.navigationSessionId,
    this.onFavoriteSaved,
    this.bookmarks,
    this.onSelectionChanged,
  });

  @override
  State<BibleChapterView> createState() => _BibleChapterViewState();
}

class _BibleChapterViewState extends State<BibleChapterView>
    with AutomaticKeepAliveClientMixin {
  late BibleReaderAdapter _adapter;
  final ReaderSelectionController _selectionController =
      ReaderSelectionController();

  List<BibleVerse> _verses = [];
  Map<int, BibleVerse> _compareVersesByNumber = {};
  Map<String, List<UserComment>> _commentsByNodeId = {};
  Map<int, List<FavoritePassage>> _favoritesByVerse = {};
  bool _loading = true;
  String? _error;

  final Map<int, GlobalKey> _verseKeys = {};
  int _loadGeneration = 0;
  bool _isSubscribedToIndexing = false;

  @override
  bool get wantKeepAlive => true; // Cache adjacent chapters in memory

  @override
  void initState() {
    super.initState();
    _adapter = BibleReaderAdapter(bibleBook: widget.book);
    _loadChapterData();
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BibleChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bookChanged = oldWidget.book.bookNumber != widget.book.bookNumber;
    final chapterChanged = bookChanged || oldWidget.chapter != widget.chapter;
    if (bookChanged) {
      _adapter = BibleReaderAdapter(bibleBook: widget.book);
    }
    if (chapterChanged ||
        oldWidget.primaryTranslation != widget.primaryTranslation ||
        oldWidget.compareTranslation != widget.compareTranslation) {
      if (_selectionController.hasSelection) {
        widget.onSelectionChanged?.call(false);
      }
      _selectionController.clear();
      if (chapterChanged) {
        _verseKeys.clear();
        _favoritesByVerse = {};
        _commentsByNodeId = {};
      }
      _loadChapterData();
    } else if (widget.navigationSessionId != oldWidget.navigationSessionId) {
      _scrollToAndHighlightTarget();
    }
  }

  Future<void> _loadFavorites() async {
    final byVerse = await _adapter.fetchFavoritesByVerse(
      widget.chapter,
      fallback: _favoritesByVerse,
    );
    if (mounted) {
      setState(() {
        _favoritesByVerse = byVerse;
      });
    }
  }

  Future<void> _loadComments() async {
    final byNodeId = await _adapter.fetchCommentsByNodeId(
      widget.chapter,
      fallback: _commentsByNodeId,
    );
    if (mounted) {
      setState(() {
        _commentsByNodeId = byNodeId;
      });
    }
  }

  Future<void> _loadChapterData() async {
    if (!mounted) return;
    final loadGen = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!ReverseCitationService.isCatalogFullyIndexed &&
          !_isSubscribedToIndexing) {
        _isSubscribedToIndexing = true;
        ReverseCitationService.ensureIndexed().then((_) {
          _isSubscribedToIndexing = false;
          if (mounted && !_loading) setState(() {});
        });
      }

      final chapterData = await _adapter.loadChapterData(
        widget.chapter,
        primaryTranslation: widget.primaryTranslation,
        compareTranslation: widget.compareTranslation,
      );

      if (!mounted || loadGen != _loadGeneration) return;
      setState(() {
        _favoritesByVerse = chapterData.favoritesByVerse;
        _commentsByNodeId = chapterData.commentsByNodeId;
        _verses = chapterData.verses;
        _compareVersesByNumber = chapterData.compareVersesByNumber;
        _loading = false;
      });
      _scrollToAndHighlightTarget();
    } catch (e) {
      if (!mounted || loadGen != _loadGeneration) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToAndHighlightTarget() {
    if (_selectionController.shouldProcessTarget(
      hasTarget: widget.scrollToVerse != null,
      navigationSessionId: widget.navigationSessionId,
      requireSessionIdMatchOnly: true,
    )) {
      _selectionController.activateTemporaryHighlight(
        start: widget.highlightStartVerse,
        end: widget.highlightEndVerse,
        navigationSessionId: widget.navigationSessionId,
        onExpired: () {
          if (mounted) setState(() {});
        },
      );

      _selectionController.scrollToKeyPostFrame(() {
        final targetVerse = _verses
            .where((v) => v.verseNumber == widget.scrollToVerse)
            .firstOrNull;
        return targetVerse != null ? _verseKeys[targetVerse.id] : null;
      });
    }
  }

  void _onVerseLongPress(int verseNumber) {
    setState(() {
      _selectionController.onLongPress(verseNumber);
    });
    widget.onSelectionChanged?.call(true);
  }

  void _onVerseTap(int verseNumber) {
    if (_selectionController.hasSelection) {
      setState(() {
        _selectionController.onTap(verseNumber);
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectionController.clear();
    });
    widget.onSelectionChanged?.call(false);
  }

  Widget _buildSelectionActionBar(ThemeData theme) {
    final start = _selectionController.start!;
    final end = _selectionController.end!;
    final count = _selectionController.selectedCount;
    final citation = _adapter.formatSelectionCitation(
      widget.chapter,
      start,
      end,
    );

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
        await _adapter.saveFavoriteRange(
          chapterNumber: widget.chapter,
          startVerse: start,
          endVerse: end,
          textPreview: textPreview,
        );
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
        nodeId: ReaderNodeId.bibleVerse(
          widget.book.bookNumber,
          widget.chapter,
          start,
        ),
        onCommentSaved: () async {
          _clearSelection();
          await _loadComments();
        },
      ),
      onCopy: () async {
        final clipboardContent = _adapter.formatClipboardContent(
          citation,
          selectedVerses,
        );
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

  Widget _buildChapterCitationsChip(
    BuildContext context,
    ThemeData theme,
    List<ReverseCitation> citations,
  ) {
    return Tooltip(
      message:
          '${citations.length} Library Reference${citations.length > 1 ? "s" : ""} to ${widget.book.bookName} ${widget.chapter}',
      child: InkWell(
        key: const Key('chapter_citations_chip'),
        mouseCursor: SystemMouseCursors.click,
        onTap: () => showReverseCitationsModal(
          context: context,
          title: '${widget.book.bookName} ${widget.chapter}',
          citations: citations,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 13,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                '${citations.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    return RepaintBoundary(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(
              16.0,
              48.0,
              16.0,
              160.0, // space for bottom sheet + action bar
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              BibleVerseResolver.formatChapterTitle(
                                bookNumber: widget.book.bookNumber,
                                bookName: widget.book.bookName,
                                chapter: widget.chapter,
                                numberingSystem: widget.numberingSystem,
                              ),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontFamily: 'CinzelDecorative',
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          if (chapterCitations.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Padding(
                              // Compensates for the font descender space (~6.0px in headlineMedium CinzelDecorative),
                              // aligning the bottom of the chip with the baseline of the chapter title text.
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: _buildChapterCitationsChip(
                                context,
                                theme,
                                chapterCitations,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_verses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 32.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.primaryTranslation == 'LXX'
                                      ? 'The Septuagint (LXX) contains only Old Testament books. Select another translation to read ${widget.book.bookName}.'
                                      : 'No verses available for ${widget.book.bookName} in this translation.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._verses.map((verse) {
                        final isSelected = _selectionController.isSelected(
                          verse.verseNumber,
                        );
                        _verseKeys.putIfAbsent(verse.id, () => GlobalKey());

                        final verseCitations =
                            ReverseCitationService.getVerseCitations(
                              widget.book.bookNumber,
                              widget.chapter,
                              verse.verseNumber,
                            );

                        final nodeId = ReaderNodeId.bibleVerse(
                          verse.bookNumber,
                          verse.chapter,
                          verse.verseNumber,
                        );
                        final verseComments =
                            _commentsByNodeId[nodeId] ?? const [];

                        final matchingFavorites =
                            _favoritesByVerse[verse.verseNumber] ?? const [];
                        final isFavorite = matchingFavorites.isNotEmpty;

                        final compareVerse =
                            _compareVersesByNumber[verse.verseNumber];

                        final verseDisplay =
                            BibleVerseResolver.formatVerseDisplay(
                              bookNumber: widget.book.bookNumber,
                              chapter: widget.chapter,
                              verseNumber: verse.verseNumber,
                              numberingSystem: widget.numberingSystem,
                            );

                        return KeyedSubtree(
                          key: _verseKeys[verse.id],
                          child: BibleVerseRow(
                            verseNumber: verseDisplay.displayVerseNumber,
                            alternateVerseNumber:
                                verseDisplay.alternateVerseNumber,
                            verseText: verse.verseText,
                            compareVerseText: compareVerse?.verseText,
                            isSelected: isSelected,
                            fontSize: widget.fontSize == 16.0
                                ? null
                                : widget.fontSize,
                            margin: const EdgeInsets.only(
                              left: 16.0,
                              top: 2.0,
                              bottom: 2.0,
                            ),
                            citationsCount: verseCitations.length,
                            commentsCount: verseComments.length,
                            isFavorite: isFavorite,
                            onTap: () => _onVerseTap(verse.verseNumber),
                            onLongPress: () =>
                                _onVerseLongPress(verse.verseNumber),
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
                BiblePageRibbonsWidget(
                  bookmarks: widget.bookmarks,
                  bookNumber: widget.book.bookNumber,
                  chapter: widget.chapter,
                  top: -48.0,
                  bottom: -16.0,
                  left: -12.0,
                ),
              ],
            ),
          ),
          if (_selectionController.hasSelection)
            Positioned(
              left: 16,
              right: 16,
              bottom: 88, // float 16px above collapsed bottom sheet (72px)
              child: _buildSelectionActionBar(theme),
            ),
        ],
      ),
    );
  }
}
