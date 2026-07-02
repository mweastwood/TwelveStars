import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

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

    _sheetTabController = TabController(length: 2, vsync: this);
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
              });
            },
            itemBuilder: (context, index) {
              final ref = _allChapters[index];
              return BibleChapterView(book: ref.book, chapter: ref.chapter);
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
                      padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
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
                                style: theme.textTheme.titleMedium?.copyWith(
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
                      child: Column(
                        children: [
                          TabBar(
                            controller: _sheetTabController,
                            tabs: const [
                              Tab(text: 'Books'),
                              Tab(text: 'Chapters'),
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
                                            (b) => b.category == 'Pentateuch',
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
                                            (b) => b.category == 'Wisdom Books',
                                          )
                                          .toList(),
                                    ),
                                    _buildBookGroup(
                                      'Prophets',
                                      catholicBooks
                                          .where(
                                            (b) => b.category == 'Prophets',
                                          )
                                          .toList(),
                                    ),
                                    _buildBookGroup(
                                      'Gospels & Acts',
                                      catholicBooks
                                          .where(
                                            (b) =>
                                                b.category == 'Gospels & Acts',
                                          )
                                          .toList(),
                                    ),
                                    _buildBookGroup(
                                      'Epistles',
                                      catholicBooks
                                          .where(
                                            (b) => b.category == 'Epistles',
                                          )
                                          .toList(),
                                    ),
                                    _buildBookGroup(
                                      'Prophecy',
                                      catholicBooks
                                          .where(
                                            (b) => b.category == 'Prophecy',
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
                                  itemCount:
                                      _selectedBookForPicker.chaptersCount,
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
                                                  ref.chapter == chapterNum,
                                            );
                                        if (pageIndex != -1) {
                                          _pageController.jumpToPage(pageIndex);
                                          _collapsePanel();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme
                                                .colorScheme
                                                .outlineVariant,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$chapterNum',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BibleChapterView extends StatefulWidget {
  final BibleBook book;
  final int chapter;

  const BibleChapterView({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  State<BibleChapterView> createState() => _BibleChapterViewState();
}

class _BibleChapterViewState extends State<BibleChapterView>
    with AutomaticKeepAliveClientMixin {
  List<BibleVerse> _verses = [];
  bool _loading = true;
  String? _error;

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
        oldWidget.chapter != widget.chapter) {
      _loadChapterData();
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
      await db.ensureBookPopulated(
        widget.book.bookNumber,
        widget.book.bookName,
        widget.book.abbrev,
      );
      final verses = await db.getChapterVerses(
        'CPDV',
        widget.book.bookNumber,
        widget.chapter,
      );
      if (mounted) {
        setState(() {
          _verses = verses;
          _loading = false;
        });
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        80.0,
      ), // space for bottom sheet
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
            'Catholic Public Domain Version (CPDV)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.outline,
            ),
          ),
          const Divider(height: 24),
          ..._verses.map((verse) {
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
}
