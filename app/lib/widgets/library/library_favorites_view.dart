import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';

class LibraryFavoritesView extends StatefulWidget {
  final List<LibraryBookItem>? catalog;
  final List<LibraryBookmark> favorites;
  final bool isLoading;
  final VoidCallback onRefresh;
  final ScrollController? scrollController;
  final void Function(
    LibraryBookItem book, {
    String? volumeKey,
    String? assetPath,
    int? sectionIndex,
    String? sectionId,
    int? itemIndex,
    int? questionNumber,
  })
  onOpenReader;

  const LibraryFavoritesView({
    super.key,
    this.catalog,
    this.scrollController,
    required this.favorites,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenReader,
  });

  @override
  State<LibraryFavoritesView> createState() => _LibraryFavoritesViewState();
}

class _LibraryFavoritesViewState extends State<LibraryFavoritesView> {
  String _selectedFavoriteBookId = 'all';

  List<LibraryBookItem> get _catalog =>
      widget.catalog ?? LibraryHelper.getCatalog();

  String _canonicalBookId(String documentId, List<LibraryBookItem> catalog) {
    final book =
        LibraryCatalog.findBookById(documentId, catalog: catalog) ??
        LibraryCatalog.resolveTarget(
          bookId: documentId,
          catalog: catalog,
        )?.book;
    return book?.id ?? documentId;
  }

  @override
  void didUpdateWidget(covariant LibraryFavoritesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final catalog = _catalog;
    if (_selectedFavoriteBookId != 'all' &&
        !widget.favorites.any(
          (f) =>
              _canonicalBookId(f.documentId, catalog) ==
              _selectedFavoriteBookId,
        )) {
      _selectedFavoriteBookId = 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.favorites.isEmpty) {
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

    final catalog = _catalog;
    final distinctBookIds = widget.favorites
        .map((f) => _canonicalBookId(f.documentId, catalog))
        .toSet()
        .toList();

    final filteredFavorites = _selectedFavoriteBookId == 'all'
        ? widget.favorites
        : widget.favorites
              .where(
                (f) =>
                    _canonicalBookId(f.documentId, catalog) ==
                    _selectedFavoriteBookId,
              )
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
                      label: Text('All (${widget.favorites.length})'),
                      onSelected: (val) {
                        setState(() {
                          _selectedFavoriteBookId = 'all';
                        });
                      },
                    ),
                  ),
                  ...distinctBookIds.map((bookId) {
                    final book =
                        LibraryCatalog.findBookById(bookId, catalog: catalog) ??
                        LibraryCatalog.resolveTarget(
                          bookId: bookId,
                          catalog: catalog,
                        )?.book;
                    final bookTitle = book?.title ?? bookId;
                    final count = widget.favorites
                        .where(
                          (f) =>
                              _canonicalBookId(f.documentId, catalog) == bookId,
                        )
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
            controller: widget.scrollController,
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

              final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary(
                fav.nodeId,
              );
              final resolvedTarget = LibraryCatalog.resolveTarget(
                bookId: fav.documentId,
                volumeKey: volKey,
                catalog: catalog,
              );
              final book =
                  LibraryCatalog.findBookById(
                    fav.documentId,
                    catalog: catalog,
                  ) ??
                  resolvedTarget?.book;

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
                      if (!mounted) return;
                      widget.onRefresh();
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

                    final effectiveVolKey = volKey ?? resolvedTarget?.volumeKey;
                    final targetVol = book.resolveVolume(
                      volumeKey: effectiveVolKey,
                    );

                    widget.onOpenReader(
                      book,
                      volumeKey: targetVol?.volumeKey ?? effectiveVolKey,
                      assetPath:
                          targetVol?.assetPath ?? resolvedTarget?.assetPath,
                      sectionIndex: fav.sectionIndex,
                      sectionId: ReaderNodeId.parseLibrarySectionId(fav.nodeId),
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
