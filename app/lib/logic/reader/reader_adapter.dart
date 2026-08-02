import 'reader_models.dart';

abstract class ReaderAdapter {
  Future<ReaderDocument> loadDocument();
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  });
  Future<void> saveBookmark(ReaderBookmark bookmark);
  Future<List<ReaderBookmark>> loadBookmarks();
}
