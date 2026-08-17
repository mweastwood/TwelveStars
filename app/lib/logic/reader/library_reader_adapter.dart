import 'package:drift/drift.dart' show Value;
import '../bible_database.dart';
import '../library_database.dart';
import 'reader_adapter.dart';
import 'reader_models.dart';

class LibraryReaderAdapter implements ReaderAdapter {
  final LibraryBookItem bookItem;
  final String assetPath;
  final BibleDatabase dbHelper;

  LibraryReaderAdapter({
    required this.bookItem,
    required this.assetPath,
    BibleDatabase? dbHelper,
  }) : dbHelper = dbHelper ?? BibleDatabaseHelper.db;

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

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    await dbHelper.saveLibraryBookmark(
      LibraryBookmarksCompanion.insert(
        documentId: bookItem.id,
        sectionIndex: bookmark.sectionIndex,
        nodeId: bookmark.nodeId,
        textPreview: bookmark.textPreview,
        createdAt: bookmark.timestamp,
      ),
    );
  }

  @override
  Future<List<ReaderBookmark>> loadBookmarks() async {
    final list = await dbHelper.getLibraryBookmarks(documentId: bookItem.id);
    return list
        .map(
          (b) => ReaderBookmark(
            id: '${b.id}',
            documentId: b.documentId,
            sectionIndex: b.sectionIndex,
            nodeId: b.nodeId,
            textPreview: b.textPreview,
            timestamp: b.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveComment(ReaderComment comment) async {
    await dbHelper.saveComment(
      UserCommentsCompanion.insert(
        documentId: comment.documentId.isNotEmpty
            ? comment.documentId
            : bookItem.id,
        sectionIndex: comment.sectionIndex,
        nodeId: comment.nodeId,
        commentText: comment.text,
        textPreview: Value(comment.textPreview),
        createdAt: comment.timestamp,
      ),
    );
  }

  @override
  Future<List<ReaderComment>> loadComments({String? nodeId}) async {
    final list = await dbHelper.getComments(
      documentId: bookItem.id,
      nodeId: nodeId,
    );
    return list
        .map(
          (c) => ReaderComment(
            id: '${c.id}',
            documentId: c.documentId,
            sectionIndex: c.sectionIndex,
            nodeId: c.nodeId,
            text: c.commentText,
            textPreview: c.textPreview,
            timestamp: c.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> updateComment(String commentId, String updatedText) async {
    final id = int.tryParse(commentId);
    if (id != null) {
      await dbHelper.updateComment(id, updatedText);
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final id = int.tryParse(commentId);
    if (id != null) {
      await dbHelper.deleteComment(id);
    }
  }
}
