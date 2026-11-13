import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/library_database.dart';
export '../../logic/catalog/library_annotation_resolver.dart';

/// Horizontal scrollable row of [FilterChip]s for filtering saved library
/// favorites or comments by canonical book ID.
class LibraryBookFilterBar extends StatelessWidget {
  final List<LibraryBookItem> catalog;
  final List<String> distinctBookIds;
  final int totalCount;
  final String selectedBookId;
  final int Function(String bookId) countForBook;
  final ValueChanged<String> onBookSelected;

  const LibraryBookFilterBar({
    super.key,
    required this.catalog,
    required this.distinctBookIds,
    required this.totalCount,
    required this.selectedBookId,
    required this.countForBook,
    required this.onBookSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: selectedBookId == 'all',
                label: Text('All ($totalCount)'),
                onSelected: (_) => onBookSelected('all'),
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
              final count = countForBook(bookId);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: selectedBookId == bookId,
                  label: Text('$bookTitle ($count)'),
                  onSelected: (val) => onBookSelected(val ? bookId : 'all'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
