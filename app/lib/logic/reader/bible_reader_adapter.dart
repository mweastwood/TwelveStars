import 'package:drift/drift.dart' show Value;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

import 'reader_adapter.dart';
import 'reader_models.dart';

class BibleReaderAdapter implements ReaderAdapter {
  final BibleBook bibleBook;
  final BibleDatabase dbHelper;

  BibleReaderAdapter({required this.bibleBook, BibleDatabase? dbHelper})
    : dbHelper = dbHelper ?? BibleDatabaseHelper.db;

  @override
  Future<ReaderDocument> loadDocument() async {
    final toc = List<ReaderTocEntry>.generate(
      bibleBook.chaptersCount,
      (index) => ReaderTocEntry(
        index: index + 1,
        title: 'Chapter ${index + 1}',
        subtitle: '${bibleBook.bookName} ${index + 1}',
      ),
    );

    return ReaderDocument(
      documentId: bibleBook.abbrev,
      title: bibleBook.bookName,
      subtitle: bibleBook.testament,
      author: 'Scripture',
      sectionsCount: bibleBook.chaptersCount,
      tocEntries: toc,
    );
  }

  @override
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  }) async {
    final primaryTrans = primaryVariant ?? 'CPDV';
    final compareTrans = compareVariant ?? 'none';

    await dbHelper.ensureBookPopulated(
      bibleBook.bookNumber,
      bibleBook.bookName,
      bibleBook.abbrev,
      translation: primaryTrans,
    );

    final primaryVerses = await dbHelper.getChapterVerses(
      primaryTrans,
      bibleBook.bookNumber,
      sectionIndex,
    );

    List<BibleVerse> compareVerses = [];
    if (compareTrans != 'none') {
      await dbHelper.ensureBookPopulated(
        bibleBook.bookNumber,
        bibleBook.bookName,
        bibleBook.abbrev,
        translation: compareTrans,
      );
      compareVerses = await dbHelper.getChapterVerses(
        compareTrans,
        bibleBook.bookNumber,
        sectionIndex,
      );
    }

    final nodes = <ReaderContentNode>[];
    for (int i = 0; i < primaryVerses.length; i++) {
      final pVerse = primaryVerses[i];
      final cVerse = (i < compareVerses.length) ? compareVerses[i] : null;

      nodes.add(
        ReaderContentNode(
          id: '${pVerse.bookNumber}_${pVerse.chapter}_${pVerse.verseNumber}',
          nodeType: ReaderNodeType.verse,
          primaryText: pVerse.verseText,
          secondaryText: cVerse?.verseText,
          questionNumber: '${pVerse.verseNumber}',
        ),
      );
    }

    return ReaderSection(
      sectionIndex: sectionIndex,
      title: '${bibleBook.bookName} $sectionIndex',
      nodes: nodes,
    );
  }

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    final verseNum = int.tryParse(bookmark.nodeId.split('_').last) ?? 1;
    await dbHelper.saveFavorite(
      FavoritePassagesCompanion.insert(
        bookNumber: bibleBook.bookNumber,
        bookName: bibleBook.bookName,
        chapter: bookmark.sectionIndex,
        startVerse: verseNum,
        endVerse: verseNum,
        textPreview: bookmark.textPreview,
      ),
    );
  }

  @override
  Future<List<ReaderBookmark>> loadBookmarks() async {
    final favorites = await dbHelper.getFavorites();
    return favorites
        .where((f) => f.bookNumber == bibleBook.bookNumber)
        .map(
          (f) => ReaderBookmark(
            id: '${f.id}',
            documentId: bibleBook.abbrev,
            sectionIndex: f.chapter,
            nodeId: '${f.bookNumber}_${f.chapter}_${f.startVerse}',
            textPreview: f.textPreview,
            timestamp: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveComment(ReaderComment comment) async {
    await dbHelper.saveComment(
      UserCommentsCompanion.insert(
        documentId: comment.documentId,
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
      documentId: bibleBook.abbrev,
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
