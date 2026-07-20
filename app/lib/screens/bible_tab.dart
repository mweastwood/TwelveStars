import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/bible_chapter_view.dart';
import 'package:twelve_stars/widgets/bible_translation_dialog.dart';

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
      builder: (context) => BibleTranslationDialog(
        mode: BibleTranslationDialogMode.primary,
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
      builder: (context) => BibleTranslationDialog(
        mode: BibleTranslationDialogMode.compare,
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
                                // Drag Handle Pill
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

                        // Tab Bar and Tab Views
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
              ],
            ),
          ),
        ],
      ),
    );
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
