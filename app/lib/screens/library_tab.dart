import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _openReader(
    BuildContext context,
    LibraryBookItem bookItem, {
    String? volumeKey,
    String? assetPath,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryReaderScreen(
          bookItem: bookItem,
          initialVolumeKey: volumeKey,
          initialAssetPath: assetPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = LibraryHelper.getCatalog();

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
            else
              ..._globalSearchResults.map((res) {
                final matchingBook = catalog.firstWhere(
                  (b) =>
                      b.title.contains(res.bookTitle) ||
                      res.bookTitle.contains(b.title),
                  orElse: () => catalog.first,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    title: Text(
                      res.sectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.bookTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          res.matchedSnippet,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () => _openReader(context, matchingBook),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ] else ...[
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
                  'CATECHISMS & DOCTRINE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Catalog Book Cards
            ...catalog.map((bookItem) {
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
                              Icons.menu_book,
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
                                Text(
                                  'By ${bookItem.author}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
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
                        Text(
                          'Select Volume:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
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
}
