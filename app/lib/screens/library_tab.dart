import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
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

  List<LibraryBookmark> _favorites = [];
  bool _loadingFavorites = true;

  List<UserComment> _comments = [];
  bool _loadingComments = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadComments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loadingFavorites = true);
    try {
      final favs = await BibleDatabaseHelper.db.getLibraryBookmarks();
      if (mounted) {
        setState(() {
          _favorites = favs;
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
                    onTap: () => _openReader(
                      context,
                      matchingBook,
                      sectionId: res.sectionId,
                    ),
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        final parts = fav.textPreview.split('\n');
        final citation = parts.first;
        final preview = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        final (volKey, itemIdx, qNum) = _parseNodeId(fav.nodeId);
        final book = catalog.where((b) => b.id == fav.documentId).firstOrNull;

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
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () async {
                await BibleDatabaseHelper.db.deleteLibraryBookmark(fav.id);
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
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
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
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
    );
  }
}
