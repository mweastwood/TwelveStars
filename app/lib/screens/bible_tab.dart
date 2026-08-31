import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/bible_notes_screen.dart';
import 'package:twelve_stars/widgets/bible_chapter_view.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_card.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';
import 'package:twelve_stars/widgets/reader/bible_bottom_navigation_panel.dart';
import 'package:twelve_stars/widgets/reader/bible_ribbons_widget.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';

class BibleChapterRef {
  final BibleBook book;
  final int chapter;

  const BibleChapterRef({required this.book, required this.chapter});
}

class BibleTab extends StatefulWidget {
  final List<BibleVerse>? initialVerses;

  const BibleTab({super.key, this.initialVerses});

  @override
  BibleTabState createState() => BibleTabState();
}

class BibleTabState extends State<BibleTab> with TickerProviderStateMixin {
  late List<BibleChapterRef> _allChapters;
  late PageController _pageController;
  int _currentPageIndex = 0;

  // Bottom Peeking Panel Animation
  late AnimationController _panelController;
  late Animation<double> _panelHeightAnimation;
  bool _isPanelExpanded = false;

  // Selected book for the chapter picker grid
  late BibleBook _selectedBookForPicker;

  // TabController inside bottom sheet
  late TabController _sheetTabController;

  List<FavoritePassage> _favorites = [];
  bool _loadingFavorites = true;

  List<UserComment> _comments = [];
  bool _loadingComments = true;

  UserSettings? _settings;
  String _primaryTranslation = 'CPDV';
  String _compareTranslation = 'none';
  bool _isSelectingVerses = false;
  bool _showTranslationSelectors = false;

  bool get showTranslationSelectors => _showTranslationSelectors;
  late final AnimationController _translationSelectorAnimationController;
  late final CurvedAnimation _translationSelectorAnimation;

  static const double _kTranslationSelectorTopSpacerHeight = 72.0;
  static const int _maxCachedControllers = 10;
  final Map<int, ScrollController> _chapterScrollControllers = {};
  double _initialScrollOffset = 0.0;
  bool _wasScrolledDown = false;

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
      final evictKey = _chapterScrollControllers.keys.firstWhere(
        (k) => k != _currentPageIndex,
        orElse: () => _chapterScrollControllers.keys.first,
      );
      final evictController = _chapterScrollControllers.remove(evictKey);
      evictController?.dispose();
    }
    final newController = ScrollController();
    _chapterScrollControllers[index] = newController;
    return newController;
  }

  ScrollController? get _currentChapterScrollController {
    return _chapterScrollControllers[_currentPageIndex];
  }

  void _onTranslationSelectorAnimationTick() {
    final controller = _currentChapterScrollController;
    if (!_wasScrolledDown || controller == null || !controller.hasClients) {
      return;
    }

    final targetOffset =
        _initialScrollOffset +
        (_kTranslationSelectorTopSpacerHeight *
            _translationSelectorAnimation.value);
    final maxExtent =
        controller.position.maxScrollExtent +
        _kTranslationSelectorTopSpacerHeight;
    controller.jumpTo(targetOffset.clamp(0.0, maxExtent));
  }

  // Navigation target for favorite scrolling/highlighting
  int? _targetBookNumber;
  int? _targetChapter;
  int? _scrollToVerse;
  int? _highlightStartVerse;
  int? _highlightEndVerse;
  String? _navigationSessionId;

  @override
  void dispose() {
    _translationSelectorAnimationController.removeListener(
      _onTranslationSelectorAnimationTick,
    );
    for (final controller in _chapterScrollControllers.values) {
      controller.dispose();
    }
    _translationSelectorAnimationController.dispose();
    _panelController.dispose();
    _pageController.dispose();
    _sheetTabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _translationSelectorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _showTranslationSelectors ? 1.0 : 0.0,
    );
    _translationSelectorAnimationController.addListener(
      _onTranslationSelectorAnimationTick,
    );
    _translationSelectorAnimation = CurvedAnimation(
      parent: _translationSelectorAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    // Build flat list of all chapters in order
    _allChapters = [];
    for (final book in catholicBooks) {
      for (int c = 1; c <= book.chaptersCount; c++) {
        _allChapters.add(BibleChapterRef(book: book, chapter: c));
      }
    }

    _pageController = PageController(initialPage: 0);
    _selectedBookForPicker = catholicBooks.first;

    // Panel controller
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _panelHeightAnimation =
        Tween<double>(
          begin: 72.0, // collapsed peeking height
          end: 500.0, // expanded picker height
        ).animate(
          CurvedAnimation(
            parent: _panelController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _sheetTabController = TabController(length: 4, vsync: this);
    _loadFavorites();
    _loadComments();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await PrayerDatabase.loadSettings();
      if (mounted) {
        final targetIndex = _allChapters.indexWhere(
          (ref) =>
              ref.book.bookNumber == settings.lastBibleBookNumber &&
              ref.chapter == settings.lastBibleChapter,
        );
        final initialIndex = targetIndex != -1 ? targetIndex : 0;
        if (_currentPageIndex != initialIndex) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(initialIndex);
          } else {
            _pageController.dispose();
            _pageController = PageController(initialPage: initialIndex);
          }
          _currentPageIndex = initialIndex;
          _selectedBookForPicker = _allChapters[initialIndex].book;
        }

        setState(() {
          _settings = settings;
          _primaryTranslation = settings.primaryBibleTranslation;
          _compareTranslation = settings.compareBibleTranslation;
          _showTranslationSelectors = settings.showBibleTranslationSelectors;
          _translationSelectorAnimationController.value =
              _showTranslationSelectors ? 1.0 : 0.0;
        });
      }
    } catch (_) {}
  }

  void _saveReadingPosition(int index) {
    if (index >= 0 && index < _allChapters.length) {
      final ref = _allChapters[index];
      if (_settings != null) {
        _settings!.lastBibleBookNumber = ref.book.bookNumber;
        _settings!.lastBibleChapter = ref.chapter;
        PrayerDatabase.saveSettings(_settings!);
      } else {
        PrayerDatabase.loadSettings().then((s) {
          _settings = s;
          s.lastBibleBookNumber = ref.book.bookNumber;
          s.lastBibleChapter = ref.chapter;
          PrayerDatabase.saveSettings(s);
        });
      }
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _loadingFavorites = true);
    try {
      final favs = await BibleDatabaseHelper.db.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favs;
          _loadingFavorites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingFavorites = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final comments = await BibleDatabaseHelper.db.getComments();
      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingComments = false;
        });
      }
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
    if (_isPanelExpanded) {
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
    return SizeTransition(
      sizeFactor: _translationSelectorAnimation,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _translationSelectorAnimation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
          child: BibleTranslationSelectorCard(
            primaryCode: _primaryTranslation,
            compareCode: _compareTranslation == 'none'
                ? null
                : _compareTranslation,
            onOpenSelector: (target) => _showTranslationSelectorDialog(target),
            onSwap: () {
              if (_compareTranslation != 'none') {
                setState(() {
                  final oldPrimary = _primaryTranslation;
                  _primaryTranslation = _compareTranslation;
                  _compareTranslation = oldPrimary;
                  _settings?.primaryBibleTranslation = _primaryTranslation;
                  _settings?.compareBibleTranslation = _compareTranslation;
                });
                if (_settings != null) {
                  PrayerDatabase.saveSettings(_settings!);
                }
              }
            },
            onClearCompare: () {
              setState(() {
                _compareTranslation = 'none';
                _settings?.compareBibleTranslation = 'none';
              });
              if (_settings != null) {
                PrayerDatabase.saveSettings(_settings!);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showTranslationSelectorDialog(
    BibleTranslationTarget target,
  ) async {
    await BibleTranslationSelectorDialog.show(
      context,
      currentPrimaryCode: _primaryTranslation,
      currentCompareCode: _compareTranslation == 'none'
          ? null
          : _compareTranslation,
      initialTarget: target,
      onPrimarySelected: (newPrimary) async {
        setState(() {
          _primaryTranslation = newPrimary;
          if (_compareTranslation == newPrimary) {
            _compareTranslation = 'none';
          }
          _settings?.primaryBibleTranslation = _primaryTranslation;
          _settings?.compareBibleTranslation = _compareTranslation;
        });
        if (_settings != null) {
          await PrayerDatabase.saveSettings(_settings!);
        }
      },
      onCompareSelected: (newCompare) async {
        setState(() {
          _compareTranslation = newCompare ?? 'none';
          if (_primaryTranslation == newCompare) {
            final options = ['CPDV', 'DRC', 'JUN', 'TAM', 'VUL', 'LXX', 'ORIG'];
            _primaryTranslation = options.firstWhere((o) => o != newCompare);
          }
          _settings?.primaryBibleTranslation = _primaryTranslation;
          _settings?.compareBibleTranslation = _compareTranslation;
        });
        if (_settings != null) {
          await PrayerDatabase.saveSettings(_settings!);
        }
      },
    );
  }

  void toggleTranslationSelectors() {
    final controller = _currentChapterScrollController;
    final offset = controller != null && controller.hasClients
        ? controller.offset
        : 0.0;
    _wasScrolledDown = offset > 5.0;
    _initialScrollOffset =
        offset -
        (_kTranslationSelectorTopSpacerHeight *
            _translationSelectorAnimation.value);

    setState(() {
      _showTranslationSelectors = !_showTranslationSelectors;
      if (_showTranslationSelectors) {
        _translationSelectorAnimationController.forward();
      } else {
        _translationSelectorAnimationController.reverse();
      }
      _settings?.showBibleTranslationSelectors = _showTranslationSelectors;
    });
    if (_settings != null) {
      PrayerDatabase.saveSettings(_settings!);
    }
  }

  @visibleForTesting
  void navigateToChapter(BibleBook book, int chapterNum) =>
      _navigateToChapter(book, chapterNum);

  void _navigateToChapter(BibleBook book, int chapterNum) {
    final pageIndex = _allChapters.indexWhere(
      (ref) =>
          ref.book.bookNumber == book.bookNumber && ref.chapter == chapterNum,
    );
    if (pageIndex != -1) {
      _pageController.jumpToPage(pageIndex);
      _collapsePanel();
      _saveReadingPosition(pageIndex);
    }
  }

  void navigateToFavorite(FavoritePassage fav) {
    final pageIndex = _allChapters.indexWhere(
      (ref) =>
          ref.book.bookNumber == fav.bookNumber && ref.chapter == fav.chapter,
    );
    if (pageIndex != -1) {
      setState(() {
        _targetBookNumber = fav.bookNumber;
        _targetChapter = fav.chapter;
        _scrollToVerse = fav.startVerse;
        _highlightStartVerse = fav.startVerse;
        _highlightEndVerse = fav.endVerse;
        _navigationSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      });
      _pageController.jumpToPage(pageIndex);
      _collapsePanel();
      _saveReadingPosition(pageIndex);
    }
  }

  void navigateToComment(UserComment comment) {
    final verseNum = int.tryParse(comment.nodeId.split('_').last) ?? 1;
    final book = catholicBooks.firstWhere(
      (b) => b.abbrev == comment.documentId,
      orElse: () => catholicBooks.first,
    );
    final pageIndex = _allChapters.indexWhere(
      (ref) =>
          ref.book.bookNumber == book.bookNumber &&
          ref.chapter == comment.sectionIndex,
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
      _pageController.jumpToPage(pageIndex);
      _collapsePanel();
      _saveReadingPosition(pageIndex);
    }
  }

  void _openNotesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleNotesScreen(
          onSelectFavorite: (fav) {
            Navigator.pop(context);
            navigateToFavorite(fav);
          },
          onSelectComment: (comment) {
            Navigator.pop(context);
            navigateToComment(comment);
          },
          onFavoritesOrCommentsChanged: () {
            _loadFavorites();
            _loadComments();
          },
        ),
      ),
    ).then((_) {
      _loadFavorites();
      _loadComments();
    });
  }

  void _onRibbonTap(int index, BibleRibbonBookmark? bookmark) {
    if (bookmark != null) {
      final book = catholicBooks.firstWhere(
        (b) => b.bookNumber == bookmark.bookNumber,
        orElse: () => catholicBooks.first,
      );
      _navigateToChapter(book, bookmark.chapter);
      setState(() {
        _selectedBookForPicker = book;
      });
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

    var settings = _settings;
    if (settings == null) {
      settings = await PrayerDatabase.loadSettings();
      _settings = settings;
    }

    final updatedRibbons = List<BibleRibbonBookmark>.from(
      settings.bibleRibbons ?? [],
    );
    updatedRibbons.removeWhere((b) => b.ribbonIndex == index);
    updatedRibbons.removeWhere(
      (b) =>
          b.bookNumber == currentRef.book.bookNumber &&
          b.chapter == currentRef.chapter,
    );
    updatedRibbons.add(newBookmark);
    updatedRibbons.sort((a, b) => a.ribbonIndex.compareTo(b.ribbonIndex));
    settings.bibleRibbons = updatedRibbons;

    setState(() {
      _settings = settings;
    });

    await PrayerDatabase.saveSettings(settings);
    await UserSettingsController.instance.update(settings);
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
                    Expanded(
                      child: Text(
                        verse.verseText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
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

    final currentRef = _allChapters[_currentPageIndex];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Main PageView containing the chapters
          PageView.builder(
            controller: _pageController,
            itemCount: _allChapters.length,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
                _selectedBookForPicker = _allChapters[index].book;
              });
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
                numberingSystem:
                    _settings?.bibleNumberingSystem ??
                    BibleNumberingSystem.vulgate,
                translationSelectorAnimation: _translationSelectorAnimation,
                scrollController: _getScrollController(index),
                scrollToVerse: isTarget ? _scrollToVerse : null,
                highlightStartVerse: isTarget ? _highlightStartVerse : null,
                highlightEndVerse: isTarget ? _highlightEndVerse : null,
                navigationSessionId: isTarget ? _navigationSessionId : null,
                onFavoriteSaved: _loadFavorites,
                bookmarks: _settings?.bibleRibbons,
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
            right: 16,
            child: BibleRibbonsWidget(
              bookmarks: _settings?.bibleRibbons,
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
            child: BibleBottomNavigationPanel(
              panelHeightAnimation: _panelHeightAnimation,
              isPanelExpanded: _isPanelExpanded,
              currentBook: currentRef.book,
              currentChapter: currentRef.chapter,
              numberingSystem:
                  _settings?.bibleNumberingSystem ??
                  BibleNumberingSystem.vulgate,
              sheetTabController: _sheetTabController,
              selectedBookForPicker: _selectedBookForPicker,
              onBookSelectedForPicker: (book) {
                setState(() {
                  _selectedBookForPicker = book;
                });
              },
              onChapterSelected: _navigateToChapter,
              favorites: _favorites,
              loadingFavorites: _loadingFavorites,
              onFavoriteTapped: navigateToFavorite,
              onDeleteFavorite: (fav) async {
                await BibleDatabaseHelper.db.deleteFavorite(fav.id);
                _loadFavorites();
              },
              comments: _comments,
              loadingComments: _loadingComments,
              onCommentTapped: navigateToComment,
              onEditComment: (comment) async {
                final verseNum =
                    int.tryParse(comment.nodeId.split('_').last) ?? 1;
                final book = catholicBooks.firstWhere(
                  (b) => b.abbrev == comment.documentId,
                  orElse: () => catholicBooks.first,
                );
                final citation =
                    '${book.bookName} ${comment.sectionIndex}:$verseNum';

                await showEditCommentDialog(
                  context: context,
                  citation: citation,
                  textPreview: comment.textPreview ?? '',
                  commentId: comment.id,
                  initialText: comment.commentText,
                  onCommentUpdated: (_) async {
                    await _loadComments();
                  },
                );
              },
              onDeleteComment: (comment) async {
                await BibleDatabaseHelper.db.deleteComment(comment.id);
                await _loadComments();
              },
              onTogglePanel: _togglePanel,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
            ),
          ),
        ],
      ),
    );
  }
}
