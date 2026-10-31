import 'dart:async';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/bible_notes_screen.dart';
import 'package:twelve_stars/widgets/bible_chapter_view.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_card.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';
import 'package:twelve_stars/widgets/collapsible_selector_bar.dart';
import 'package:twelve_stars/widgets/reader/bible_bottom_navigation_panel.dart';
import 'package:twelve_stars/widgets/reader/bible_ribbons_widget.dart';

class BibleChapterRef {
  final BibleBook book;
  final int chapter;

  const BibleChapterRef({required this.book, required this.chapter});
}

/// Static canonical list of all 1,334 Catholic Bible chapters across 73 books.
final List<BibleChapterRef> canonicalBibleChapters = List.unmodifiable([
  for (final book in catholicBooks)
    for (int c = 1; c <= book.chaptersCount; c++)
      BibleChapterRef(book: book, chapter: c),
]);

final Map<String, int> _canonicalChapterIndexMap = Map.unmodifiable({
  for (int i = 0; i < canonicalBibleChapters.length; i++)
    '${canonicalBibleChapters[i].book.bookNumber}:${canonicalBibleChapters[i].chapter}':
        i,
});

/// Returns the 0-based canonical page index for the given [bookNumber] and [chapterNum],
/// or -1 if the chapter does not exist in the Catholic canon.
int getCanonicalChapterIndex(int bookNumber, int chapterNum) =>
    _canonicalChapterIndexMap['$bookNumber:$chapterNum'] ?? -1;

class BibleTab extends StatefulWidget {
  final List<BibleVerse>? initialVerses;
  final double fontSize;

  const BibleTab({super.key, this.initialVerses, this.fontSize = 16.0});

  @override
  BibleTabState createState() => BibleTabState();
}

class BibleTabState extends State<BibleTab> with TickerProviderStateMixin {
  List<BibleChapterRef> get _allChapters => canonicalBibleChapters;
  late PageController _pageController;
  int _currentPageIndex = 0;
  late final ValueNotifier<int> _currentPageIndexNotifier;

  // Bottom Peeking Panel Animation
  late AnimationController _panelController;
  late Animation<double> _panelHeightAnimation;
  bool _isPanelExpanded = false;

  // Selected book for the chapter picker grid
  late BibleBook _selectedBookForPicker;
  late final ValueNotifier<BibleBook> _selectedBookForPickerNotifier;

  @visibleForTesting
  BibleBook get selectedBookForPicker => _selectedBookForPicker;

  // TabController inside bottom sheet
  late TabController _sheetTabController;

  UserSettings? _settings;
  String _primaryTranslation = 'CPDV';
  String _compareTranslation = 'none';
  BibleNumberingSystem _numberingSystem = BibleNumberingSystem.vulgate;
  List<BibleRibbonBookmark>? _bibleRibbons;
  bool _isSelectingVerses = false;
  bool _showTranslationSelectors = false;

  bool get showTranslationSelectors => _showTranslationSelectors;
  late final CollapsibleSelectorController _translationSelectorController;
  late final CurvedAnimation _panelHeightCurvedAnimation;

  static const double _kTranslationSelectorTopSpacerHeight = 72.0;
  static const int _maxCachedControllers = 10;
  final Map<int, ScrollController> _chapterScrollControllers = {};

  @visibleForTesting
  Map<int, ScrollController> get chapterScrollControllers =>
      _chapterScrollControllers;

  ScrollController _getScrollController(int index) {
    if (_chapterScrollControllers.containsKey(index)) {
      final controller = _chapterScrollControllers.remove(index)!;
      _chapterScrollControllers[index] = controller;
      return controller;
    }
    if (_chapterScrollControllers.length >= _maxCachedControllers) {
      final evictKeys = _chapterScrollControllers.entries
          .where((e) => e.key != _currentPageIndex && !e.value.hasClients)
          .map((e) => e.key)
          .take(_chapterScrollControllers.length - _maxCachedControllers + 1)
          .toList();
      for (final key in evictKeys) {
        _chapterScrollControllers.remove(key)?.dispose();
      }
    }
    final newController = ScrollController();
    _chapterScrollControllers[index] = newController;
    return newController;
  }

  ScrollController? get _currentChapterScrollController {
    return _chapterScrollControllers[_currentPageIndex];
  }

  // Navigation target for favorite scrolling/highlighting
  int? _targetBookNumber;
  int? _targetChapter;
  int? _scrollToVerse;
  int? _highlightStartVerse;
  int? _highlightEndVerse;
  String? _navigationSessionId;
  bool _hasExplicitNavigation = false;

  @override
  void dispose() {
    UserSettingsController.instance.removeListener(_onSettingsChanged);
    _translationSelectorController.dispose();
    for (final controller in _chapterScrollControllers.values) {
      controller.dispose();
    }
    _currentPageIndexNotifier.dispose();
    _selectedBookForPickerNotifier.dispose();
    _panelHeightCurvedAnimation.dispose();
    _panelController.dispose();
    _pageController.dispose();
    _sheetTabController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final settings = UserSettingsController.instance.value;
    final showSelectorsChanged =
        _showTranslationSelectors != settings.showBibleTranslationSelectors;
    final translationChanged =
        _primaryTranslation != settings.primaryBibleTranslation ||
        _compareTranslation != settings.compareBibleTranslation;
    final numberingChanged = _numberingSystem != settings.bibleNumberingSystem;
    final ribbonsChanged = !listEquals(_bibleRibbons, settings.bibleRibbons);
    _settings = settings;
    if (showSelectorsChanged ||
        translationChanged ||
        numberingChanged ||
        ribbonsChanged) {
      setState(() {
        _primaryTranslation = settings.primaryBibleTranslation;
        _compareTranslation = settings.compareBibleTranslation;
        _numberingSystem = settings.bibleNumberingSystem;
        _bibleRibbons = settings.bibleRibbons != null
            ? List<BibleRibbonBookmark>.from(settings.bibleRibbons!)
            : null;
        if (showSelectorsChanged) {
          _showTranslationSelectors = settings.showBibleTranslationSelectors;
          _translationSelectorController.syncExpanded(
            _showTranslationSelectors,
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPageIndexNotifier = ValueNotifier<int>(_currentPageIndex);
    _selectedBookForPicker = catholicBooks.first;
    _selectedBookForPickerNotifier = ValueNotifier<BibleBook>(
      _selectedBookForPicker,
    );
    _translationSelectorController = CollapsibleSelectorController(
      vsync: this,
      topSpacerHeight: _kTranslationSelectorTopSpacerHeight,
      activeScrollController: () => _currentChapterScrollController,
      initiallyExpanded: _showTranslationSelectors,
    );

    _pageController = PageController(initialPage: 0);

    // Panel controller
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _panelHeightCurvedAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOutCubic,
    );

    _panelHeightAnimation = Tween<double>(
      begin: 72.0, // collapsed peeking height
      end: 500.0, // expanded picker height
    ).animate(_panelHeightCurvedAnimation);

    _sheetTabController = TabController(length: 2, vsync: this);
    UserSettingsController.instance.addListener(_onSettingsChanged);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await UserSettingsController.instance.load();
      if (mounted) {
        final targetIndex = getCanonicalChapterIndex(
          settings.lastBibleBookNumber,
          settings.lastBibleChapter,
        );
        final initialIndex = targetIndex != -1 ? targetIndex : 0;
        if (!_hasExplicitNavigation &&
            _targetBookNumber == null &&
            _currentPageIndex != initialIndex) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(initialIndex);
          } else {
            _pageController.dispose();
            _pageController = PageController(initialPage: initialIndex);
          }
          _currentPageIndex = initialIndex;
          _selectedBookForPicker = _allChapters[initialIndex].book;
          _selectedBookForPickerNotifier.value = _selectedBookForPicker;
          _currentPageIndexNotifier.value = initialIndex;
        }

        setState(() {
          _settings = settings;
          _primaryTranslation = settings.primaryBibleTranslation;
          _compareTranslation = settings.compareBibleTranslation;
          _numberingSystem = settings.bibleNumberingSystem;
          _bibleRibbons = settings.bibleRibbons != null
              ? List<BibleRibbonBookmark>.from(settings.bibleRibbons!)
              : null;
          _showTranslationSelectors = settings.showBibleTranslationSelectors;
          _translationSelectorController.syncExpanded(
            _showTranslationSelectors,
          );
        });
      }
    } catch (_) {}
  }

  void _saveReadingPosition(int index) {
    if (index >= 0 && index < _allChapters.length) {
      final ref = _allChapters[index];
      _settings?.lastBibleBookNumber = ref.book.bookNumber;
      _settings?.lastBibleChapter = ref.chapter;
      UserSettingsController.instance.mutate((s) {
        s.lastBibleBookNumber = ref.book.bookNumber;
        s.lastBibleChapter = ref.chapter;
      });
    }
  }

  void _togglePanel() {
    setState(() {
      _isPanelExpanded = !_isPanelExpanded;
      if (_isPanelExpanded) {
        _panelController.forward();
      } else {
        _panelController.reverse();
      }
    });
  }

  void _collapsePanel() {
    if (_isPanelExpanded || _panelController.value > 0.0) {
      setState(() {
        _isPanelExpanded = false;
        _panelController.reverse();
      });
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _panelController.value -= details.primaryDelta! / (500.0 - 72.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0.0;
    if (velocity < -100.0) {
      _panelController.animateTo(1.0, curve: Curves.easeOutCubic);
      setState(() => _isPanelExpanded = true);
    } else if (velocity > 100.0) {
      _panelController.animateTo(0.0, curve: Curves.easeOutCubic);
      setState(() => _isPanelExpanded = false);
    } else {
      if (_panelController.value > 0.5) {
        _panelController.animateTo(1.0, curve: Curves.easeOutCubic);
        setState(() => _isPanelExpanded = true);
      } else {
        _panelController.animateTo(0.0, curve: Curves.easeOutCubic);
        setState(() => _isPanelExpanded = false);
      }
    }
  }

  Widget _buildTranslationSelectors(ThemeData theme) {
    return CollapsibleSelectorBar(
      animation: _translationSelectorController.animation,
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
      child: BibleTranslationSelectorCard(
        primaryCode: _primaryTranslation,
        compareCode: _compareTranslation == 'none' ? null : _compareTranslation,
        onOpenSelector: (target) => _showTranslationSelectorDialog(target),
        onSwap: () {
          if (_compareTranslation != 'none') {
            final nextPrimary = _compareTranslation;
            final nextCompare = _primaryTranslation;
            setState(() {
              _primaryTranslation = nextPrimary;
              _compareTranslation = nextCompare;
            });
            UserSettingsController.instance.mutate((s) {
              s.primaryBibleTranslation = nextPrimary;
              s.compareBibleTranslation = nextCompare;
            });
          }
        },
        onClearCompare: () {
          setState(() {
            _compareTranslation = 'none';
          });
          UserSettingsController.instance.mutate((s) {
            s.compareBibleTranslation = 'none';
          });
        },
      ),
    );
  }

  Future<void> _showTranslationSelectorDialog(
    BibleTranslationTarget target,
  ) async {
    final currentBookNumber =
        _allChapters.isNotEmpty && _currentPageIndex < _allChapters.length
        ? _allChapters[_currentPageIndex].book.bookNumber
        : null;
    await BibleTranslationSelectorDialog.show(
      context,
      currentPrimaryCode: _primaryTranslation,
      currentCompareCode: _compareTranslation == 'none'
          ? null
          : _compareTranslation,
      initialTarget: target,
      currentBookNumber: currentBookNumber,
      onPrimarySelected: (newPrimary) async {
        final nextCompare = _compareTranslation == newPrimary
            ? 'none'
            : _compareTranslation;
        setState(() {
          _primaryTranslation = newPrimary;
          _compareTranslation = nextCompare;
        });
        await UserSettingsController.instance.mutate((s) {
          s.primaryBibleTranslation = newPrimary;
          s.compareBibleTranslation = nextCompare;
        });
      },
      onCompareSelected: (newCompare) async {
        final nextCompare = newCompare ?? 'none';
        var nextPrimary = _primaryTranslation;
        if (_primaryTranslation == newCompare) {
          final options = BibleTranslationInfo.allTranslations
              .map((t) => t.code)
              .toList();
          nextPrimary = options.firstWhere((o) => o != newCompare);
        }
        setState(() {
          _primaryTranslation = nextPrimary;
          _compareTranslation = nextCompare;
        });
        await UserSettingsController.instance.mutate((s) {
          s.primaryBibleTranslation = nextPrimary;
          s.compareBibleTranslation = nextCompare;
        });
      },
    );
  }

  void toggleTranslationSelectors() {
    final nextShow = _translationSelectorController.toggle();
    setState(() {
      _showTranslationSelectors = nextShow;
    });
    UserSettingsController.instance.mutate((s) {
      s.showBibleTranslationSelectors = nextShow;
    });
  }

  void _jumpToPageAndSync(int pageIndex) {
    _hasExplicitNavigation = true;
    final book = _allChapters[pageIndex].book;
    _selectedBookForPicker = book;
    _selectedBookForPickerNotifier.value = book;
    final previousPageIndex = _currentPageIndex;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(pageIndex);
    } else {
      _pageController.dispose();
      _pageController = PageController(initialPage: pageIndex);
    }
    if (_currentPageIndex == previousPageIndex) {
      _currentPageIndex = pageIndex;
      _currentPageIndexNotifier.value = pageIndex;
      _saveReadingPosition(pageIndex);
    }
  }

  @visibleForTesting
  void navigateToChapter(BibleBook book, int chapterNum) =>
      _navigateToChapter(book, chapterNum);

  void _navigateToChapter(BibleBook book, int chapterNum) {
    final pageIndex = getCanonicalChapterIndex(book.bookNumber, chapterNum);
    if (pageIndex != -1) {
      _jumpToPageAndSync(pageIndex);
      _collapsePanel();
    }
  }

  void navigateToFavorite(FavoritePassage fav) {
    final pageIndex = getCanonicalChapterIndex(fav.bookNumber, fav.chapter);
    if (pageIndex != -1) {
      setState(() {
        _targetBookNumber = fav.bookNumber;
        _targetChapter = fav.chapter;
        _scrollToVerse = fav.startVerse;
        _highlightStartVerse = fav.startVerse;
        _highlightEndVerse = fav.endVerse;
        _navigationSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      });
      _jumpToPageAndSync(pageIndex);
      _collapsePanel();
    }
  }

  void navigateToComment(UserComment comment) {
    final verseNum = ReaderNodeId.parseBibleVerseNumber(comment.nodeId);
    final book =
        catholicBooksByAbbrev[comment.documentId.toUpperCase()] ??
        catholicBooks.first;
    final pageIndex = getCanonicalChapterIndex(
      book.bookNumber,
      comment.sectionIndex,
    );
    if (pageIndex != -1) {
      setState(() {
        _targetBookNumber = book.bookNumber;
        _targetChapter = comment.sectionIndex;
        _scrollToVerse = verseNum;
        _highlightStartVerse = verseNum;
        _highlightEndVerse = verseNum;
        _navigationSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      });
      _jumpToPageAndSync(pageIndex);
      _collapsePanel();
    }
  }

  void _openNotesScreen() {
    final currentRef =
        _allChapters.isNotEmpty && _currentPageIndex < _allChapters.length
        ? _allChapters[_currentPageIndex]
        : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleNotesScreen(
          currentBook: currentRef?.book,
          currentChapter: currentRef?.chapter,
          onSelectFavorite: (fav) {
            Navigator.pop(context);
            navigateToFavorite(fav);
          },
          onSelectComment: (comment) {
            Navigator.pop(context);
            navigateToComment(comment);
          },
        ),
      ),
    );
  }

  void _onRibbonTap(int index, BibleRibbonBookmark? bookmark) {
    if (bookmark != null) {
      final book =
          catholicBooksByNumber[bookmark.bookNumber] ?? catholicBooks.first;
      _navigateToChapter(book, bookmark.chapter);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Long press this ribbon to bookmark the current chapter',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onRibbonLongPress(int index) async {
    final currentRef = _allChapters[_currentPageIndex];
    if (_settings?.hapticsEnabled ?? true) {
      HapticFeedback.mediumImpact();
    }
    final newBookmark = BibleRibbonBookmark(
      ribbonIndex: index,
      bookNumber: currentRef.book.bookNumber,
      chapter: currentRef.chapter,
    );

    await UserSettingsController.instance.mutate((s) {
      final updatedRibbons = List<BibleRibbonBookmark>.from(
        s.bibleRibbons ?? [],
      );
      updatedRibbons.removeWhere((b) => b.ribbonIndex == index);
      updatedRibbons.removeWhere(
        (b) =>
            b.bookNumber == currentRef.book.bookNumber &&
            b.chapter == currentRef.chapter,
      );
      updatedRibbons.add(newBookmark);
      updatedRibbons.sort((a, b) => a.ribbonIndex.compareTo(b.ribbonIndex));
      s.bibleRibbons = updatedRibbons;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If initialVerses is provided (e.g. for testing), render a static scrollable view
    if (widget.initialVerses != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genesis 1',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catholic Public Domain Version (CPDV)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.outline,
              ),
            ),
            const Divider(height: 24),
            ...widget.initialVerses!.map((verse) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${verse.verseNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        verse.verseText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: widget.fontSize == 16.0
                              ? null
                              : widget.fontSize,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Main PageView containing the chapters
          PageView.builder(
            controller: _pageController,
            itemCount: _allChapters.length,
            onPageChanged: (index) {
              final book = _allChapters[index].book;
              _currentPageIndex = index;
              _selectedBookForPicker = book;
              _selectedBookForPickerNotifier.value = book;
              _currentPageIndexNotifier.value = index;
              _saveReadingPosition(index);
            },
            itemBuilder: (context, index) {
              final ref = _allChapters[index];
              final isTarget =
                  _targetBookNumber == ref.book.bookNumber &&
                  _targetChapter == ref.chapter;
              return BibleChapterView(
                book: ref.book,
                chapter: ref.chapter,
                primaryTranslation: _primaryTranslation,
                compareTranslation: _compareTranslation,
                numberingSystem: _numberingSystem,
                fontSize: widget.fontSize,
                translationSelectorAnimation:
                    _translationSelectorController.animation,
                scrollController: _getScrollController(index),
                scrollToVerse: isTarget ? _scrollToVerse : null,
                highlightStartVerse: isTarget ? _highlightStartVerse : null,
                highlightEndVerse: isTarget ? _highlightEndVerse : null,
                navigationSessionId: isTarget ? _navigationSessionId : null,
                bookmarks: _bibleRibbons,
                onSelectionChanged: (isSelecting) {
                  if (_isSelectingVerses != isSelecting) {
                    setState(() => _isSelectingVerses = isSelecting);
                  }
                },
              );
            },
          ),

          // 2. Ribbons Bookmark Overlay
          Positioned(
            top: 0,
            right: 0,
            child: BibleRibbonsWidget(
              bookmarks: _bibleRibbons,
              onRibbonTap: _onRibbonTap,
              onRibbonLongPress: _onRibbonLongPress,
            ),
          ),

          // 3. Floating Translation Selector
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTranslationSelectors(theme),
          ),

          // 3. Backdrop Barrier to collapse sheet on tap
          if (_isPanelExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _collapsePanel,
                child: Container(color: Colors.black26),
              ),
            ),

          // 4. Notes FAB (floats above collapsed bottom sheet when not selecting verses)
          if (!_isPanelExpanded && !_isSelectingVerses)
            Positioned(
              right: 16,
              bottom: 88, // float 16px above collapsed bottom sheet (72px)
              child: FloatingActionButton.extended(
                key: const Key('bible_notes_fab'),
                onPressed: _openNotesScreen,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Notes'),
              ),
            ),

          // 5. Persistent Peeking Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _currentPageIndexNotifier,
                _selectedBookForPickerNotifier,
              ]),
              builder: (context, _) {
                final currentRef =
                    _allChapters[_currentPageIndexNotifier.value];
                return BibleBottomNavigationPanel(
                  panelHeightAnimation: _panelHeightAnimation,
                  isPanelExpanded: _isPanelExpanded,
                  currentBook: currentRef.book,
                  currentChapter: currentRef.chapter,
                  numberingSystem: _numberingSystem,
                  sheetTabController: _sheetTabController,
                  selectedBookForPicker: _selectedBookForPickerNotifier.value,
                  onBookSelectedForPicker: (book) {
                    _selectedBookForPicker = book;
                    _selectedBookForPickerNotifier.value = book;
                  },
                  onChapterSelected: _navigateToChapter,
                  onTogglePanel: _togglePanel,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
