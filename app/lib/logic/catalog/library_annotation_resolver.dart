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
  final targetVol = book?.resolveVolume(
    volumeKey: effectiveVolKey,
    fallbackToFirst: false,
  );

  return ResolvedLibraryAnnotation(
    book: book,
    volumeKey: targetVol?.volumeKey ?? effectiveVolKey,
    assetPath: targetVol?.assetPath ?? resolvedTarget?.assetPath,
    sectionId: ReaderNodeId.parseLibrarySectionId(nodeId),
    itemIndex: itemIdx,
    questionNumber: qNum,
  );
}
