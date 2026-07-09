import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';

class BibleChapterRef {
  final BibleBook book;
  final int chapter;

  const BibleChapterRef({required this.book, required this.chapter});
}

class BibleTab extends StatefulWidget {
  final List<BibleVerse>? initialVerses;

  const BibleTab({super.key, this.initialVerses});

  @override
  State<BibleTab> createState() => _BibleTabState();
}

class _BibleTabState extends State<BibleTab> with TickerProviderStateMixin {
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

  UserSettings? _settings;
  String _primaryTranslation = 'CPDV';
  String _compareTranslation = 'none';

  // Navigation target for favorite scrolling/highlighting
  int? _targetBookNumber;
  int? _targetChapter;
  int? _scrollToVerse;
  int? _highlightStartVerse;
  int? _highlightEndVerse;
  String? _navigationSessionId;

  @override
  void initState() {
    super.initState();
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

    _sheetTabController = TabController(length: 3, vsync: this);
    _loadFavorites();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await PrayerDatabase.loadSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _primaryTranslation = settings.primaryBibleTranslation;
          _compareTranslation = settings.compareBibleTranslation;
        });
      }
    } catch (_) {}
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

  @override
  void dispose() {
    _pageController.dispose();
    _panelController.dispose();
    _sheetTabController.dispose();
    super.dispose();
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

  Widget _buildBookGroup(String title, List<BibleBook> books) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: books.map((book) {
              final isSelected =
                  _selectedBookForPicker.bookNumber == book.bookNumber;
              return ChoiceChip(
                label: Text(book.bookName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedBookForPicker = book;
                  });
                  _sheetTabController.animateTo(1); // Switch to Chapter tab
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSelectors(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () => _showPrimaryDialog(theme),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.translate,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primary Translation',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              _primaryTranslation,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () => _showCompareDialog(theme),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.compare_arrows,
                        color: theme.colorScheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comparison Translation',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            Text(
                              _compareTranslation == 'none'
                                  ? 'None'
                                  : _compareTranslation,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrimaryDialog(ThemeData theme) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _BibleTranslationDialog(
        mode: _TranslationDialogMode.primary,
        currentPrimary: _primaryTranslation,
        currentCompare: _compareTranslation,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _primaryTranslation = result;
        if (_compareTranslation == result) {
          _compareTranslation = 'none';
        }
        _settings?.primaryBibleTranslation = _primaryTranslation;
        _settings?.compareBibleTranslation = _compareTranslation;
      });
      if (_settings != null) {
        await PrayerDatabase.saveSettings(_settings!);
      }
    }
  }

  Future<void> _showCompareDialog(ThemeData theme) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _BibleTranslationDialog(
        mode: _TranslationDialogMode.compare,
        currentPrimary: _primaryTranslation,
        currentCompare: _compareTranslation,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _compareTranslation = result;
        if (_primaryTranslation == result) {
          final options = ['CPDV', 'DRC', 'JUN', 'TAM'];
          _primaryTranslation = options.firstWhere((o) => o != result);
        }
        _settings?.primaryBibleTranslation = _primaryTranslation;
        _settings?.compareBibleTranslation = _compareTranslation;
      });
      if (_settings != null) {
        await PrayerDatabase.saveSettings(_settings!);
      }
    }
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
      body: Column(
        children: [
          _buildTranslationSelectors(theme),
          Expanded(
            child: Stack(
              children: [
                // 1. Main PageView containing the chapters
                PageView.builder(
                  controller: _pageController,
                  itemCount: _allChapters.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
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
                      scrollToVerse: isTarget ? _scrollToVerse : null,
                      highlightStartVerse: isTarget
                          ? _highlightStartVerse
                          : null,
                      highlightEndVerse: isTarget ? _highlightEndVerse : null,
                      navigationSessionId: isTarget
                          ? _navigationSessionId
                          : null,
                      onFavoriteSaved: _loadFavorites,
                    );
                  },
                ),

                // 2. Backdrop Barrier to collapse sheet on tap
                if (_isPanelExpanded)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _collapsePanel,
                      child: Container(color: Colors.black26),
                    ),
                  ),

                // 3. Persistent Peeking Bottom Panel
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _panelHeightAnimation,
                    builder: (context, child) {
                      return Container(
                        height: _panelHeightAnimation.value,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28.0),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        // Drag Handle & Location Header
                        GestureDetector(
                          onVerticalDragUpdate: _onVerticalDragUpdate,
                          onVerticalDragEnd: _onVerticalDragEnd,
                          onTap: _togglePanel,
                          behavior: HitTestBehavior.translucent,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(
                              top: 12.0,
                              bottom: 16.0,
                            ),
                            child: Column(
                              children: [
                                // Small Handle Pill
                                Container(
                                  width: 36,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withAlpha(102),
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Current location title
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${currentRef.book.bookName} ${currentRef.chapter}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _isPanelExpanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_up,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tab Bar and Tab Views (only shown when height is expanded enough)
                        if (_isPanelExpanded)
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _panelHeightAnimation,
                              builder: (context, _) {
                                if (_panelHeightAnimation.value <= 150.0) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    TabBar(
                                      controller: _sheetTabController,
                                      tabs: const [
                                        Tab(text: 'Books'),
                                        Tab(text: 'Chapters'),
                                        Tab(text: 'Favorites'),
                                      ],
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        controller: _sheetTabController,
                                        children: [
                                          // Tab 1: Book List grouped by Category
                                          ListView(
                                            padding: const EdgeInsets.all(16.0),
                                            children: [
                                              _buildBookGroup(
                                                'Pentateuch',
                                                catholicBooks
                                                    .where(
                                                      (b) =>
                                                          b.category ==
                                                          'Pentateuch',
                                                    )
                                                    .toList(),
                                              ),
                                              _buildBookGroup(
                                                'Historical Books',
                                                catholicBooks
                                                    .where(
                                                      (b) =>
                                                          b.category ==
                                                          'Historical Books',
                                                    )
                                                    .toList(),
                                              ),
                                              _buildBookGroup(
                                                'Wisdom Books',
                                                catholicBooks
                                                    .where(
                                                      (b) =>
                                                          b.category ==
                                                          'Wisdom Books',
                                                    )
                                                    .toList(),
                                              ),
                                              _buildBookGroup(
                                                'Prophets',
                                                catholicBooks
                                                    .where(
                                                      (b) =>
                                                          b.category ==
                                                          'Prophets',
                                                    )
                                                    .toList(),
                                              ),
                                              _buildBookGroup(
                                                'Gospels & Acts',
                                                catholicBooks
                                                    .where(
                                                      (b) =>
                                                          b.category ==
                                                          'Gospels & Acts',
                                                    )
                                                    .toList(),
                                              ),
                                              _buildBookGroup(
                                                'Epistles',
                                                catholicBooks
                                                    .where(
                                                      (b) =>
                                                          b.category ==
                                                          'Epistles',
                                                    )
                                                    .toList(),
                                              ),
                                              _buildBookGroup(
                                                'Prophecy',
                                                catholicBooks
                                                    .where(
                                                      (b) =>
                                                          b.category ==
                                                          'Prophecy',
                                                    )
                                                    .toList(),
                                              ),
                                            ],
                                          ),

                                          // Tab 2: Chapter Grid
                                          GridView.builder(
                                            padding: const EdgeInsets.all(16.0),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 6,
                                                  mainAxisSpacing: 12.0,
                                                  crossAxisSpacing: 12.0,
                                                ),
                                            itemCount: _selectedBookForPicker
                                                .chaptersCount,
                                            itemBuilder: (context, index) {
                                              final chapterNum = index + 1;
                                              return InkWell(
                                                onTap: () {
                                                  final pageIndex = _allChapters
                                                      .indexWhere(
                                                        (ref) =>
                                                            ref.book.bookNumber ==
                                                                _selectedBookForPicker
                                                                    .bookNumber &&
                                                            ref.chapter ==
                                                                chapterNum,
                                                      );
                                                  if (pageIndex != -1) {
                                                    _pageController.jumpToPage(
                                                      pageIndex,
                                                    );
                                                    _collapsePanel();
                                                  }
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: theme
                                                          .colorScheme
                                                          .outlineVariant,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$chapterNum',
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          // Tab 3: Favorites List
                                          _buildFavoritesTab(theme),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ], // closes Stack children
            ), // closes Stack
          ), // closes Expanded
        ], // closes Column children
      ), // closes Column
    ); // closes Scaffold
  }

  Widget _buildFavoritesTab(ThemeData theme) {
    if (_loadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_outline,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No favorite passages saved yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Long-press on a verse to start selection, then save.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        final citation = fav.startVerse == fav.endVerse
            ? '${fav.bookName} ${fav.chapter}:${fav.startVerse}'
            : '${fav.bookName} ${fav.chapter}:${fav.startVerse}-${fav.endVerse}';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(
              citation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            subtitle: Text(
              fav.textPreview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () async {
                await BibleDatabaseHelper.db.deleteFavorite(fav.id);
                _loadFavorites();
              },
            ),
            onTap: () {
              final pageIndex = _allChapters.indexWhere(
                (ref) =>
                    ref.book.bookNumber == fav.bookNumber &&
                    ref.chapter == fav.chapter,
              );
              if (pageIndex != -1) {
                setState(() {
                  _targetBookNumber = fav.bookNumber;
                  _targetChapter = fav.chapter;
                  _scrollToVerse = fav.startVerse;
                  _highlightStartVerse = fav.startVerse;
                  _highlightEndVerse = fav.endVerse;
                  _navigationSessionId = DateTime.now().millisecondsSinceEpoch
                      .toString();
                });
                _pageController.jumpToPage(pageIndex);
                _collapsePanel();
              }
            },
          ),
        );
      },
    );
  }
}

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
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
              tooltip: 'Cancel selection',
            ),
            const SizedBox(width: 8),
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

enum _TranslationDialogMode { primary, compare }

class _BibleTranslationDialog extends StatefulWidget {
  final _TranslationDialogMode mode;
  final String currentPrimary;
  final String currentCompare;

  const _BibleTranslationDialog({
    required this.mode,
    required this.currentPrimary,
    required this.currentCompare,
  });

  @override
  State<_BibleTranslationDialog> createState() =>
      _BibleTranslationDialogState();
}

class _BibleTranslationDialogState extends State<_BibleTranslationDialog> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.mode == _TranslationDialogMode.primary
        ? widget.currentPrimary
        : widget.currentCompare;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimaryMode = widget.mode == _TranslationDialogMode.primary;

    return AlertDialog(
      title: Text(
        isPrimaryMode ? 'Primary Translation' : 'Comparison Translation',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPrimaryMode) ...[
                _buildTranslationOption(
                  title: 'Catholic Public Domain Version (CPDV)',
                  origin: 'Ronald L. Conte Jr. (2009)',
                  description:
                      'A contemporary, literal translation of the Clementine Latin Vulgate.',
                  usage:
                      'Clear modern reading, literal Vulgate comparison, and study.',
                  value: 'CPDV',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Douay-Rheims Bible (DRC)',
                  origin: 'Challoner Revision (1749–1752)',
                  description:
                      'A classic, traditional translation of the Latin Vulgate, highly faithful to the Latin text.',
                  usage:
                      'Majestic traditional language, personal devotions, and historical study.',
                  value: 'DRC',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Biblia de Jünemann (JUN)',
                  origin: 'Guillermo Jünemann (1928)',
                  description:
                      'La primera versión de la Biblia completa traducida en América Latina, con el AT traducido de la Septuaginta.',
                  usage:
                      'Estudio bíblico hispano, comparación con la Septuaginta y devoción.',
                  value: 'JUN',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Torres Amat (TAM)',
                  origin: 'Félix Torres Amat (1836)',
                  description:
                      'Una de las traducciones católicas al español más tradicionales e influyentes, basada en la Vulgata.',
                  usage:
                      'Lenguaje tradicional, devoción personal y comparación histórica.',
                  value: 'TAM',
                  theme: theme,
                ),
              ] else ...[
                _buildTranslationOption(
                  title: 'None (Single View)',
                  origin: '',
                  description:
                      'Displays only the primary translation in a single column layout.',
                  usage: '',
                  value: 'none',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Catholic Public Domain Version (CPDV)',
                  origin: 'Ronald L. Conte Jr. (2009)',
                  description:
                      'A contemporary, literal translation of the Clementine Latin Vulgate.',
                  usage:
                      'Clear modern reading, literal Vulgate comparison, and study.',
                  value: 'CPDV',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Douay-Rheims Bible (DRC)',
                  origin: 'Challoner Revision (1749–1752)',
                  description:
                      'A classic, traditional translation of the Latin Vulgate, highly faithful to the Latin text.',
                  usage:
                      'Majestic traditional language, personal devotions, and historical study.',
                  value: 'DRC',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Biblia de Jünemann (JUN)',
                  origin: 'Guillermo Jünemann (1928)',
                  description:
                      'La primera versión de la Biblia completa traducida en América Latina, con el AT traducido de la Septuaginta.',
                  usage:
                      'Estudio bíblico hispano, comparación con la Septuaginta y devoción.',
                  value: 'JUN',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Torres Amat (TAM)',
                  origin: 'Félix Torres Amat (1836)',
                  description:
                      'Una de las traducciones católicas al español más tradicionales e influyentes, basada en la Vulgata.',
                  usage:
                      'Lenguaje tradicional, devoción personal y comparación histórica.',
                  value: 'TAM',
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedValue);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildTranslationOption({
    required String title,
    required String origin,
    required String description,
    required String usage,
    required String value,
    required ThemeData theme,
  }) {
    final isSelected = _selectedValue == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedValue = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (origin.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Origin: $origin',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (usage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Best for: $usage',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
