import 'dart:math';
import 'package:drift/drift.dart' show Value;
import '../bible_database.dart';
import '../library_database.dart';
import 'reader_adapter.dart';
import 'reader_models.dart';
import 'reader_node_id.dart';

class LibraryReaderAdapter implements ReaderAdapter {
  final LibraryBookItem bookItem;
  final String assetPath;
  final String? volumeKey;
  final BibleDatabase dbHelper;

  LibraryReaderAdapter({
    required this.bookItem,
    required this.assetPath,
    this.volumeKey,
    BibleDatabase? dbHelper,
  }) : dbHelper = dbHelper ?? BibleDatabaseHelper.db;

  /// Resolves the initial volume key and asset path for [bookItem].
  static ({String? volumeKey, String? assetPath}) resolveInitialSource(
    LibraryBookItem bookItem, {
    String? initialVolumeKey,
    String? initialAssetPath,
  }) {
    if (bookItem.isSeries) {
      if (initialVolumeKey != null) {
        final selectedVol = bookItem.volumes!.firstWhere(
          (v) => v.volumeKey == initialVolumeKey,
          orElse: () => bookItem.volumes!.first,
        );
        return (
          volumeKey: selectedVol.volumeKey,
          assetPath: selectedVol.assetPath,
        );
      } else if (initialAssetPath != null) {
        final selectedVol = bookItem.volumes!.firstWhere(
          (v) => v.assetPath == initialAssetPath,
          orElse: () => bookItem.volumes!.first,
        );
        return (
          volumeKey: selectedVol.volumeKey,
          assetPath: selectedVol.assetPath,
        );
      } else {
        final firstVol = bookItem.volumes!.first;
        return (volumeKey: firstVol.volumeKey, assetPath: firstVol.assetPath);
      }
    }
    return (
      volumeKey: null,
      assetPath: initialAssetPath ?? bookItem.defaultAssetPath,
    );
  }

  /// Resolves the target 0-based section index within [data] from explicit
  /// navigation parameters or a persisted [savedPos].
  static int resolveInitialSectionIndex(
    ParsedBookData data, {
    required LibraryBookItem bookItem,
    String? currentVolumeKey,
    String? initialSectionId,
    int? initialSectionIndex,
    BookReadingPosition? savedPos,
    int fallbackIndex = 0,
  }) {
    int resolvedIndex = fallbackIndex;
    if (initialSectionId != null) {
      final idx = data.sections.indexWhere((s) => s.id == initialSectionId);
      if (idx >= 0) return idx;
    }
    if (initialSectionIndex != null) {
      return initialSectionIndex.clamp(0, max(0, data.sections.length - 1));
    } else if (savedPos != null) {
      final isMatchingVolume =
          !bookItem.isSeries ||
          savedPos.volumeKey == null ||
          savedPos.volumeKey == currentVolumeKey;
      if (isMatchingVolume) {
        if (savedPos.sectionId != null) {
          final idx = data.sections.indexWhere(
            (s) => s.id == savedPos.sectionId,
          );
          if (idx >= 0) {
            return idx;
          }
        }
        return savedPos.sectionIndex.clamp(0, max(0, data.sections.length - 1));
      }
    }
    return resolvedIndex;
  }

  /// Builds [ReaderTocEntry] items from [bookData].
  static List<ReaderTocEntry> buildTocEntries(ParsedBookData bookData) {
    if (bookData.sections.isNotEmpty) {
      return [
        for (int idx = 0; idx < bookData.sections.length; idx++)
          ReaderTocEntry(
            index: idx,
            title: bookData.sections[idx].title.isNotEmpty
                ? bookData.sections[idx].title
                : (idx < bookData.toc.length ? bookData.toc[idx].title : ''),
            subtitle: bookData.sections[idx].subtitle.isNotEmpty
                ? bookData.sections[idx].subtitle
                : null,
          ),
      ];
    }
    return [
      for (int idx = 0; idx < bookData.toc.length; idx++)
        ReaderTocEntry(index: idx, title: bookData.toc[idx].title),
    ];
  }

  /// Groups [comments] belonging to [sectionIndex] by their `nodeId`,
  /// filtering out comments from other volumes when [isSeries] is true.
  static Map<String, List<UserComment>> groupCommentsForSection(
    List<UserComment> comments,
    int sectionIndex, {
    String? currentVolumeKey,
    bool isSeries = false,
  }) {
    final sectionCommentsMap = <String, List<UserComment>>{};
    for (final c in comments) {
      if (c.sectionIndex == sectionIndex) {
        final (commentVolKey, _, _) = ReaderNodeId.parseLibrary(c.nodeId);
        if (isSeries &&
            currentVolumeKey != null &&
            commentVolKey != null &&
            commentVolKey != currentVolumeKey) {
          continue;
        }
        sectionCommentsMap.putIfAbsent(c.nodeId, () => []).add(c);
      }
    }
    return sectionCommentsMap;
  }

  /// Loads the parsed book data for [assetPath].
  Future<ParsedBookData> loadBookData() =>
      LibraryHelper.loadBookData(assetPath);

  /// Searches within [bookData] for [query].
  List<BookSearchResult> searchInBook(ParsedBookData bookData, String query) =>
      LibraryHelper.searchInBook(bookData, query)
          .map(
            (r) => BookSearchResult(
              bookTitle: r.bookTitle,
              sectionId: r.sectionId,
              sectionTitle: r.sectionTitle,
              matchedSnippet: r.matchedSnippet,
              bookId: r.bookId ?? bookItem.id,
              volumeKey: r.volumeKey ?? volumeKey,
              assetPath: r.assetPath ?? assetPath,
              itemIndex: r.itemIndex,
              questionNumber: r.questionNumber,
            ),
          )
          .toList();

  /// Loads the persisted reading position for [bookItem.id], if any.
  Future<BookReadingPosition?> getReadingPosition() async {
    try {
      return await dbHelper.getBookReadingPosition(bookItem.id);
    } catch (_) {
      return null;
    }
  }

  /// Persists the current reading position for [bookItem.id].
  Future<void> saveReadingPosition({
    required int sectionIndex,
    String? sectionId,
  }) async {
    try {
      await dbHelper.saveBookReadingPosition(
        bookId: bookItem.id,
        volumeKey: volumeKey,
        sectionIndex: sectionIndex,
        sectionId: sectionId,
      );
    } catch (_) {}
  }

  /// Loads raw [UserComment] records for [bookItem.id].
  Future<List<UserComment>> loadUserComments() async {
    try {
      return await dbHelper.getComments(documentId: bookItem.id);
    } catch (_) {
      return const [];
    }
  }

  /// Computes the formatted [citation] and [textPreview] for the selected
  /// item range `[startIndex, endIndex]` within [section].
  static ({String citation, String textPreview}) formatSectionSelection({
    required BookSection section,
    required int startIndex,
    required int endIndex,
    String? volumeTitle,
  }) {
    final trimmedVol = volumeTitle?.trim();
    final baseCitation = (trimmedVol != null && trimmedVol.isNotEmpty)
        ? '$trimmedVol, ${section.title}'
        : section.title;

    if (section.content.isEmpty) {
      return (citation: baseCitation, textPreview: '');
    }

    final maxIndex = section.content.length - 1;
    final clampedStart = min(startIndex, endIndex).clamp(0, maxIndex);
    final clampedEnd = max(startIndex, endIndex).clamp(0, maxIndex);
    final firstItem = section.content[clampedStart];
    final lastItem = section.content[clampedEnd];

    String citation = baseCitation;
    if (firstItem.questionNumber != null && lastItem.questionNumber != null) {
      if (firstItem.questionNumber == lastItem.questionNumber) {
        citation = '$baseCitation, Q. ${firstItem.questionNumber}';
      } else {
        final qMin = min(firstItem.questionNumber!, lastItem.questionNumber!);
        final qMax = max(firstItem.questionNumber!, lastItem.questionNumber!);
        citation = '$baseCitation, QQ. $qMin-$qMax';
      }
    } else if (clampedStart == clampedEnd && firstItem.questionNumber != null) {
      citation = '$baseCitation, Q. ${firstItem.questionNumber}';
    }

    final parts = <String>[];
    for (int i = clampedStart; i <= clampedEnd; i++) {
      final item = section.content[i];
      if (item.type == 'qa') {
        final q = item.question ?? '';
        final a = item.answer ?? '';
        parts.add('Q. $q\nA. $a');
      } else {
        parts.add(item.text ?? '');
      }
    }

    return (citation: citation, textPreview: parts.join('\n\n').trim());
  }

  /// Resolves the target content item index in [section] from an explicit
  /// [itemIndex] or by matching [questionNumber].
  static int? resolveTargetItemIndex(
    BookSection section, {
    int? itemIndex,
    int? questionNumber,
  }) {
    if (itemIndex != null) return itemIndex;
    if (questionNumber != null) {
      final idx = section.content.indexWhere(
        (it) => it.type == 'qa' && it.questionNumber == questionNumber,
      );
      if (idx >= 0) return idx;
    }
    return null;
  }

  /// Returns the display title for this book/volume (including series edition
  /// short name when applicable).
  String get resolvedVolumeTitle {
    if (bookItem.isSeries &&
        bookItem.volumes != null &&
        bookItem.volumes!.isNotEmpty) {
      final vol = bookItem.volumes!.firstWhere(
        (v) => v.volumeKey == volumeKey,
        orElse: () => bookItem.volumes!.first,
      );
      return '${bookItem.title} (${vol.shortName})';
    }
    return bookItem.title;
  }

  /// Builds a human-readable citation for the selected item range in [section].
  String buildItemCitation(BookSection section, int startIndex, int endIndex) {
    final baseTitle = resolvedVolumeTitle;

    if (section.content.isEmpty) {
      return '$baseTitle, ${section.title}';
    }

    final maxIndex = section.content.length - 1;
    final clampedStart = min(startIndex, endIndex).clamp(0, maxIndex);
    final clampedEnd = max(startIndex, endIndex).clamp(0, maxIndex);
    final startItem = section.content[clampedStart];
    final endItem = section.content[clampedEnd];

    if (startItem.type == 'qa' &&
        endItem.type == 'qa' &&
        startItem.questionNumber != null &&
        endItem.questionNumber != null) {
      if (startItem.questionNumber == endItem.questionNumber) {
        return '$baseTitle, ${section.title}, Q. ${startItem.questionNumber}';
      } else {
        final qMin = min(startItem.questionNumber!, endItem.questionNumber!);
        final qMax = max(startItem.questionNumber!, endItem.questionNumber!);
        return '$baseTitle, ${section.title}, Q. $qMin–$qMax';
      }
    }

    return '$baseTitle, ${section.title}';
  }

  /// Builds a plain-text preview for the selected item range in [section].
  String buildItemTextPreview(
    BookSection section,
    int startIndex,
    int endIndex,
  ) => formatSectionSelection(
    section: section,
    startIndex: startIndex,
    endIndex: endIndex,
  ).textPreview;

  @override
  Future<ReaderDocument> loadDocument() async {
    final data = await loadBookData();
    final toc = buildTocEntries(data);

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
    final data = await loadBookData();
    if (sectionIndex < 0 || sectionIndex >= data.sections.length) {
      throw RangeError('Section index out of bounds');
    }
    final section = data.sections[sectionIndex];

    final nodes = <ReaderContentNode>[];
    for (int i = 0; i < section.content.length; i++) {
      final item = section.content[i];
      final nodeType = item.type == 'qa'
          ? ReaderNodeType.qa
          : (item.type == 'heading'
                ? ReaderNodeType.heading
                : ReaderNodeType.paragraph);

      nodes.add(
        ReaderContentNode(
          id: ReaderNodeId.libraryItem(
            sectionId: section.id,
            itemIndex: i,
            volumeKey: volumeKey,
          ),
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

  Future<void> saveFavorite(ReaderBookmark bookmark) => saveBookmark(bookmark);

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    final docId = bookmark.documentId.isNotEmpty
        ? bookmark.documentId
        : bookItem.id;
    final existing = await dbHelper.getLibraryBookmarks(documentId: docId);
    if (existing.any((b) => b.nodeId == bookmark.nodeId)) {
      return;
    }
    await dbHelper.saveLibraryBookmark(
      LibraryBookmarksCompanion.insert(
        documentId: docId,
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
  Future<List<ReaderComment>> loadComments({
    String? nodeId,
    int? sectionIndex,
  }) async {
    final list = await dbHelper.getComments(
      documentId: bookItem.id,
      nodeId: nodeId,
      sectionIndex: sectionIndex,
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
