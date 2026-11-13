import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/reader/reader_selection_controller.dart';
import 'package:twelve_stars/widgets/library/library_reader_modals.dart';
import 'package:twelve_stars/widgets/reader/library_edition_selector_bar.dart';
import 'package:twelve_stars/widgets/reader/library_search_results_view.dart';
import 'package:twelve_stars/widgets/reader/reader_section_navigation_bar.dart';

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
  late LibraryReaderAdapter _adapter;
  final ReaderSelectionController _selectionController =
      ReaderSelectionController();

  bool _isLoading = true;
  String? _error;
  ParsedBookData? _bookData;

  late PageController _pageController;
  int _currentSectionIndex = 0;
  double _fontSize = 16.0;
  final Map<int, Map<int, GlobalKey>> _sectionQuestionKeys = {};
  final Map<int, Map<int, GlobalKey>> _sectionItemKeys = {};
  int _loadGeneration = 0;
  int _commentsLoadGeneration = 0;

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

    final resolved = LibraryReaderAdapter.resolveInitialSource(
      widget.bookItem,
      initialVolumeKey: widget.initialVolumeKey,
      initialAssetPath: widget.initialAssetPath,
    );
    _currentVolumeKey = resolved.volumeKey;
    if (resolved.assetPath == null) {
      _currentAssetPath = '';
      _adapter = LibraryReaderAdapter(
        bookItem: widget.bookItem,
        assetPath: '',
        volumeKey: _currentVolumeKey,
      );
      _isLoading = false;
      _error = 'No reader content available for this title.';
      return;
    }

    _currentAssetPath = resolved.assetPath!;
    _adapter = LibraryReaderAdapter(
      bookItem: widget.bookItem,
      assetPath: _currentAssetPath,
      volumeKey: _currentVolumeKey,
    );

    _loadComments();
    _loadBookData(
      isInitialLoad: true,
      initialSectionIndex: _currentSectionIndex,
    );
  }

  @override
  void dispose() {
    _selectionController.dispose();
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
    final generation = ++_commentsLoadGeneration;
    final adapter = _adapter;
    final comments = await adapter.loadUserComments();
    if (!mounted ||
        generation != _commentsLoadGeneration ||
        !identical(adapter, _adapter)) {
      return;
    }
    setState(() => _comments = comments);
  }

  void _populateKeys(ParsedBookData? data, int sectionIndex) {
    if (data == null ||
        sectionIndex < 0 ||
        sectionIndex >= data.sections.length ||
        (_sectionItemKeys.containsKey(sectionIndex) &&
            _sectionQuestionKeys.containsKey(sectionIndex))) {
      return;
    }
    final sec = data.sections[sectionIndex];
    final itemKeys = <int, GlobalKey>{};
    final questionKeys = <int, GlobalKey>{};
    for (int i = 0; i < sec.content.length; i++) {
      final key = GlobalKey();
      itemKeys[i] = key;
      final item = sec.content[i];
      if (item.type == 'qa' && item.questionNumber != null) {
        questionKeys.putIfAbsent(item.questionNumber!, () => key);
      }
    }
    _sectionItemKeys[sectionIndex] = itemKeys;
    _sectionQuestionKeys[sectionIndex] = questionKeys;
  }

  void _highlightAndScrollTo({
    int? itemIndex,
    int? questionNumber,
    String? navigationSessionId,
  }) {
    final hasValidSection =
        _bookData != null &&
        _currentSectionIndex >= 0 &&
        _currentSectionIndex < _bookData!.sections.length;
    final effectiveItemIndex = hasValidSection
        ? LibraryReaderAdapter.resolveTargetItemIndex(
            _bookData!.sections[_currentSectionIndex],
            itemIndex: itemIndex,
            questionNumber: questionNumber,
          )
        : itemIndex;

    if (effectiveItemIndex == null && questionNumber == null) return;

    setState(() {
      _selectionController.activateTemporaryHighlight(
        start: effectiveItemIndex,
        end: effectiveItemIndex,
        navigationSessionId: navigationSessionId,
        onExpired: () {
          if (mounted) setState(() {});
        },
      );
    });

    _selectionController.scrollToKeyPostFrame(() {
      final itemKeys = _sectionItemKeys[_currentSectionIndex];
      if (effectiveItemIndex != null &&
          itemKeys != null &&
          itemKeys.containsKey(effectiveItemIndex)) {
        return itemKeys[effectiveItemIndex];
      }
      final questionKeys = _sectionQuestionKeys[_currentSectionIndex];
      if (questionNumber != null &&
          questionKeys != null &&
          questionKeys.containsKey(questionNumber)) {
        return questionKeys[questionNumber];
      }
      return null;
    }, alignment: 0.1);
  }

  void _scrollToAndHighlightTarget() {
    final hasTarget =
        widget.initialItemIndex != null || widget.initialQuestionNumber != null;
    if (!_selectionController.shouldProcessTarget(
      hasTarget: hasTarget,
      navigationSessionId: widget.navigationSessionId,
    )) {
      return;
    }

    _highlightAndScrollTo(
      itemIndex: widget.initialItemIndex,
      questionNumber: widget.initialQuestionNumber,
      navigationSessionId: widget.navigationSessionId,
    );
  }

  Future<void> _saveReadingPosition(int sectionIndex) async {
    if (_bookData == null ||
        sectionIndex < 0 ||
        sectionIndex >= _bookData!.sections.length) {
      return;
    }
    await _adapter.saveReadingPosition(
      sectionIndex: sectionIndex,
      sectionId: _bookData!.sections[sectionIndex].id,
    );
  }

  Future<void> _loadBookData({
    bool isInitialLoad = false,
    int initialSectionIndex = 0,
    int? targetQuestionNumber,
    int? targetItemIndex,
  }) async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
      _sectionQuestionKeys.clear();
      _sectionItemKeys.clear();
      _selectionController.clear();
    });

    try {
      BookReadingPosition? savedPos;
      if (isInitialLoad &&
          widget.initialSectionIndex == null &&
          widget.initialSectionId == null) {
        savedPos = await _adapter.getReadingPosition();
        if (!mounted || generation != _loadGeneration) return;
      }

      if (isInitialLoad &&
          savedPos != null &&
          widget.bookItem.isSeries &&
          widget.initialVolumeKey == null &&
          widget.initialAssetPath == null &&
          savedPos.volumeKey != null) {
        final matchingVol = widget.bookItem.volumes?.firstWhere(
          (v) => v.volumeKey == savedPos!.volumeKey,
          orElse: () => widget.bookItem.volumes!.first,
        );
        if (matchingVol != null) {
          _currentVolumeKey = matchingVol.volumeKey;
          _currentAssetPath = matchingVol.assetPath;
          _adapter = LibraryReaderAdapter(
            bookItem: widget.bookItem,
            assetPath: _currentAssetPath,
            volumeKey: _currentVolumeKey,
          );
        }
      }

      final data = await _adapter.loadBookData();
      if (!mounted || generation != _loadGeneration) return;

      final resolvedIndex = isInitialLoad
          ? LibraryReaderAdapter.resolveInitialSectionIndex(
              data,
              bookItem: widget.bookItem,
              currentVolumeKey: _currentVolumeKey,
              initialSectionId: widget.initialSectionId,
              initialSectionIndex: widget.initialSectionIndex,
              savedPos: savedPos,
              fallbackIndex: initialSectionIndex,
            )
          : initialSectionIndex;

      setState(() {
        _bookData = data;
        _currentSectionIndex = resolvedIndex;
        _populateKeys(data, resolvedIndex);
        _isLoading = false;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(resolvedIndex);
      } else {
        _pageController.dispose();
        _pageController = PageController(initialPage: resolvedIndex);
      }

      _saveReadingPosition(resolvedIndex);
      if (targetItemIndex != null || targetQuestionNumber != null) {
        _highlightAndScrollTo(
          itemIndex: targetItemIndex,
          questionNumber: targetQuestionNumber,
          navigationSessionId:
              'volswitch_${DateTime.now().microsecondsSinceEpoch}',
        );
      } else {
        _scrollToAndHighlightTarget();
      }
    } catch (e) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _switchVolume(
    BaltimoreVolume vol, {
    int initialSectionIndex = 0,
    int? targetQuestionNumber,
    int? targetItemIndex,
  }) {
    if (_currentVolumeKey == vol.volumeKey) {
      ++_loadGeneration;
      if (_currentSectionIndex != initialSectionIndex) {
        _jumpToSection(initialSectionIndex);
      } else {
        setState(
          () => _selectionController.clear(clearTemporaryHighlight: true),
        );
      }
      if (targetItemIndex != null || targetQuestionNumber != null) {
        _populateKeys(_bookData, initialSectionIndex);
        _highlightAndScrollTo(
          itemIndex: targetItemIndex,
          questionNumber: targetQuestionNumber,
          navigationSessionId:
              'crossref_${DateTime.now().microsecondsSinceEpoch}',
        );
      }
      return;
    }
    setState(() {
      _currentVolumeKey = vol.volumeKey;
      _currentAssetPath = vol.assetPath;
      _adapter = LibraryReaderAdapter(
        bookItem: widget.bookItem,
        assetPath: _currentAssetPath,
        volumeKey: _currentVolumeKey,
      );
      _selectionController.clear(clearTemporaryHighlight: true);
    });
    _loadComments();
    _loadBookData(
      initialSectionIndex: initialSectionIndex,
      targetQuestionNumber: targetQuestionNumber,
      targetItemIndex: targetItemIndex,
    );
  }

  void _jumpToSection(int idx) {
    setState(() {
      _currentSectionIndex = idx;
      _populateKeys(_bookData, idx);
      _selectionController.clear(clearTemporaryHighlight: true);
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(idx);
    }
    _saveReadingPosition(idx);
  }

  void _stepSection(int delta) {
    _clearSelection();
    if (_pageController.hasClients) {
      final future = delta < 0
          ? _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
          : _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
      future.ignore();
    } else {
      setState(() {
        _currentSectionIndex += delta;
        _populateKeys(_bookData, _currentSectionIndex);
      });
      _saveReadingPosition(_currentSectionIndex);
    }
  }

  void _onItemLongPress(int index) =>
      setState(() => _selectionController.onLongPress(index));

  void _onItemTap(int index) {
    if (_selectionController.hasSelection) {
      setState(() => _selectionController.onTap(index));
    }
  }

  void _clearSelection() =>
      setState(() => _selectionController.clear(clearTemporaryHighlight: true));

  Widget? _buildSelectionActionBar() {
    if (_bookData == null ||
        _currentSectionIndex < 0 ||
        _currentSectionIndex >= _bookData!.sections.length ||
        !_selectionController.hasSelection) {
      return null;
    }

    final section = _bookData!.sections[_currentSectionIndex];
    if (section.content.isEmpty) return null;

    final maxIndex = section.content.length - 1;
    final rawStart = _selectionController.start!.clamp(0, maxIndex);
    final rawEnd = _selectionController.end!.clamp(0, maxIndex);
    final start = rawStart <= rawEnd ? rawStart : rawEnd;
    final end = rawStart <= rawEnd ? rawEnd : rawStart;

    final (
      :citation,
      :textPreview,
    ) = LibraryReaderAdapter.formatSectionSelection(
      section: section,
      startIndex: start,
      endIndex: end,
      volumeTitle: _adapter.resolvedVolumeTitle,
    );
    final nodeId = ReaderNodeId.libraryItem(
      sectionId: section.id,
      itemIndex: start,
      volumeKey: _currentVolumeKey,
    );

    return buildLibraryReaderSelectionActionBar(
      context: context,
      adapter: _adapter,
      documentId: widget.bookItem.id,
      sectionIndex: _currentSectionIndex,
      nodeId: nodeId,
      citation: citation,
      textPreview: textPreview,
      selectedCount: end - start + 1,
      onClearSelection: _clearSelection,
      onCommentSaved: _loadComments,
      onFavoriteSaved: widget.onFavoriteSaved,
    );
  }

  void _openTocSheet(BuildContext context) {
    final book = _bookData;
    if (book == null) return;
    showLibraryReaderTocSheet(
      context: context,
      book: book,
      currentSectionIndex: _currentSectionIndex,
      onSectionSelected: _jumpToSection,
    );
  }

  void _openFontDialog(BuildContext context) {
    showLibraryReaderTextOptionsSheet(
      context: context,
      fontSize: _fontSize,
      onFontSizeChanged: (val) => setState(() => _fontSize = val),
    );
  }

  void _performSearch(String query) {
    if (_bookData == null) return;
    setState(() => _searchResults = _adapter.searchInBook(_bookData!, query));
  }

  void _closeSearch() {
    _pageController.dispose();
    _pageController = PageController(initialPage: _currentSectionIndex);
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _onSearchResultSelected(BookSearchResult res) {
    final secIdx =
        _bookData?.sections.indexWhere((s) => s.id == res.sectionId) ?? -1;
    if (secIdx < 0) return;

    _selectionController.clear(clearTemporaryHighlight: true);
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
    _saveReadingPosition(secIdx);
    if (res.itemIndex != null || res.questionNumber != null) {
      _highlightAndScrollTo(
        itemIndex: res.itemIndex,
        questionNumber: res.questionNumber,
        navigationSessionId: 'search_${DateTime.now().microsecondsSinceEpoch}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = _bookData;

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearching) _closeSearch();
      },
      child: Scaffold(
        appBar: buildLibraryReaderAppBar(
          theme: theme,
          bookTitle: widget.bookItem.title,
          book: book,
          isSearching: _isSearching,
          searchController: _searchController,
          onSearchChanged: (val) {
            setState(() => _searchQuery = val);
            _performSearch(val);
          },
          onClearSearch: () => setState(() {
            _searchController.clear();
            _searchQuery = '';
            _searchResults = [];
          }),
          onStartSearch: () => setState(() {
            _selectionController.clear(clearTemporaryHighlight: true);
            _isSearching = true;
          }),
          onCloseSearch: _closeSearch,
          onOpenToc: () => _openTocSheet(context),
          onOpenFontOptions: () => _openFontDialog(context),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (widget.bookItem.isSeries && !_isSearching)
                LibraryEditionSelectorBar(
                  volumes: widget.bookItem.volumes!,
                  selectedVolumeKey: _currentVolumeKey,
                  onVolumeSelected: _switchVolume,
                ),
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
                        onResultTap: _onSearchResultSelected,
                      )
                    : _buildSectionContentView(book!),
              ),
              if (!_isSearching && book != null && book.sections.isNotEmpty)
                ReaderSectionNavigationBar(
                  currentIndex: _currentSectionIndex,
                  totalSections: book.sections.length,
                  onPrevious: () => _stepSection(-1),
                  onNext: () => _stepSection(1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContentView(ParsedBookData book) {
    final sectionCommentsMap = LibraryReaderAdapter.groupCommentsForSection(
      _comments,
      _currentSectionIndex,
      currentVolumeKey: _currentVolumeKey,
      isSeries: widget.bookItem.isSeries,
    );

    return buildLibraryReaderSectionContentView(
      context: context,
      book: book,
      bookItem: widget.bookItem,
      pageController: _pageController,
      currentSectionIndex: _currentSectionIndex,
      fontSize: _fontSize,
      currentVolumeKey: _currentVolumeKey,
      sectionQuestionKeys: _sectionQuestionKeys,
      sectionItemKeys: _sectionItemKeys,
      sectionCommentsMap: sectionCommentsMap,
      selectedStartIndex: _selectionController.effectiveHighlightStart,
      selectedEndIndex: _selectionController.effectiveHighlightEnd,
      onPageChanged: (index) {
        setState(() {
          _currentSectionIndex = index;
          _populateKeys(_bookData, index);
          _selectionController.clear(clearTemporaryHighlight: true);
        });
        _saveReadingPosition(index);
      },
      onItemLongPress: _onItemLongPress,
      onItemTap: _onItemTap,
      onCommentsChanged: _loadComments,
      onSwitchVolume: (vol, idx, [targetQNum]) => _switchVolume(
        vol,
        initialSectionIndex: idx,
        targetQuestionNumber: targetQNum,
      ),
      selectionActionBar: _buildSelectionActionBar(),
    );
  }
}
