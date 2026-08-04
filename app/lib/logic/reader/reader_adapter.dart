import 'reader_models.dart';

/// Abstract interface defining the data provider contract for the Unified Reader Framework.
/// Serves as the foundation connecting Reader views with specific content sources
/// (e.g., [BibleReaderAdapter] for Scripture and [LibraryReaderAdapter] for catechisms/documents).
abstract class ReaderAdapter {
  Future<ReaderDocument> loadDocument();
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  });
  Future<void> saveBookmark(ReaderBookmark bookmark);
  Future<List<ReaderBookmark>> loadBookmarks();
  Future<void> saveComment(ReaderComment comment) async {}
  Future<List<ReaderComment>> loadComments({String? nodeId}) async => [];
  Future<void> deleteComment(String commentId) async {}
}
