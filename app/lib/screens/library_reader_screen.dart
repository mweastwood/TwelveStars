import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/library_section_view.dart';
import 'package:twelve_stars/widgets/library_toc_drawer.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reading Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.format_size, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Font Size: ${_fontSize.round()} pt',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 28.0,
                    divisions: 16,
                    label: '${_fontSize.round()}',
                    onChanged: (val) {
                      setSheetState(() {
                        _fontSize = val;
                      });
                      setState(() {
                        _fontSize = val;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
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
                  ? _buildSearchResultsView(theme)
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

  Widget _buildSearchResultsView(ThemeData theme) {
    if (_searchQuery.trim().isEmpty) {
      return Center(
        child: Text(
          'Type a search term to find in this book.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No matches found for "$_searchQuery".',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, idx) {
        final res = _searchResults[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: ListTile(
            title: Text(
              res.sectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                res.matchedSnippet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            onTap: () {
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
          ),
        );
      },
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
              onShowCrossRefModal: _showCrossRefModal,
              onShowScriptureModal: _showScriptureModal,
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

  Future<void> _showCrossRefModal(int qNum) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (sheetCtx, scrollController) {
            return FutureBuilder<List<ParsedBookData?>>(
              future: Future.wait([
                LibraryHelper.loadBookData(
                  'assets/catechism/json/baltimore_2.json',
                ),
                LibraryHelper.loadBookData(
                  'assets/catechism/json/baltimore_4.json',
                ),
              ]),
              builder: (bCtx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final vol2 = snapshot.data![0];
                final vol4 = snapshot.data![1];

                ContentItem? q2Item;
                int? q2SecIdx;
                if (vol2 != null) {
                  for (int s = 0; s < vol2.sections.length; s++) {
                    for (final item in vol2.sections[s].content) {
                      if (item.type == 'qa' && item.questionNumber == qNum) {
                        q2Item = item;
                        q2SecIdx = s;
                        break;
                      }
                    }
                    if (q2Item != null) break;
                  }
                }

                ContentItem? q4Item;
                int? q4SecIdx;
                if (vol4 != null) {
                  for (int s = 0; s < vol4.sections.length; s++) {
                    for (final item in vol4.sections[s].content) {
                      if (item.type == 'qa' && item.questionNumber == qNum) {
                        q4Item = item;
                        q4SecIdx = s;
                        break;
                      }
                    }
                    if (q4Item != null) break;
                  }
                }

                final theme = Theme.of(context);
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cross-Reference: Master Question #$qNum',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (q2Item != null) ...[
                        Text(
                          'Baltimore Catechism No. 2 (Confirmation Edition)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q. ${q2Item.questionNumber}. ${q2Item.question}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('A. ${q2Item.answer}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (q4Item != null) ...[
                        Text(
                          'Baltimore Catechism No. 4 (Fr. Kinkead\'s Explanation)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPLANATION',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                q4Item.explanation ?? q4Item.answer ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (widget.bookItem.isSeries &&
                          widget.bookItem.volumes != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (q2SecIdx != null &&
                                widget.bookItem.volumes!.any(
                                  (v) => v.volumeKey == 'baltimore_2',
                                ))
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.bookmark_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Open Vol 2'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _switchVolume(
                                    widget.bookItem.volumes!.firstWhere(
                                      (v) => v.volumeKey == 'baltimore_2',
                                    ),
                                    initialSectionIndex: q2SecIdx!,
                                  );
                                },
                              ),
                            if (q4SecIdx != null &&
                                widget.bookItem.volumes!.any(
                                  (v) => v.volumeKey == 'baltimore_4',
                                ))
                              FilledButton.icon(
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                ),
                                label: const Text('Open Vol 4'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _switchVolume(
                                    widget.bookItem.volumes!.firstWhere(
                                      (v) => v.volumeKey == 'baltimore_4',
                                    ),
                                    initialSectionIndex: q4SecIdx!,
                                  );
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showScriptureModal(BibleCitation citation) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (sheetCtx, scrollController) {
            return FutureBuilder<List<BibleVerse>>(
              future: () async {
                await BibleDatabaseHelper.db.ensureBookPopulated(
                  citation.bookNumber,
                  citation.bookName,
                  citation.abbrev,
                );
                return await BibleDatabaseHelper.db.getChapterVerses(
                  'CPDV',
                  citation.bookNumber,
                  citation.chapter,
                );
              }(),
              builder: (bCtx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final verses = snapshot.data ?? [];
                final bool hasTargetVerse = citation.verse != null;
                final targetVerseNum = citation.verse ?? 1;
                final endVerseNum = citation.endVerse ?? targetVerseNum;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients &&
                      hasTargetVerse &&
                      targetVerseNum > 1) {
                    final targetIndex = verses.indexWhere(
                      (v) => v.verseNumber == targetVerseNum,
                    );
                    if (targetIndex > 0) {
                      final targetOffset = (targetIndex * 85.0).clamp(
                        0.0,
                        scrollController.position.maxScrollExtent,
                      );
                      scrollController.jumpTo(targetOffset);
                    }
                  }
                });

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${citation.bookName} ${citation.chapter}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Catholic Public Domain Version (CPDV)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: verses.length,
                          itemBuilder: (lCtx, index) {
                            final verse = verses[index];
                            final isTarget =
                                hasTargetVerse &&
                                verse.verseNumber >= targetVerseNum &&
                                verse.verseNumber <= endVerseNum;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 2.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 6.0,
                              ),
                              decoration: BoxDecoration(
                                color: isTarget
                                    ? theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.4)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                                border: isTarget
                                    ? Border(
                                        left: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 3.5,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${verse.verseNumber}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      verse.verseText,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            height: 1.5,
                                            fontWeight: isTarget
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
