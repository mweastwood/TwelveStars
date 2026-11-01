import 'dart:math';

import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/thematic_database.dart';

class ThematicBookmarkHelper {
  const ThematicBookmarkHelper._();

  /// Selects the deterministic daily featured passage for [date].
  static ThematicPassage selectDailyFeaturedPassage(
    List<ThematicPassage> passages,
    DateTime date,
  ) {
    if (passages.isEmpty) {
      throw ArgumentError.value(passages, 'passages', 'Must not be empty');
    }
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = ThematicHelper.mockRandom ?? Random(seed);
    return passages[random.nextInt(passages.length)];
  }

  /// Returns all candidate `(docId, nodeId)` bookmark key pairs (covering both
  /// raw passage `bookId` and canonical catalog `book.id`, as well as legacy
  /// and canonical `ReaderNodeId` formats) for [passage].
  static List<({String docId, String nodeId})> bookmarkKeysForPassage(
    ThematicPassage passage, {
    List<LibraryBookItem>? catalog,
  }) {
    final target = LibraryCatalog.resolveTarget(
      bookId: passage.bookId,
      catalog: catalog,
    );
    final legacyNodeId = '${passage.sectionId}_${passage.itemIndex}';
    final canonicalNodeId = ReaderNodeId.libraryItem(
      sectionId: passage.sectionId,
      itemIndex: passage.itemIndex,
      volumeKey: target?.volumeKey,
    );
    final docIds = <String>{passage.bookId, if (target != null) target.book.id};
    final nodeIds = <String>{legacyNodeId, canonicalNodeId};
    return [
      for (final docId in docIds)
        for (final nodeId in nodeIds) (docId: docId, nodeId: nodeId),
    ];
  }

  /// Returns `true` if any bookmark in [bookmarks] matches [passage].
  static bool isPassageBookmarked(
    ThematicPassage passage,
    Iterable<LibraryBookmark> bookmarks, {
    List<LibraryBookItem>? catalog,
  }) {
    final keys = bookmarkKeysForPassage(passage, catalog: catalog);
    return bookmarks.any(
      (b) => keys.any((k) => k.docId == b.documentId && k.nodeId == b.nodeId),
    );
  }

  /// Resolves the 0-based section index for [passage] from cached or loaded
  /// book JSON at [assetPath], defaulting to `0` on timeout or lookup miss.
  static Future<int> resolveSectionIndex(
    ThematicPassage passage,
    String? assetPath,
  ) async {
    if (assetPath == null || assetPath.isEmpty) return 0;
    try {
      final cachedBook =
          LibraryHelper.getCachedBookData(assetPath) ??
          await LibraryHelper.loadBookData(
            assetPath,
          ).timeout(const Duration(milliseconds: 100));
      final idx = cachedBook.sections.indexWhere(
        (s) => s.id == passage.sectionId,
      );
      if (idx >= 0) return idx;
    } catch (_) {}
    return 0;
  }

  /// Toggles the bookmark state for [passage] in [BibleDatabaseHelper.db].
  ///
  /// If any bookmark in [currentBookmarks] matches [passage]'s legacy or
  /// canonical keys, all matching bookmarks are deleted; otherwise a new
  /// canonical bookmark is inserted. Returns the new bookmarked status and
  /// refreshed list of bookmarks.
  static Future<
    ({bool isNowBookmarked, List<LibraryBookmark> updatedBookmarks})
  >
  togglePassageBookmark({
    required ThematicPassage passage,
    required List<LibraryBookmark> currentBookmarks,
    List<LibraryBookItem>? catalog,
  }) async {
    final target = LibraryCatalog.resolveTarget(
      bookId: passage.bookId,
      catalog: catalog,
    );
    final keys = bookmarkKeysForPassage(passage, catalog: catalog);
    final matching = currentBookmarks
        .where(
          (b) =>
              keys.any((k) => k.docId == b.documentId && k.nodeId == b.nodeId),
        )
        .toList();

    if (matching.isNotEmpty) {
      for (final existing in matching) {
        await BibleDatabaseHelper.db.deleteLibraryBookmark(existing.id);
      }
      final updated = await BibleDatabaseHelper.db.getLibraryBookmarks();
      return (isNowBookmarked: false, updatedBookmarks: updated);
    } else {
      final resolvedSectionIndex = await resolveSectionIndex(
        passage,
        target?.assetPath,
      );
      final effectiveDocumentId = target?.book.id ?? passage.bookId;
      final canonicalNodeId = ReaderNodeId.libraryItem(
        sectionId: passage.sectionId,
        itemIndex: passage.itemIndex,
        volumeKey: target?.volumeKey,
      );
      final citation = passage.sectionTitle.isNotEmpty
          ? '${passage.bookTitle} — ${passage.sectionTitle}'
          : passage.bookTitle;
      final excerpt = passage.keyExcerpt.isNotEmpty
          ? passage.keyExcerpt
          : passage.oneSentenceSummary;
      await BibleDatabaseHelper.db.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: effectiveDocumentId,
          sectionIndex: resolvedSectionIndex,
          nodeId: canonicalNodeId,
          textPreview: '$citation\n$excerpt',
          createdAt: DateTime.now(),
        ),
      );
      final updated = await BibleDatabaseHelper.db.getLibraryBookmarks();
      return (isNowBookmarked: true, updatedBookmarks: updated);
    }
  }

  /// Resolves the reader launch target for [passage], optionally building a
  /// fallback book item when [fallbackIfMissing] is `true`.
  static ({
    LibraryBookItem bookItem,
    BaltimoreVolume? initialVolume,
    String initialSectionId,
    int? initialQuestionNumber,
  })?
  resolveReaderLaunchTarget(
    ThematicPassage passage, {
    List<LibraryBookItem>? catalog,
    bool fallbackIfMissing = false,
  }) {
    var target = LibraryCatalog.resolveTarget(
      bookId: passage.bookId,
      catalog: catalog,
    );
    if (target == null && fallbackIfMissing) {
      target = LibraryCatalog.buildFallbackTarget(
        bookId: passage.bookId,
        bookTitle: passage.bookTitle,
        author: passage.author,
        authorSaintId: passage.authorSaintId,
      );
    }
    if (target == null) return null;

    return (
      bookItem: target.book,
      initialVolume: target.volume,
      initialSectionId: passage.sectionId,
      initialQuestionNumber: passage.questionNumber,
    );
  }
}
