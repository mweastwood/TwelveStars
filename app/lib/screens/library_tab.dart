import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchingGlobal = false;
  List<BookSearchResult> _globalSearchResults = [];

  List<LibraryBookmark> _favorites = [];
  bool _loadingFavorites = true;
  String _selectedFavoriteBookId = 'all';

  List<UserComment> _comments = [];
  bool _loadingComments = true;
  String _selectedCommentBookId = 'all';

  BookReadingPosition? _latestReadingPosition;
  String _selectedCategory = 'All';

  List<String> get _categories => [
    'All',
    ...{for (final b in LibraryHelper.getCatalog()) b.category},
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadComments();
    _loadLatestReadingPosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestReadingPosition() async {
    try {
      final pos = await BibleDatabaseHelper.db.getLatestBookReadingPosition();
      if (mounted) {
        setState(() {
          _latestReadingPosition = pos;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    setState(() => _loadingFavorites = true);
    try {
      final favs = await BibleDatabaseHelper.db.getLibraryBookmarks();
      if (mounted) {
        setState(() {
          _favorites = favs;
          if (_selectedFavoriteBookId != 'all' &&
              !favs.any((f) => f.documentId == _selectedFavoriteBookId)) {
            _selectedFavoriteBookId = 'all';
          }
          _loadingFavorites = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final allComments = await BibleDatabaseHelper.db.getComments();
      final nonBibleComments = allComments
          .where((c) => !catholicBooks.any((b) => b.abbrev == c.documentId))
          .toList();
      if (mounted) {
        setState(() {
          _comments = nonBibleComments;
          if (_selectedCommentBookId != 'all' &&
              !nonBibleComments.any(
                (c) => c.documentId == _selectedCommentBookId,
              )) {
            _selectedCommentBookId = 'all';
          }
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _performGlobalSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      setState(() {
        _globalSearchResults = [];
        _isSearchingGlobal = false;
      });
      return;
    }

    setState(() {
      _isSearchingGlobal = true;
    });

    final catalog = LibraryHelper.getCatalog();
    final allResults = <BookSearchResult>[];

    for (final bookItem in catalog) {
      if (bookItem.isSeries) {
        for (final vol in bookItem.volumes!) {
          try {
            final parsedData = await LibraryHelper.loadBookData(vol.assetPath);
            final res = LibraryHelper.searchInBook(parsedData, cleanQuery);
            allResults.addAll(res);
            if (allResults.length >= 50) break;
          } catch (_) {}
        }
      } else if (bookItem.defaultAssetPath != null) {
        try {
          final parsedData = await LibraryHelper.loadBookData(
            bookItem.defaultAssetPath!,
          );
          final res = LibraryHelper.searchInBook(parsedData, cleanQuery);
          allResults.addAll(res);
        } catch (_) {}
      }
      if (allResults.length >= 50) break;
    }

    if (mounted) {
      setState(() {
        _globalSearchResults = allResults;
        _isSearchingGlobal = false;
      });
    }
  }

  Future<void> _openReader(
    BuildContext context,
    LibraryBookItem bookItem, {
    String? volumeKey,
    String? assetPath,
    String? sectionId,
    int? sectionIndex,
    int? questionNumber,
    int? itemIndex,
  }) async {
    String? targetVolumeKey = volumeKey;
    String? targetAssetPath = assetPath;
    String? targetSectionId = sectionId;
    int? targetSectionIndex = sectionIndex;

    if (volumeKey == null &&
        assetPath == null &&
        sectionId == null &&
        sectionIndex == null &&
        questionNumber == null &&
        itemIndex == null) {
      try {
        final savedPos = await BibleDatabaseHelper.db.getBookReadingPosition(
          bookItem.id,
        );
        if (savedPos != null) {
          if (bookItem.isSeries && savedPos.volumeKey != null) {
            final vol = bookItem.volumes?.firstWhere(
              (v) => v.volumeKey == savedPos.volumeKey,
              orElse: () => bookItem.volumes!.first,
            );
            if (vol != null) {
              targetVolumeKey = vol.volumeKey;
              targetAssetPath = vol.assetPath;
            }
          }
          targetSectionIndex = savedPos.sectionIndex;
          targetSectionId = savedPos.sectionId;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryReaderScreen(
          bookItem: bookItem,
          initialVolumeKey: targetVolumeKey,
          initialAssetPath: targetAssetPath,
          initialSectionId: targetSectionId,
          initialSectionIndex: targetSectionIndex,
          initialQuestionNumber: questionNumber,
          initialItemIndex: itemIndex,
          navigationSessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          onFavoriteSaved: _loadFavorites,
        ),
      ),
    ).then((_) {
      _loadFavorites();
      _loadComments();
      _loadLatestReadingPosition();
    });
  }

  (String? volKey, int? itemIdx, int? qNum) _parseNodeId(String nodeId) {
    String? volumeKey;
    int? itemIndex;
    int? questionNumber;

    String cleanNodeId = nodeId;
    if (nodeId.contains(':')) {
      final parts = nodeId.split(':');
      volumeKey = parts.first;
      cleanNodeId = parts.sublist(1).join(':');
    }

    if (cleanNodeId.contains('_')) {
      final lastPart = cleanNodeId.split('_').last;
      if (lastPart.startsWith('q')) {
        questionNumber = int.tryParse(lastPart.substring(1));
      } else {
        itemIndex = int.tryParse(lastPart);
      }
    } else if (cleanNodeId.contains('-')) {
      final lastPart = cleanNodeId.split('-').last;
      itemIndex = int.tryParse(lastPart);
    }

    return (volumeKey, itemIndex, questionNumber);
  }

  Widget _buildContinueReadingHero(
    ThemeData theme,
    List<LibraryBookItem> catalog,
  ) {
    if (_latestReadingPosition == null) return const SizedBox.shrink();

    final book = catalog
        .where((b) => b.id == _latestReadingPosition!.bookId)
        .firstOrNull;
    if (book == null) return const SizedBox.shrink();

    String? volumeName;
    String? volumeAssetPath;
    if (book.isSeries && _latestReadingPosition!.volumeKey != null) {
      final vol = book.volumes
          ?.where((v) => v.volumeKey == _latestReadingPosition!.volumeKey)
          .firstOrNull;
      if (vol != null) {
        volumeName = vol.name;
        volumeAssetPath = vol.assetPath;
      }
    }

    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark_added_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'CONTINUE READING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (volumeName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          volumeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'Section ${_latestReadingPosition!.sectionIndex + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _openReader(
                    context,
                    book,
                    volumeKey: _latestReadingPosition!.volumeKey,
                    assetPath: volumeAssetPath,
                    sectionIndex: _latestReadingPosition!.sectionIndex,
                    sectionId: _latestReadingPosition!.sectionId,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Resume'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Apostolic Fathers':
        return Icons.history_edu_rounded;
      case 'Early Apologists':
        return Icons.shield_outlined;
      case 'Church Fathers':
        return Icons.church_rounded;
      case 'Patristics':
        return Icons.account_balance_rounded;
      case 'Doctors of the Church':
      case 'Doctors of the Church / Spiritual Classics':
        return Icons.school_rounded;
      case 'Marian & Spiritual Classics':
        return Icons.flare_rounded;
      case 'Monastic & Spiritual Classics':
        return Icons.cottage_rounded;
      case 'Spiritual Classics':
        return Icons.self_improvement_rounded;
      case 'Catechisms':
      default:
        return Icons.menu_book_rounded;
    }
  }

  void _showVolumePickerModal(BuildContext context, LibraryBookItem bookItem) {
    if (bookItem.volumes == null || bookItem.volumes!.isEmpty) return;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookItem.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select from ${bookItem.volumes!.length} volumes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: bookItem.volumes!.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final vol = bookItem.volumes![idx];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            (idx + 1).toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          vol.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: vol.description.isNotEmpty
                            ? Text(
                                vol.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openReader(
                            context,
                            bookItem,
                            volumeKey: vol.volumeKey,
                            assetPath: vol.assetPath,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Books'),
              Tab(text: 'Favorites'),
              Tab(text: 'Comments'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCatalogTab(theme),
                _buildFavoritesTab(theme),
                _buildCommentsTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTab(ThemeData theme) {
    final catalog = LibraryHelper.getCatalog();
    final displayedBooks = _selectedCategory == 'All'
        ? catalog
        : catalog.where((b) => b.category == _selectedCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Global Library Search Bar
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search catechisms & library...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                        _performGlobalSearch(val);
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _globalSearchResults = [];
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Results View if Searching
          if (_searchQuery.trim().isNotEmpty) ...[
            Text(
              'SEARCH RESULTS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            if (_isSearchingGlobal)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_globalSearchResults.isEmpty)
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No search results found for "$_searchQuery".',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              ...() {
                final Map<String, List<BookSearchResult>> groups = {};
                for (final res in _globalSearchResults) {
                  groups.putIfAbsent(res.bookTitle, () => []).add(res);
                }

                return groups.entries.map((entry) {
                  final bookTitle = entry.key;
                  final results = entry.value;
                  final matchingBook = catalog.firstWhere(
                    (b) => b.title == bookTitle,
                    orElse: () => catalog.first,
                  );
                  final categoryIcon = _getCategoryIcon(matchingBook.category);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                categoryIcon,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bookTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${results.length} ${results.length == 1 ? 'match' : 'matches'}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...results.map((res) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _openReader(
                                context,
                                matchingBook,
                                sectionId: res.sectionId,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 4.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.sectionTitle,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.secondary,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      res.matchedSnippet,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                });
              }(),
            ],
            const SizedBox(height: 80),
          ] else ...[
            // Continue Reading Hero Card if available
            if (_latestReadingPosition != null) ...[
              _buildContinueReadingHero(theme, catalog),
              const SizedBox(height: 12),
            ],

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Category Section Header
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory == 'All'
                      ? 'CATECHISMS & DOCTRINE'
                      : _selectedCategory.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${displayedBooks.length} ${displayedBooks.length == 1 ? 'WORK' : 'WORKS'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Catalog Book Cards
            ...displayedBooks.map((bookItem) {
              final categoryIcon = _getCategoryIcon(bookItem.category);

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              categoryIcon,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookItem.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bookItem.subtitle,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (bookItem.authorSaintId != null)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () async {
                                      final saint =
                                          await SaintDatabase.getSaintById(
                                            bookItem.authorSaintId!,
                                          );
                                      if (mounted && saint != null) {
                                        SaintDetailsSheet.show(context, saint);
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'By ${bookItem.author}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    'By ${bookItem.author}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                // Metadata Badges
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  children: [
                                    if (bookItem.era != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .secondaryContainer
                                              .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          bookItem.era!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        bookItem.category,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                    if (bookItem.isSeries)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .tertiaryContainer
                                              .withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${bookItem.volumes!.length} Volumes',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onTertiaryContainer,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bookItem.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Volume chips if series, or Read Book button if single book
                      if (bookItem.isSeries) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Volume (${bookItem.volumes!.length}):',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              icon: const Icon(Icons.layers_outlined, size: 16),
                              label: const Text('Browse All ▾'),
                              onPressed: () =>
                                  _showVolumePickerModal(context, bookItem),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 6.0,
                          children: bookItem.volumes!.map((vol) {
                            return ActionChip(
                              avatar: Icon(
                                Icons.bookmark_border,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(vol.name),
                              onPressed: () => _openReader(
                                context,
                                bookItem,
                                volumeKey: vol.volumeKey,
                                assetPath: vol.assetPath,
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.menu_book, size: 18),
                            label: const Text('Read Book'),
                            onPressed: () => _openReader(context, bookItem),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
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
                'No favorite passages saved in Library yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Long-press on any passage in a book to select and save.',
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

    final catalog = LibraryHelper.getCatalog();
    final distinctBookIds = _favorites
        .map((f) => f.documentId)
        .toSet()
        .toList();

    final filteredFavorites = _selectedFavoriteBookId == 'all'
        ? _favorites
        : _favorites
              .where((f) => f.documentId == _selectedFavoriteBookId)
              .toList();

    return Column(
      children: [
        if (distinctBookIds.length > 1) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _selectedFavoriteBookId == 'all',
                      label: Text('All (${_favorites.length})'),
                      onSelected: (val) {
                        setState(() {
                          _selectedFavoriteBookId = 'all';
                        });
                      },
                    ),
                  ),
                  ...distinctBookIds.map((bookId) {
                    final book = catalog
                        .where((b) => b.id == bookId)
                        .firstOrNull;
                    final bookTitle = book?.title ?? bookId;
                    final count = _favorites
                        .where((f) => f.documentId == bookId)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: _selectedFavoriteBookId == bookId,
                        label: Text('$bookTitle ($count)'),
                        onSelected: (val) {
                          setState(() {
                            _selectedFavoriteBookId = val ? bookId : 'all';
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: filteredFavorites.length,
            itemBuilder: (context, index) {
              final fav = filteredFavorites[index];
              final parts = fav.textPreview.split('\n');
              final citation = parts.first;
              final preview = parts.length > 1
                  ? parts.sublist(1).join(' ')
                  : '';

              final (volKey, itemIdx, qNum) = _parseNodeId(fav.nodeId);
              final book = catalog
                  .where((b) => b.id == fav.documentId)
                  .firstOrNull;

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
                  subtitle: preview.isNotEmpty
                      ? Text(
                          preview,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () async {
                      await BibleDatabaseHelper.db.deleteLibraryBookmark(
                        fav.id,
                      );
                      _loadFavorites();
                    },
                  ),
                  onTap: () {
                    if (book == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Book not found in library'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    String? targetAssetPath;
                    String? targetVolKey = volKey;
                    if (book.isSeries && book.volumes != null) {
                      final match =
                          book.volumes!
                              .where((v) => v.volumeKey == volKey)
                              .firstOrNull ??
                          book.volumes!.firstOrNull;
                      if (match != null) {
                        targetVolKey = match.volumeKey;
                        targetAssetPath = match.assetPath;
                      }
                    }

                    _openReader(
                      context,
                      book,
                      volumeKey: targetVolKey,
                      assetPath: targetAssetPath,
                      sectionIndex: fav.sectionIndex,
                      itemIndex: itemIdx,
                      questionNumber: qNum,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab(ThemeData theme) {
    if (_loadingComments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No comments on library books yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Long-press on a passage, then tap Comment to add a note.',
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

    final catalog = LibraryHelper.getCatalog();
    final distinctBookIds = _comments.map((c) => c.documentId).toSet().toList();

    final filteredComments = _selectedCommentBookId == 'all'
        ? _comments
        : _comments
              .where((c) => c.documentId == _selectedCommentBookId)
              .toList();

    return Column(
      children: [
        if (distinctBookIds.length > 1) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _selectedCommentBookId == 'all',
                      label: Text('All (${_comments.length})'),
                      onSelected: (val) {
                        setState(() {
                          _selectedCommentBookId = 'all';
                        });
                      },
                    ),
                  ),
                  ...distinctBookIds.map((bookId) {
                    final book = catalog
                        .where((b) => b.id == bookId)
                        .firstOrNull;
                    final bookTitle = book?.title ?? bookId;
                    final count = _comments
                        .where((c) => c.documentId == bookId)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: _selectedCommentBookId == bookId,
                        label: Text('$bookTitle ($count)'),
                        onSelected: (val) {
                          setState(() {
                            _selectedCommentBookId = val ? bookId : 'all';
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: filteredComments.length,
            itemBuilder: (context, index) {
              final comment = filteredComments[index];
              final book = catalog
                  .where((b) => b.id == comment.documentId)
                  .firstOrNull;

              final (volKey, itemIdx, qNum) = _parseNodeId(comment.nodeId);
              String header = book?.title ?? comment.documentId;
              if (book != null &&
                  volKey != null &&
                  book.isSeries &&
                  book.volumes != null) {
                final vol = book.volumes!
                    .where((v) => v.volumeKey == volKey)
                    .firstOrNull;
                if (vol != null) {
                  header = '${book.title} (${vol.shortName})';
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    header,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        comment.commentText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (comment.textPreview != null &&
                          comment.textPreview!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${comment.textPreview}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () async {
                      await BibleDatabaseHelper.db.deleteComment(comment.id);
                      _loadComments();
                    },
                  ),
                  onTap: () {
                    if (book == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Book not found in library'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    String? targetAssetPath;
                    String? targetVolKey = volKey;
                    if (book.isSeries && book.volumes != null) {
                      final match =
                          book.volumes!
                              .where((v) => v.volumeKey == volKey)
                              .firstOrNull ??
                          book.volumes!.firstOrNull;
                      if (match != null) {
                        targetVolKey = match.volumeKey;
                        targetAssetPath = match.assetPath;
                      }
                    }

                    _openReader(
                      context,
                      book,
                      volumeKey: targetVolKey,
                      assetPath: targetAssetPath,
                      sectionIndex: comment.sectionIndex,
                      itemIndex: itemIdx,
                      questionNumber: qNum,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
