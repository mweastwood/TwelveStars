import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';

/// Resolves [documentId] (which may be a book ID, volume key, or legacy alias)
/// to its canonical parent [LibraryBookItem.id] in [catalog].
String canonicalLibraryBookId(
  String documentId,
  List<LibraryBookItem> catalog,
) {
  final book =
      LibraryCatalog.findBookById(documentId, catalog: catalog) ??
      LibraryCatalog.resolveTarget(bookId: documentId, catalog: catalog)?.book;
  return book?.id ?? documentId;
}

/// Resolved target metadata for a saved library bookmark or comment.
class ResolvedLibraryAnnotation {
  final LibraryBookItem? book;
  final String? volumeKey;
  final String? assetPath;
  final String? sectionId;
  final int? itemIndex;
  final int? questionNumber;

  const ResolvedLibraryAnnotation({
    required this.book,
    required this.volumeKey,
    required this.assetPath,
    required this.sectionId,
    required this.itemIndex,
    required this.questionNumber,
  });
}

/// Parses [nodeId] and resolves [documentId] against [catalog] to determine
/// the target book, volume, asset path, section ID, and item/question coordinates.
ResolvedLibraryAnnotation resolveLibraryAnnotation({
  required String documentId,
  required String nodeId,
  required List<LibraryBookItem> catalog,
}) {
  final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary(nodeId);
  final resolvedTarget = LibraryCatalog.resolveTarget(
    bookId: documentId,
    volumeKey: volKey,
    catalog: catalog,
  );
  final book =
      LibraryCatalog.findBookById(documentId, catalog: catalog) ??
      resolvedTarget?.book;
  final effectiveVolKey = resolvedTarget?.volumeKey ?? volKey;
  final targetVol = book?.resolveVolume(volumeKey: effectiveVolKey);

  return ResolvedLibraryAnnotation(
    book: book,
    volumeKey: targetVol?.volumeKey ?? effectiveVolKey,
    assetPath: targetVol?.assetPath ?? resolvedTarget?.assetPath,
    sectionId: ReaderNodeId.parseLibrarySectionId(nodeId),
    itemIndex: itemIdx,
    questionNumber: qNum,
  );
}

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
