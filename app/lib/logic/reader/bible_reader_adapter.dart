import 'package:drift/drift.dart' show Value;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

import 'reader_adapter.dart';
import 'reader_models.dart';
import 'reader_node_id.dart';

/// Snapshot of a loaded Bible chapter including primary verses, optional
/// parallel comparison verses indexed by verse number, and chapter annotations.
class BibleChapterData {
  final List<BibleVerse> verses;
  final Map<int, BibleVerse> compareVersesByNumber;
  final Map<int, List<FavoritePassage>> favoritesByVerse;
  final Map<String, List<UserComment>> commentsByNodeId;

  const BibleChapterData({
    required this.verses,
    required this.compareVersesByNumber,
    required this.favoritesByVerse,
    required this.commentsByNodeId,
  });
}

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
        index: index,
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

  /// Loads the primary and optional comparison verses for [chapterNumber] (1-based).
  Future<
    ({List<BibleVerse> primary, Map<int, BibleVerse> compareVersesByNumber})
  >
  loadChapterVerses(
    int chapterNumber, {
    String primaryTranslation = 'CPDV',
    String compareTranslation = 'none',
  }) async {
    await dbHelper.ensureBookPopulated(
      bibleBook.bookNumber,
      bibleBook.bookName,
      bibleBook.abbrev,
      translation: primaryTranslation,
    );

    final primaryVerses = await dbHelper.getChapterVerses(
      primaryTranslation,
      bibleBook.bookNumber,
      chapterNumber,
    );

    Map<int, BibleVerse> compareVersesByNumber = {};
    if (compareTranslation != 'none') {
      await dbHelper.ensureBookPopulated(
        bibleBook.bookNumber,
        bibleBook.bookName,
        bibleBook.abbrev,
        translation: compareTranslation,
      );
      final compareVerses = await dbHelper.getChapterVerses(
        compareTranslation,
        bibleBook.bookNumber,
        chapterNumber,
      );
      compareVersesByNumber = {
        for (final cv in compareVerses) cv.verseNumber: cv,
      };
    }

    return (
      primary: primaryVerses,
      compareVersesByNumber: compareVersesByNumber,
    );
  }

  /// Loads a complete [BibleChapterData] snapshot for [chapterNumber] (1-based).
  Future<BibleChapterData> loadChapterData(
    int chapterNumber, {
    required String primaryTranslation,
    String compareTranslation = 'none',
  }) async {
    final favoritesByVerse = await fetchFavoritesByVerse(chapterNumber);
    final commentsByNodeId = await fetchCommentsByNodeId(chapterNumber);
    final loaded = await loadChapterVerses(
      chapterNumber,
      primaryTranslation: primaryTranslation,
      compareTranslation: compareTranslation,
    );

    return BibleChapterData(
      verses: loaded.primary,
      compareVersesByNumber: loaded.compareVersesByNumber,
      favoritesByVerse: favoritesByVerse,
      commentsByNodeId: commentsByNodeId,
    );
  }

  /// Fetches favorite passages for [chapterNumber] (1-based) indexed by verse number.
  Future<Map<int, List<FavoritePassage>>> fetchFavoritesByVerse(
    int chapterNumber, {
    Map<int, List<FavoritePassage>> fallback = const {},
  }) async {
    try {
      final favorites = await dbHelper.getFavoritesForChapter(
        bibleBook.bookNumber,
        chapterNumber,
      );
      final byVerse = <int, List<FavoritePassage>>{};
      for (final fav in favorites) {
        for (int v = fav.startVerse; v <= fav.endVerse; v++) {
          byVerse.putIfAbsent(v, () => []).add(fav);
        }
      }
      return byVerse;
    } catch (_) {
      return fallback;
    }
  }

  /// Fetches user comments for [chapterNumber] (1-based) indexed by `nodeId`.
  Future<Map<String, List<UserComment>>> fetchCommentsByNodeId(
    int chapterNumber, {
    Map<String, List<UserComment>> fallback = const {},
  }) async {
    try {
      final comments = await dbHelper.getComments(
        documentId: bibleBook.abbrev,
        sectionIndex: chapterNumber,
      );
      final byNodeId = <String, List<UserComment>>{};
      for (final c in comments) {
        byNodeId.putIfAbsent(c.nodeId, () => []).add(c);
      }
      return byNodeId;
    } catch (_) {
      return fallback;
    }
  }

  /// Saves a favorite verse range in [chapterNumber] (1-based).
  Future<void> saveFavoriteRange({
    required int chapterNumber,
    required int startVerse,
    required int endVerse,
    required String textPreview,
  }) async {
    await dbHelper.saveFavorite(
      FavoritePassagesCompanion.insert(
        bookNumber: bibleBook.bookNumber,
        bookName: bibleBook.bookName,
        chapter: chapterNumber,
        startVerse: startVerse,
        endVerse: endVerse,
        textPreview: textPreview,
      ),
    );
  }

  /// Formats a human-readable citation label for a selected verse range.
  String formatSelectionCitation(int chapter, int startVerse, int endVerse) {
    return startVerse == endVerse
        ? '${bibleBook.bookName} $chapter:$startVerse'
        : '${bibleBook.bookName} $chapter:$startVerse-$endVerse';
  }

  /// Formats selected verses for clipboard copy.
  String formatClipboardContent(
    String citation,
    List<BibleVerse> selectedVerses,
  ) {
    final count = selectedVerses.length;
    final versesText = selectedVerses
        .map((v) => count == 1 ? v.verseText : '${v.verseNumber} ${v.verseText}')
        .join(count == 1 ? '' : '\n');
    return '$citation\n$versesText';
  }

  @override
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  }) async {
    final chapterNumber = sectionIndex + 1;
    final loaded = await loadChapterVerses(
      chapterNumber,
      primaryTranslation: primaryVariant ?? 'CPDV',
      compareTranslation: compareVariant ?? 'none',
    );

    final nodes = <ReaderContentNode>[];
    for (final pVerse in loaded.primary) {
      final cVerse = loaded.compareVersesByNumber[pVerse.verseNumber];

      nodes.add(
        ReaderContentNode(
          id: ReaderNodeId.bibleVerse(
            pVerse.bookNumber,
            pVerse.chapter,
            pVerse.verseNumber,
          ),
          nodeType: ReaderNodeType.verse,
          primaryText: pVerse.verseText,
          secondaryText: cVerse?.verseText,
          questionNumber: '${pVerse.verseNumber}',
        ),
      );
    }

    return ReaderSection(
      sectionIndex: sectionIndex,
      title: '${bibleBook.bookName} $chapterNumber',
      nodes: nodes,
    );
  }

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    final verseNum = ReaderNodeId.parseBibleVerseNumber(bookmark.nodeId);
    await saveFavoriteRange(
      chapterNumber: bookmark.sectionIndex + 1,
      startVerse: verseNum,
      endVerse: verseNum,
      textPreview: bookmark.textPreview,
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
            sectionIndex: f.chapter - 1,
            nodeId: ReaderNodeId.bibleVerse(
              f.bookNumber,
              f.chapter,
              f.startVerse,
            ),
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
        documentId: comment.documentId.isNotEmpty
            ? comment.documentId
            : bibleBook.abbrev,
        sectionIndex: comment.sectionIndex + 1,
        nodeId: comment.nodeId,
        commentText: comment.text,
        textPreview: Value(comment.textPreview),
        createdAt: comment.timestamp,
      ),
    );
  }

  @override
  Future<List<ReaderComment>> loadComments({
    String? nodeId,
    int? sectionIndex,
  }) async {
    final list = await dbHelper.getComments(
      documentId: bibleBook.abbrev,
      nodeId: nodeId,
      sectionIndex: sectionIndex != null ? sectionIndex + 1 : null,
    );
    final comments = List<UserComment>.from(list);
    if (sectionIndex == 0) {
      final legacyList = await dbHelper.getComments(
        documentId: bibleBook.abbrev,
        nodeId: nodeId,
        sectionIndex: 0,
      );
      comments.addAll(legacyList);
    }
    return comments
        .map(
          (c) => ReaderComment(
            id: '${c.id}',
            documentId: c.documentId,
            sectionIndex: c.sectionIndex > 0 ? c.sectionIndex - 1 : 0,
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
