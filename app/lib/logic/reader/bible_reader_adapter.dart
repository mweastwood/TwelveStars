import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

import 'reader_adapter.dart';
import 'reader_models.dart';

class BibleReaderAdapter implements ReaderAdapter {
  final BibleBook book;
  final BibleDatabase db;

  BibleReaderAdapter({required this.book, BibleDatabase? db})
    : db = db ?? BibleDatabaseHelper.db;

  @override
  Future<ReaderDocument> loadDocument() async {
    final toc = List<ReaderTocEntry>.generate(
      book.chaptersCount,
      (index) => ReaderTocEntry(
        index: index + 1,
        title: 'Chapter ${index + 1}',
        subtitle: '${book.bookName} ${index + 1}',
      ),
    );

    return ReaderDocument(
      documentId: 'bible_${book.bookNumber}',
      title: book.bookName,
      subtitle: book.testament,
      author: 'Scripture',
      sectionsCount: book.chaptersCount,
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

    await db.ensureBookPopulated(
      book.bookNumber,
      book.bookName,
      book.abbrev,
      translation: primaryTrans,
    );

    final primaryVerses = await db.getChapterVerses(
      primaryTrans,
      book.bookNumber,
      sectionIndex,
    );

    List<BibleVerse> compareVerses = [];
    if (compareTrans != 'none') {
      await db.ensureBookPopulated(
        book.bookNumber,
        book.bookName,
        book.abbrev,
        translation: compareTrans,
      );
      compareVerses = await db.getChapterVerses(
        compareTrans,
        book.bookNumber,
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
      title: '${book.bookName} $sectionIndex',
      nodes: nodes,
    );
  }

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    final verseNum = int.tryParse(bookmark.nodeId.split('_').last) ?? 1;
    await db.saveFavorite(
      FavoritePassagesCompanion.insert(
        bookNumber: book.bookNumber,
        bookName: book.bookName,
        chapter: bookmark.sectionIndex,
        startVerse: verseNum,
        endVerse: verseNum,
        textPreview: bookmark.textPreview,
      ),
    );
  }

  @override
  Future<List<ReaderBookmark>> loadBookmarks() async {
    final favorites = await db.getFavorites();
    return favorites
        .where((f) => f.bookNumber == book.bookNumber)
        .map(
          (f) => ReaderBookmark(
            id: '${f.id}',
            documentId: 'bible_${f.bookNumber}',
            sectionIndex: f.chapter,
            nodeId: '${f.bookNumber}_${f.chapter}_${f.startVerse}',
            textPreview: f.textPreview,
            timestamp: DateTime.now(),
          ),
        )
        .toList();
  }
}
