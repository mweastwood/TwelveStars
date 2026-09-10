import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import 'package:twelve_stars/widgets/library/library_continue_reading_hero.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

class LibraryCatalogView extends StatefulWidget {
  final List<LibraryBookItem>? catalog;
  final BookReadingPosition? latestReadingPosition;
  final void Function(
    LibraryBookItem book, {
    String? volumeKey,
    String? assetPath,
    String? sectionId,
    int? sectionIndex,
    int? questionNumber,
    int? itemIndex,
  })
  onOpenReader;

  const LibraryCatalogView({
    super.key,
    this.catalog,
    this.latestReadingPosition,
    required this.onOpenReader,
  });

  @override
  State<LibraryCatalogView> createState() => _LibraryCatalogViewState();
}

class _LibraryCatalogViewState extends State<LibraryCatalogView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchingGlobal = false;
  List<BookSearchResult> _globalSearchResults = [];
  int _searchSessionId = 0;
  String _selectedCategory = 'All';

  List<LibraryBookItem> get _catalog =>
      widget.catalog ?? LibraryHelper.getCatalog();

  List<String> get _categories => [
    'All',
    ...{for (final b in _catalog) b.category},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performGlobalSearch(String query) async {
    final sessionId = ++_searchSessionId;
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

    final allResults = await LibraryHelper.searchCatalog(cleanQuery);

    if (mounted && sessionId == _searchSessionId) {
      setState(() {
        _globalSearchResults = allResults;
        _isSearchingGlobal = false;
      });
    }
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
                          widget.onOpenReader(
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
    final catalog = _catalog;
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
                              onTap: () => widget.onOpenReader(
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
            if (widget.latestReadingPosition != null) ...[
              LibraryContinueReadingHero(
                readingPosition: widget.latestReadingPosition!,
                catalog: catalog,
                onResume:
                    (book, {volumeKey, assetPath, sectionIndex, sectionId}) =>
                        widget.onOpenReader(
                          book,
                          volumeKey: volumeKey,
                          assetPath: assetPath,
                          sectionIndex: sectionIndex,
                          sectionId: sectionId,
                        ),
              ),
              const SizedBox(height: 12),
            ],

            // Thematic Quote Browser Banner
            Card(
              elevation: 0,
              color: theme.colorScheme.tertiaryContainer.withValues(
                alpha: 0.35,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThematicQuoteBrowserScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.format_quote_rounded,
                          size: 20,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPLORE BY THEME',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.tertiary,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Swipe through quotations by sacrament & virtue',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.tertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                                      if (!context.mounted) return;
                                      if (saint != null) {
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
                              onPressed: () => widget.onOpenReader(
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
                            onPressed: () => widget.onOpenReader(bookItem),
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
}
