import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import 'package:twelve_stars/widgets/library/library_book_card.dart';
import 'package:twelve_stars/widgets/library/library_continue_reading_hero.dart';
import 'package:twelve_stars/widgets/library/library_search_results_view.dart';
import 'package:twelve_stars/widgets/library/library_volume_picker_sheet.dart';

class LibraryCatalogView extends StatefulWidget {
  final List<LibraryBookItem>? catalog;
  final BookReadingPosition? latestReadingPosition;
  final String? searchHintText;
  final Widget? searchTrailing;
  final Widget? header;
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
    this.searchHintText,
    this.searchTrailing,
    this.header,
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

    final allResults = await LibraryHelper.searchCatalog(
      cleanQuery,
      catalog: _catalog,
    );

    if (mounted && sessionId == _searchSessionId) {
      setState(() {
        _globalSearchResults = allResults;
        _isSearchingGlobal = false;
      });
    }
  }

  void _showVolumePickerModal(BuildContext context, LibraryBookItem bookItem) {
    LibraryVolumePickerSheet.show(
      context,
      bookItem: bookItem,
      onSelectVolume: (vol) => widget.onOpenReader(
        bookItem,
        volumeKey: vol.volumeKey,
        assetPath: vol.assetPath,
      ),
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
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
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
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  widget.searchHintText ??
                                  'Search catechisms & library...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
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
              ),
              if (widget.searchTrailing != null) ...[
                const SizedBox(width: 8),
                widget.searchTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Search Results View if Searching
          if (_searchQuery.trim().isNotEmpty) ...[
            LibrarySearchResultsView(
              searchQuery: _searchQuery,
              isLoading: _isSearchingGlobal,
              results: _globalSearchResults,
              catalog: catalog,
              onOpenReader: widget.onOpenReader,
            ),
            const SizedBox(height: 80),
          ] else ...[
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(height: 20),
            ],
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
            if (widget.header == null) ...[
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
                        builder: (context) =>
                            const ThematicQuoteBrowserScreen(),
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
            ...displayedBooks.map(
              (bookItem) => LibraryBookCard(
                bookItem: bookItem,
                onOpenReader: widget.onOpenReader,
                onBrowseVolumes: () =>
                    _showVolumePickerModal(context, bookItem),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }
}
