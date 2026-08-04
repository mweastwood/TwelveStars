import 'reader_models.dart';
import 'reader_adapter.dart';
import '../library_database.dart';

class LibraryReaderAdapter implements ReaderAdapter {
  final LibraryBookItem bookItem;
  final String assetPath;

  LibraryReaderAdapter({required this.bookItem, required this.assetPath});

  @override
  Future<ReaderDocument> loadDocument() async {
    final data = await LibraryHelper.loadBookData(assetPath);

    List<ReaderTocEntry> toc = data.toc.asMap().entries.map((e) {
      return ReaderTocEntry(index: e.key, title: e.value.title);
    }).toList();

    return ReaderDocument(
      documentId: bookItem.id,
      title: bookItem.title,
      subtitle: bookItem.subtitle,
      author: bookItem.author,
      sectionsCount: data.sections.length,
      tocEntries: toc,
    );
  }

  @override
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  }) async {
    final data = await LibraryHelper.loadBookData(assetPath);
    if (sectionIndex < 0 || sectionIndex >= data.sections.length) {
      throw RangeError('Section index out of bounds');
    }
    final section = data.sections[sectionIndex];

    List<ReaderContentNode> nodes = [];
    for (int i = 0; i < section.content.length; i++) {
      final item = section.content[i];
      final nodeType = item.type == 'qa'
          ? ReaderNodeType.qa
          : (item.type == 'heading'
                ? ReaderNodeType.heading
                : ReaderNodeType.paragraph);

      nodes.add(
        ReaderContentNode(
          id: '${section.id}-$i',
          nodeType: nodeType,
          primaryText: item.text,
          questionNumber: item.questionNumber?.toString(),
          question: item.question,
          answer: item.answer,
          explanation: item.explanation,
          crossRefId: item.crossRefQNum?.toString(),
        ),
      );
    }

    return ReaderSection(
      sectionIndex: sectionIndex,
      title: section.title,
      subtitle: section.subtitle,
      nodes: nodes,
    );
  }

  final List<ReaderBookmark> _bookmarks = [];

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    _bookmarks.add(bookmark);
  }

  @override
  Future<List<ReaderBookmark>> loadBookmarks() async {
    return List.unmodifiable(_bookmarks);
  }

  final List<ReaderComment> _comments = [];

  @override
  Future<void> saveComment(ReaderComment comment) async {
    _comments.add(comment);
  }

  @override
  Future<List<ReaderComment>> loadComments({String? nodeId}) async {
    if (nodeId != null) {
      return _comments.where((c) => c.nodeId == nodeId).toList();
    }
    return List.unmodifiable(_comments);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    _comments.removeWhere((c) => c.id == commentId);
  }
}
