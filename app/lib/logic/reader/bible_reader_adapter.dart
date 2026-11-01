import 'package:drift/drift.dart' show Value;
import 'package:twelve_stars/logic/bible_citation_parser.dart';
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

class _ChapterCacheKey {
  final int dbIdentity;
  final int bookNumber;
  final int chapterNumber;
  final String primaryTranslation;
  final String compareTranslation;
  final int annotationsRevision;

  const _ChapterCacheKey({
    required this.dbIdentity,
    required this.bookNumber,
    required this.chapterNumber,
    required this.primaryTranslation,
    required this.compareTranslation,
    required this.annotationsRevision,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ChapterCacheKey &&
          dbIdentity == other.dbIdentity &&
          bookNumber == other.bookNumber &&
          chapterNumber == other.chapterNumber &&
          primaryTranslation == other.primaryTranslation &&
          compareTranslation == other.compareTranslation &&
          annotationsRevision == other.annotationsRevision;

  @override
  int get hashCode => Object.hash(
    dbIdentity,
    bookNumber,
    chapterNumber,
    primaryTranslation,
    compareTranslation,
    annotationsRevision,
  );
}

class BibleReaderAdapter implements ReaderAdapter {
  static const int maxCachedChapters = 24;
  static final Map<_ChapterCacheKey, BibleChapterData> _chapterDataCache = {};

  /// Clears all cached [BibleChapterData] entries.
  static void clearChapterDataCache() => _chapterDataCache.clear();

  final BibleBook bibleBook;
  final BibleDatabase dbHelper;

  BibleReaderAdapter({required this.bibleBook, BibleDatabase? dbHelper})
    : dbHelper = dbHelper ?? BibleDatabaseHelper.db;

  _ChapterCacheKey _buildCacheKey(
    int chapterNumber, {
    required String primaryTranslation,
    required String compareTranslation,
    required int annotationsRevision,
  }) {
    return _ChapterCacheKey(
      dbIdentity: identityHashCode(dbHelper),
      bookNumber: bibleBook.bookNumber,
      chapterNumber: chapterNumber,
      primaryTranslation: primaryTranslation,
      compareTranslation: compareTranslation,
      annotationsRevision: annotationsRevision,
    );
  }

  /// Synchronously returns a cached [BibleChapterData] snapshot if available,
  /// promoting it in the LRU cache.
  BibleChapterData? getCachedChapterData(
    int chapterNumber, {
    required String primaryTranslation,
    String compareTranslation = 'none',
    int annotationsRevision = 0,
  }) {
    final key = _buildCacheKey(
      chapterNumber,
      primaryTranslation: primaryTranslation,
      compareTranslation: compareTranslation,
      annotationsRevision: annotationsRevision,
    );
    final cached = _chapterDataCache.remove(key);
    if (cached != null) {
      _chapterDataCache[key] = cached;
    }
    return cached;
  }

  void _storeChapterDataInCache(
    _ChapterCacheKey key,
    BibleChapterData chapterData,
  ) {
    if (chapterData.verses.isEmpty) return;
    _chapterDataCache.remove(key);
    if (_chapterDataCache.length >= maxCachedChapters) {
      _chapterDataCache.remove(_chapterDataCache.keys.first);
    }
    _chapterDataCache[key] = chapterData;
  }

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

  Future<List<BibleVerse>> _loadSingleTranslationVerses(
    int chapterNumber,
    String translation,
  ) async {
    await dbHelper.ensureBookPopulated(
      bibleBook.bookNumber,
      bibleBook.bookName,
      bibleBook.abbrev,
      translation: translation,
    );
    return dbHelper.getChapterVerses(
      translation,
      bibleBook.bookNumber,
      chapterNumber,
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
    final primaryFuture = _loadSingleTranslationVerses(
      chapterNumber,
      primaryTranslation,
    );

    Future<Map<int, BibleVerse>>? compareFuture;
    if (compareTranslation != 'none') {
      compareFuture = () async {
        try {
          final compareVerses = await _loadSingleTranslationVerses(
            chapterNumber,
            compareTranslation,
          );
          return <int, BibleVerse>{
            for (final cv in compareVerses) cv.verseNumber: cv,
          };
        } catch (_) {
          // Comparative translation failure or missing book should not crash primary translation view
          return <int, BibleVerse>{};
        }
      }();
    }

    final primaryVerses = await primaryFuture;
    final compareVersesByNumber = compareFuture != null
        ? await compareFuture
        : <int, BibleVerse>{};

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
    int annotationsRevision = 0,
  }) async {
    final favoritesFuture = fetchFavoritesByVerse(chapterNumber);
    final commentsFuture = fetchCommentsByNodeId(chapterNumber);
    final versesFuture = loadChapterVerses(
      chapterNumber,
      primaryTranslation: primaryTranslation,
      compareTranslation: compareTranslation,
    );

    final favoritesByVerse = await favoritesFuture;
    final commentsByNodeId = await commentsFuture;
    final loaded = await versesFuture;

    final chapterData = BibleChapterData(
      verses: loaded.primary,
      compareVersesByNumber: loaded.compareVersesByNumber,
      favoritesByVerse: favoritesByVerse,
      commentsByNodeId: commentsByNodeId,
    );

    final key = _buildCacheKey(
      chapterNumber,
      primaryTranslation: primaryTranslation,
      compareTranslation: compareTranslation,
      annotationsRevision: annotationsRevision,
    );
    _storeChapterDataInCache(key, chapterData);

    return chapterData;
  }

  /// Pre-populates the in-memory [BibleChapterData] cache for [chapterNumber]
  /// if it is not already cached and the book's verses are already present in
  /// [dbHelper] (avoiding unexpected background asset parsing in tests).
  Future<void> prefetchChapterData(
    int chapterNumber, {
    required String primaryTranslation,
    String compareTranslation = 'none',
    int annotationsRevision = 0,
  }) async {
    final existing = getCachedChapterData(
      chapterNumber,
      primaryTranslation: primaryTranslation,
      compareTranslation: compareTranslation,
      annotationsRevision: annotationsRevision,
    );
    if (existing != null) return;

    try {
      final primaryVerses = await dbHelper.getChapterVerses(
        primaryTranslation,
        bibleBook.bookNumber,
        chapterNumber,
      );
      if (primaryVerses.isEmpty) return;

      final favoritesFuture = fetchFavoritesByVerse(chapterNumber);
      final commentsFuture = fetchCommentsByNodeId(chapterNumber);

      Map<int, BibleVerse> compareVersesByNumber = {};
      if (compareTranslation != 'none') {
        try {
          final compareVerses = await dbHelper.getChapterVerses(
            compareTranslation,
            bibleBook.bookNumber,
            chapterNumber,
          );
          compareVersesByNumber = {
            for (final cv in compareVerses) cv.verseNumber: cv,
          };
        } catch (_) {}
      }

      final favoritesByVerse = await favoritesFuture;
      final commentsByNodeId = await commentsFuture;

      final chapterData = BibleChapterData(
        verses: primaryVerses,
        compareVersesByNumber: compareVersesByNumber,
        favoritesByVerse: favoritesByVerse,
        commentsByNodeId: commentsByNodeId,
      );

      final key = _buildCacheKey(
        chapterNumber,
        primaryTranslation: primaryTranslation,
        compareTranslation: compareTranslation,
        annotationsRevision: annotationsRevision,
      );
      _storeChapterDataInCache(key, chapterData);
    } catch (_) {}
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

  /// Fetches favorite passages across [chapters] (1-based) for [bookNumber],
  /// indexed by [ReaderNodeId.bibleVerse] key.
  static Future<Map<String, List<FavoritePassage>>>
  fetchFavoritesByNodeIdForChapters(
    int bookNumber,
    Iterable<int> chapters, {
    BibleDatabase? dbHelper,
  }) async {
    final db = dbHelper ?? BibleDatabaseHelper.db;
    final byVerseKey = <String, List<FavoritePassage>>{};
    for (final ch in chapters.toSet()) {
      final favorites = await db.getFavoritesForChapter(bookNumber, ch);
      for (final fav in favorites) {
        for (int v = fav.startVerse; v <= fav.endVerse; v++) {
          final key = ReaderNodeId.bibleVerse(fav.bookNumber, fav.chapter, v);
          byVerseKey.putIfAbsent(key, () => []).add(fav);
        }
      }
    }
    return byVerseKey;
  }

  /// Fetches user comments across [chapters] (1-based) for [bookAbbrev],
  /// indexed by `nodeId`.
  static Future<Map<String, List<UserComment>>>
  fetchCommentsByNodeIdForChapters(
    String bookAbbrev,
    Iterable<int> chapters, {
    BibleDatabase? dbHelper,
  }) async {
    final db = dbHelper ?? BibleDatabaseHelper.db;
    final targetChapters = chapters.toSet();
    if (targetChapters.isEmpty) {
      return {};
    }

    final List<UserComment> comments;
    if (targetChapters.length == 1) {
      comments = await db.getComments(
        documentId: bookAbbrev,
        sectionIndex: targetChapters.first,
      );
    } else {
      final commentsList = await Future.wait(
        targetChapters.map(
          (ch) => db.getComments(documentId: bookAbbrev, sectionIndex: ch),
        ),
      );
      comments = commentsList.expand((list) => list).toList();
    }

    final byNodeId = <String, List<UserComment>>{};
    for (final c in comments) {
      byNodeId.putIfAbsent(c.nodeId, () => []).add(c);
    }
    return byNodeId;
  }

  /// Fetches user comments for [chapterNumber] (1-based) indexed by `nodeId`.
  Future<Map<String, List<UserComment>>> fetchCommentsByNodeId(
    int chapterNumber, {
    Map<String, List<UserComment>> fallback = const {},
  }) async {
    try {
      return await fetchCommentsByNodeIdForChapters(bibleBook.abbrev, [
        chapterNumber,
      ], dbHelper: dbHelper);
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

  /// Formats a human-readable citation label for a single-chapter or
  /// cross-chapter passage according to [numberingSystem].
  static String formatPassageCitation({
    required int bookNumber,
    required String bookName,
    required int startChapter,
    required int startVerse,
    required int endChapter,
    required int endVerse,
    BibleNumberingSystem numberingSystem = BibleNumberingSystem.vulgate,
    String crossChapterSeparator = '-',
  }) {
    final String vulgatePart;
    if (startChapter == endChapter && startVerse == endVerse) {
      vulgatePart = '$startChapter:$startVerse';
    } else if (startChapter == endChapter) {
      vulgatePart = '$startChapter:$startVerse-$endVerse';
    } else {
      vulgatePart =
          '$startChapter:$startVerse$crossChapterSeparator$endChapter:$endVerse';
    }

    if (numberingSystem == BibleNumberingSystem.vulgate) {
      return '$bookName $vulgatePart';
    }

    final mStart = BibleVerseResolver.vulgateToMasoreticVerse(
      bookNumber: bookNumber,
      chapter: startChapter,
      verse: startVerse,
    );
    final mEnd = BibleVerseResolver.vulgateToMasoreticVerse(
      bookNumber: bookNumber,
      chapter: endChapter,
      verse: endVerse,
    );

    final String modernPart;
    if (mStart.chapter == mEnd.chapter && mStart.verse == mEnd.verse) {
      modernPart = '${mStart.chapter}:${mStart.verse}';
    } else if (mStart.chapter == mEnd.chapter) {
      modernPart = '${mStart.chapter}:${mStart.verse}-${mEnd.verse}';
    } else {
      modernPart =
          '${mStart.chapter}:${mStart.verse}$crossChapterSeparator${mEnd.chapter}:${mEnd.verse}';
    }

    if (numberingSystem == BibleNumberingSystem.modern) {
      return '$bookName $modernPart';
    }

    if (vulgatePart == modernPart) {
      return '$bookName $vulgatePart';
    }
    return '$bookName $vulgatePart (Modern $modernPart)';
  }

  /// Formats selected [verses] and their [citation] header for clipboard copy.
  static String formatVersesForClipboard({
    required String citation,
    required List<BibleVerse> verses,
    BibleNumberingSystem numberingSystem = BibleNumberingSystem.vulgate,
    int? fallbackBookNumber,
  }) {
    final count = verses.length;
    final versesText = verses
        .map((v) {
          if (count == 1) return v.verseText;
          final effectiveBookNumber = v.bookNumber > 0
              ? v.bookNumber
              : (fallbackBookNumber ?? v.bookNumber);
          final display = BibleVerseResolver.formatVerseDisplay(
            bookNumber: effectiveBookNumber,
            chapter: v.chapter,
            verseNumber: v.verseNumber,
            numberingSystem: numberingSystem,
          );
          final numLabel =
              display.alternateVerseNumber != null &&
                  display.alternateVerseNumber!.isNotEmpty
              ? '${display.displayVerseNumber} (${display.alternateVerseNumber})'
              : '${display.displayVerseNumber}';
          return '$numLabel ${v.verseText}';
        })
        .join(count == 1 ? '' : '\n');
    return '$citation\n$versesText';
  }

  /// Formats a human-readable citation label for a selected verse range.
  String formatSelectionCitation(
    int chapter,
    int startVerse,
    int endVerse, {
    BibleNumberingSystem numberingSystem = BibleNumberingSystem.vulgate,
  }) {
    return formatPassageCitation(
      bookNumber: bibleBook.bookNumber,
      bookName: bibleBook.bookName,
      startChapter: chapter,
      startVerse: startVerse,
      endChapter: chapter,
      endVerse: endVerse,
      numberingSystem: numberingSystem,
    );
  }

  /// Formats selected verses for clipboard copy.
  String formatClipboardContent(
    String citation,
    List<BibleVerse> selectedVerses, {
    BibleNumberingSystem numberingSystem = BibleNumberingSystem.vulgate,
  }) {
    return formatVersesForClipboard(
      citation: citation,
      verses: selectedVerses,
      numberingSystem: numberingSystem,
      fallbackBookNumber: bibleBook.bookNumber,
    );
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
