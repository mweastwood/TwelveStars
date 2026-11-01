import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_book_filter_bar.dart';

export 'package:twelve_stars/widgets/library/library_book_filter_bar.dart';

typedef LibraryOpenReaderCallback =
    void Function(
      LibraryBookItem book, {
      String? volumeKey,
      String? assetPath,
      int? sectionIndex,
      String? sectionId,
      int? itemIndex,
      int? questionNumber,
    });

class LibraryAnnotationsListShell<T> extends StatefulWidget {
  final List<LibraryBookItem>? catalog;
  final List<T> items;
  final bool isLoading;
  final ScrollController? scrollController;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String Function(T item) documentIdOf;
  final Widget Function(
    BuildContext context,
    T item,
    List<LibraryBookItem> catalog,
  )
  itemBuilder;

  const LibraryAnnotationsListShell({
    super.key,
    this.catalog,
    this.scrollController,
    required this.items,
    required this.isLoading,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.documentIdOf,
    required this.itemBuilder,
  });

  static void openResolvedAnnotation({
    required BuildContext context,
    required ResolvedLibraryAnnotation resolved,
    required int sectionIndex,
    required LibraryOpenReaderCallback onOpenReader,
  }) {
    final book = resolved.book;
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book not found in library'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    onOpenReader(
      book,
      volumeKey: resolved.volumeKey,
      assetPath: resolved.assetPath,
      sectionIndex: sectionIndex,
      sectionId: resolved.sectionId,
      itemIndex: resolved.itemIndex,
      questionNumber: resolved.questionNumber,
    );
  }

  @override
  State<LibraryAnnotationsListShell<T>> createState() =>
      _LibraryAnnotationsListShellState<T>();
}

class _LibraryAnnotationsListShellState<T>
    extends State<LibraryAnnotationsListShell<T>> {
  String _selectedBookId = 'all';

  List<LibraryBookItem> get _catalog =>
      widget.catalog ?? LibraryHelper.getCatalog();

  @override
  void didUpdateWidget(covariant LibraryAnnotationsListShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final catalog = _catalog;
    if (_selectedBookId != 'all' &&
        !widget.items.any(
          (item) =>
              canonicalLibraryBookId(widget.documentIdOf(item), catalog) ==
              _selectedBookId,
        )) {
      _selectedBookId = 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.emptyIcon,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.emptyTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.emptySubtitle,
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
    final distinctBookIds = widget.items
        .map(
          (item) => canonicalLibraryBookId(widget.documentIdOf(item), catalog),
        )
        .toSet()
        .toList();

    final filteredItems = _selectedBookId == 'all'
        ? widget.items
        : widget.items
              .where(
                (item) =>
                    canonicalLibraryBookId(
                      widget.documentIdOf(item),
                      catalog,
                    ) ==
                    _selectedBookId,
              )
              .toList();

    return Column(
      children: [
        if (distinctBookIds.length > 1)
          LibraryBookFilterBar(
            catalog: catalog,
            distinctBookIds: distinctBookIds,
            totalCount: widget.items.length,
            selectedBookId: _selectedBookId,
            countForBook: (bookId) => widget.items
                .where(
                  (item) =>
                      canonicalLibraryBookId(
                        widget.documentIdOf(item),
                        catalog,
                      ) ==
                      bookId,
                )
                .length,
            onBookSelected: (bookId) {
              setState(() {
                _selectedBookId = bookId;
              });
            },
          ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) =>
                widget.itemBuilder(context, filteredItems[index], catalog),
          ),
        ),
      ],
    );
  }
}
