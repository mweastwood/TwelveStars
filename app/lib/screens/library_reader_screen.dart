import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library_section_view.dart';
import 'package:twelve_stars/widgets/library_toc_drawer.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/reader/library_cross_ref_sheet.dart';
import 'package:twelve_stars/widgets/reader/library_scripture_modal.dart';
import 'package:twelve_stars/widgets/reader/library_search_results_view.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
import 'package:twelve_stars/widgets/reader/reader_text_options_sheet.dart';

class LibraryReaderScreen extends StatefulWidget {
  final LibraryBookItem bookItem;
  final String? initialAssetPath;
  final String? initialVolumeKey;
  final String? initialSectionId;
  final int? initialSectionIndex;
  final int? initialQuestionNumber;
  final int? initialItemIndex;
  final String? navigationSessionId;
  final VoidCallback? onFavoriteSaved;

  const LibraryReaderScreen({
    super.key,
    required this.bookItem,
    this.initialAssetPath,
    this.initialVolumeKey,
    this.initialSectionId,
    this.initialSectionIndex,
    this.initialQuestionNumber,
    this.initialItemIndex,
    this.navigationSessionId,
    this.onFavoriteSaved,
  });

  @override
  State<LibraryReaderScreen> createState() => _LibraryReaderScreenState();
}

class _LibraryReaderScreenState extends State<LibraryReaderScreen> {
  late String _currentAssetPath;
  String? _currentVolumeKey;
  bool _isLoading = true;
  String? _error;
  ParsedBookData? _bookData;

  late PageController _pageController;
  int _currentSectionIndex = 0;
  double _fontSize = 16.0;
  final Map<int, GlobalKey> _questionKeys = {};
  final Map<int, GlobalKey> _itemKeys = {};

  int? _firstSelectedItemIndex;
  int? _lastSelectedItemIndex;
  int? _temporaryHighlightStartIndex;
  int? _temporaryHighlightEndIndex;
  String? _lastProcessedSessionId;
  Timer? _highlightTimer;
  List<UserComment> _comments = [];

  bool _isSearching = false;
  String _searchQuery = '';
  List<BookSearchResult> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentSectionIndex = widget.initialSectionIndex ?? 0;
    _pageController = PageController(initialPage: _currentSectionIndex);
    if (widget.bookItem.isSeries) {
      if (widget.initialVolumeKey != null) {
        _currentVolumeKey = widget.initialVolumeKey;
        final selectedVol = widget.bookItem.volumes!.firstWhere(
          (v) => v.volumeKey == _currentVolumeKey,
          orElse: () => widget.bookItem.volumes!.first,
        );
        _currentAssetPath = selectedVol.assetPath;
      } else if (widget.initialAssetPath != null) {
        final selectedVol = widget.bookItem.volumes!.firstWhere(
          (v) => v.assetPath == widget.initialAssetPath,
          orElse: () => widget.bookItem.volumes!.first,
        );
        _currentVolumeKey = selectedVol.volumeKey;
        _currentAssetPath = selectedVol.assetPath;
      } else {
        _currentVolumeKey = widget.bookItem.volumes!.first.volumeKey;
        _currentAssetPath = widget.bookItem.volumes!.first.assetPath;
      }
    } else {
      _currentAssetPath =
          widget.initialAssetPath ?? widget.bookItem.defaultAssetPath!;
    }
    _loadComments();
    _loadBookData(
      isInitialLoad: true,
      initialSectionIndex: _currentSectionIndex,
    );
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LibraryReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationSessionId != oldWidget.navigationSessionId) {
      _scrollToAndHighlightTarget();
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await BibleDatabaseHelper.db.getComments(
        documentId: widget.bookItem.id,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (_) {}
  }

  void _populateKeys(ParsedBookData? data, int sectionIndex) {
    _questionKeys.clear();
    _itemKeys.clear();
    if (data != null &&
        sectionIndex >= 0 &&
        sectionIndex < data.sections.length) {
      final sec = data.sections[sectionIndex];
      for (int i = 0; i < sec.content.length; i++) {
        _itemKeys[i] = GlobalKey();
        final item = sec.content[i];
        if (item.type == 'qa' && item.questionNumber != null) {
          _questionKeys[item.questionNumber!] = GlobalKey();
        }
      }
    }
  }

  void _scrollToAndHighlightTarget() {
    if ((widget.initialItemIndex != null ||
            widget.initialQuestionNumber != null) &&
        widget.navigationSessionId != _lastProcessedSessionId) {
      _lastProcessedSessionId = widget.navigationSessionId;
      _temporaryHighlightStartIndex = widget.initialItemIndex;
      _temporaryHighlightEndIndex = widget.initialItemIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        GlobalKey? targetKey;
        if (widget.initialItemIndex != null &&
            _itemKeys.containsKey(widget.initialItemIndex!)) {
          targetKey = _itemKeys[widget.initialItemIndex!];
        } else if (widget.initialQuestionNumber != null &&
            _questionKeys.containsKey(widget.initialQuestionNumber!)) {
          targetKey = _questionKeys[widget.initialQuestionNumber!];
        }

        if (targetKey != null && targetKey.currentContext != null) {
          Scrollable.ensureVisible(
            targetKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });

      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _temporaryHighlightStartIndex = null;
            _temporaryHighlightEndIndex = null;
          });
        }
      });
    }
  }

  Future<void> _loadBookData({
    bool isInitialLoad = false,
    int initialSectionIndex = 0,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _questionKeys.clear();
      _itemKeys.clear();
      _firstSelectedItemIndex = null;
      _lastSelectedItemIndex = null;
    });

    try {
      final data = await LibraryHelper.loadBookData(_currentAssetPath);
      if (mounted) {
        int resolvedIndex = initialSectionIndex;
        if (isInitialLoad && widget.initialSectionId != null) {
          final idx = data.sections.indexWhere(
            (s) => s.id == widget.initialSectionId,
          );
          if (idx >= 0) resolvedIndex = idx;
        } else if (isInitialLoad && widget.initialSectionIndex != null) {
          resolvedIndex = widget.initialSectionIndex!;
        }
        _populateKeys(data, resolvedIndex);

        if (_pageController.hasClients) {
          _pageController.jumpToPage(resolvedIndex);
        } else {
          _pageController.dispose();
          _pageController = PageController(initialPage: resolvedIndex);
        }

        setState(() {
          _bookData = data;
          _currentSectionIndex = resolvedIndex;
          _isLoading = false;
        });

        _scrollToAndHighlightTarget();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _switchVolume(BaltimoreVolume vol, {int initialSectionIndex = 0}) {
    if (_currentVolumeKey == vol.volumeKey) {
      if (_currentSectionIndex != initialSectionIndex) {
        setState(() {
          _currentSectionIndex = initialSectionIndex;
          _clearSelection();
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(initialSectionIndex);
        }
      }
      return;
    }
    setState(() {
      _currentVolumeKey = vol.volumeKey;
      _currentAssetPath = vol.assetPath;
      _clearSelection();
    });
    _loadBookData(initialSectionIndex: initialSectionIndex);
  }

  void _onItemLongPress(int index) {
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _firstSelectedItemIndex = index;
      _lastSelectedItemIndex = index;
    });
  }

  void _onItemTap(int index) {
    if (_firstSelectedItemIndex != null) {
      setState(() {
        _lastSelectedItemIndex = index;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _firstSelectedItemIndex = null;
      _lastSelectedItemIndex = null;
    });
  }

  String _buildItemCitation(BookSection section, int startIndex, int endIndex) {
    String baseTitle = widget.bookItem.title;
    if (widget.bookItem.isSeries && widget.bookItem.volumes != null) {
      final vol = widget.bookItem.volumes!.firstWhere(
        (v) => v.volumeKey == _currentVolumeKey,
        orElse: () => widget.bookItem.volumes!.first,
      );
      baseTitle = '${widget.bookItem.title} (${vol.shortName})';
    }

    final startItem = section.content[startIndex];
    final endItem = section.content[endIndex];

    if (startItem.type == 'qa' &&
        endItem.type == 'qa' &&
        startItem.questionNumber != null &&
        endItem.questionNumber != null) {
      if (startItem.questionNumber == endItem.questionNumber) {
        return '$baseTitle, ${section.title}, Q. ${startItem.questionNumber}';
      } else {
        final qMin = min(startItem.questionNumber!, endItem.questionNumber!);
        final qMax = max(startItem.questionNumber!, endItem.questionNumber!);
        return '$baseTitle, ${section.title}, Q. $qMin–$qMax';
      }
    }

    return '$baseTitle, ${section.title}';
  }

  String _buildItemTextPreview(
    BookSection section,
    int startIndex,
    int endIndex,
  ) {
    final buffer = StringBuffer();
    for (int i = startIndex; i <= endIndex; i++) {
      final item = section.content[i];
      if (item.type == 'qa') {
        final q = item.question ?? '';
        final a = item.answer ?? '';
        buffer.writeln('Q. $q');
        buffer.writeln('A. $a');
      } else if (item.type == 'heading') {
        buffer.writeln(item.text ?? '');
      } else {
        buffer.writeln(item.text ?? '');
      }
      if (i < endIndex) buffer.writeln();
    }
    return buffer.toString().trim();
  }

  Widget _buildSelectionActionBar(ThemeData theme) {
    if (_bookData == null ||
        _currentSectionIndex >= _bookData!.sections.length ||
        _firstSelectedItemIndex == null ||
        _lastSelectedItemIndex == null) {
      return const SizedBox.shrink();
    }

    final section = _bookData!.sections[_currentSectionIndex];
    final start = min(_firstSelectedItemIndex!, _lastSelectedItemIndex!);
    final end = max(_firstSelectedItemIndex!, _lastSelectedItemIndex!);
    final count = end - start + 1;

    final citation = _buildItemCitation(section, start, end);
    final textPreview = _buildItemTextPreview(section, start, end);
    final nodeId =
        '${_currentVolumeKey != null ? '$_currentVolumeKey:' : ''}${section.id}_$start';

    return ReaderSelectionActionBar(
      title: citation,
      selectedCount: count,
      itemLabel: 'passage',
      onSaveFavorite: () async {
        final bookmark = LibraryBookmarksCompanion.insert(
          documentId: widget.bookItem.id,
          sectionIndex: _currentSectionIndex,
          nodeId: nodeId,
          textPreview: '$citation\n$textPreview',
          createdAt: DateTime.now(),
        );

        await BibleDatabaseHelper.db.saveLibraryBookmark(bookmark);

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
        documentId: widget.bookItem.id,
        sectionIndex: _currentSectionIndex,
        nodeId: nodeId,
        onCommentSaved: () async {
          _clearSelection();
          await _loadComments();
        },
      ),
      onCopy: () async {
        final clipboardContent = '$citation\n\n$textPreview';
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

  void _openTocSheet(BuildContext context, ThemeData theme) {
    final book = _bookData;
    if (book == null) return;

    LibraryTocDrawer.show(
      context,
      book: book,
      currentSectionIndex: _currentSectionIndex,
      onSectionSelected: (idx) {
        setState(() {
          _currentSectionIndex = idx;
          _populateKeys(_bookData, idx);
          _clearSelection();
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(idx);
        }
      },
    );
  }

  void _openFontDialog(BuildContext context, ThemeData theme) {
    ReaderTextOptionsSheet.show(
      context,
      fontSize: _fontSize,
      onFontSizeChanged: (val) {
        setState(() {
          _fontSize = val;
        });
      },
    );
  }

  void _performSearch(String query) {
    if (_bookData == null) return;
    final results = LibraryHelper.searchInBook(_bookData!, query);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = _bookData;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Search in book...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                  _performSearch(val);
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bookItem.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book != null)
                    Text(
                      book.subtitle.isNotEmpty ? book.subtitle : book.title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchResults = [];
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search in Book',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'Table of Contents',
              onPressed: () => _openTocSheet(context, theme),
            ),
            IconButton(
              icon: const Icon(Icons.text_fields),
              tooltip: 'Text Options',
              onPressed: () => _openFontDialog(context, theme),
            ),
          ],
        ],
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.dispose();
                  _pageController = PageController(
                    initialPage: _currentSectionIndex,
                  );
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Series Volume Selector Header (for Baltimore Catechism)
            if (widget.bookItem.isSeries && !_isSearching)
              Container(
                color: theme.colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Edition: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.bookItem.volumes!.map((vol) {
                            final isSel = vol.volumeKey == _currentVolumeKey;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(vol.shortName),
                                selected: isSel,
                                onSelected: (selected) {
                                  if (selected) _switchVolume(vol);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Reader / Search Results View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error loading book: $_error',
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _isSearching
                  ? LibrarySearchResultsView(
                      searchQuery: _searchQuery,
                      searchResults: _searchResults,
                      onResultTap: (res) {
                        final secIdx =
                            _bookData?.sections.indexWhere(
                              (s) => s.id == res.sectionId,
                            ) ??
                            -1;
                        if (secIdx >= 0) {
                          _pageController.dispose();
                          _pageController = PageController(initialPage: secIdx);
                          setState(() {
                            _currentSectionIndex = secIdx;
                            _populateKeys(_bookData, secIdx);
                            _isSearching = false;
                            _searchQuery = '';
                            _searchController.clear();
                            _searchResults = [];
                          });
                        }
                      },
                    )
                  : _buildSectionContentView(theme, book!),
            ),

            // Bottom Section Navigation Footer
            if (!_isSearching && book != null && book.sections.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous Section',
                      onPressed: _currentSectionIndex > 0
                          ? () {
                              _clearSelection();
                              if (_pageController.hasClients) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                setState(() {
                                  _currentSectionIndex--;
                                  _populateKeys(
                                    _bookData,
                                    _currentSectionIndex,
                                  );
                                });
                              }
                            }
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'Section ${_currentSectionIndex + 1} of ${book.sections.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next Section',
                      onPressed: _currentSectionIndex < book.sections.length - 1
                          ? () {
                              _clearSelection();
                              if (_pageController.hasClients) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                setState(() {
                                  _currentSectionIndex++;
                                  _populateKeys(
                                    _bookData,
                                    _currentSectionIndex,
                                  );
                                });
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContentView(ThemeData theme, ParsedBookData book) {
    if (book.sections.isEmpty) {
      return const Center(child: Text('No content found in this volume.'));
    }

    // Build map of nodeId -> list of comments for the current section
    final sectionCommentsMap = <String, List<UserComment>>{};
    for (final c in _comments) {
      if (c.sectionIndex == _currentSectionIndex) {
        sectionCommentsMap.putIfAbsent(c.nodeId, () => []).add(c);
      }
    }

    final int? selStart = _firstSelectedItemIndex != null
        ? min(_firstSelectedItemIndex!, _lastSelectedItemIndex!)
        : (_temporaryHighlightStartIndex != null
              ? min(
                  _temporaryHighlightStartIndex!,
                  _temporaryHighlightEndIndex!,
                )
              : null);
    final int? selEnd = _firstSelectedItemIndex != null
        ? max(_firstSelectedItemIndex!, _lastSelectedItemIndex!)
        : (_temporaryHighlightStartIndex != null
              ? max(
                  _temporaryHighlightStartIndex!,
                  _temporaryHighlightEndIndex!,
                )
              : null);

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: book.sections.length,
          onPageChanged: (index) {
            setState(() {
              _currentSectionIndex = index;
              _populateKeys(_bookData, index);
              _clearSelection();
            });
          },
          itemBuilder: (context, index) {
            final sec = book.sections[index];
            return LibrarySectionView(
              section: sec,
              fontSize: _fontSize,
              verseSystem: widget.bookItem.verseSystem,
              volumeKey: _currentVolumeKey,
              questionKeys: index == _currentSectionIndex
                  ? _questionKeys
                  : null,
              itemKeys: index == _currentSectionIndex ? _itemKeys : null,
              selectedStartIndex: index == _currentSectionIndex
                  ? selStart
                  : null,
              selectedEndIndex: index == _currentSectionIndex ? selEnd : null,
              onItemLongPress: index == _currentSectionIndex
                  ? _onItemLongPress
                  : null,
              onItemTap: index == _currentSectionIndex ? _onItemTap : null,
              commentsMap: index == _currentSectionIndex
                  ? sectionCommentsMap
                  : null,
              onTapComments: (nodeId, citation, textPreview, itemComments) {
                showVerseCommentsModal(
                  context: context,
                  title: citation,
                  nodeId: nodeId,
                  textPreview: textPreview,
                  comments: itemComments,
                  onCommentsChanged: _loadComments,
                  onAddComment: () => showAddCommentDialog(
                    context: context,
                    citation: citation,
                    textPreview: textPreview,
                    documentId: widget.bookItem.id,
                    sectionIndex: _currentSectionIndex,
                    nodeId: nodeId,
                    onCommentSaved: _loadComments,
                  ),
                );
              },
              onShowCrossRefModal: (qNum) => showBaltimoreCrossRefSheet(
                context: context,
                questionNumber: qNum,
                bookItem: widget.bookItem,
                onSwitchVolume: (vol, idx) =>
                    _switchVolume(vol, initialSectionIndex: idx),
              ),
              onShowScriptureModal: (citation) => showLibraryScriptureModal(
                context: context,
                citation: citation,
              ),
            );
          },
        ),
        if (_firstSelectedItemIndex != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildSelectionActionBar(theme),
          ),
      ],
    );
  }
}
