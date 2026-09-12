import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import 'package:twelve_stars/widgets/library/library_catalog_view.dart';
import 'package:twelve_stars/widgets/library/library_saved_sheet.dart';
import 'package:twelve_stars/widgets/library/library_thematic_shelf.dart';
import 'package:twelve_stars/widgets/library/library_thematic_spark_card.dart';

class LibraryTabController {
  VoidCallback? _onShowSaved;

  void showSavedModalSheet() {
    _onShowSaved?.call();
  }

  void attach({required VoidCallback onShowSaved}) {
    _onShowSaved = onShowSaved;
  }

  void detach() {
    _onShowSaved = null;
  }
}

class LibraryTab extends StatefulWidget {
  static DateTime? mockNow;

  final LibraryTabController? controller;
  final List<LibraryBookItem>? catalog;

  const LibraryTab({super.key, this.controller, this.catalog});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  List<LibraryBookmark> _favorites = [];
  bool _loadingFavorites = true;

  List<UserComment> _comments = [];
  bool _loadingComments = true;

  BookReadingPosition? _latestReadingPosition;

  List<ThematicPassage> _allThematicPassages = [];
  ThematicPassage? _featuredPassage;

  List<LibraryBookItem> get _catalog =>
      widget.catalog ?? LibraryHelper.getCatalog();

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(onShowSaved: _showSavedModalSheet);
    _loadFavorites();
    _loadComments();
    _loadLatestReadingPosition();
    _loadThematicPassages();
  }

  @override
  void didUpdateWidget(covariant LibraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(onShowSaved: _showSavedModalSheet);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    super.dispose();
  }

  Future<void> _loadThematicPassages() async {
    try {
      final passages = await ThematicHelper.loadAllPassages();
      if (mounted) {
        setState(() {
          _allThematicPassages = passages;
          if (passages.isNotEmpty && _featuredPassage == null) {
            final now = LibraryTab.mockNow ?? DateTime.now();
            final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
            _featuredPassage = passages[dayOfYear % passages.length];
          }
        });
      }
    } catch (_) {}
  }

  void _shuffleFeaturedQuote() {
    if (_allThematicPassages.isEmpty) return;
    HapticFeedback.lightImpact();
    final random = ThematicHelper.mockRandom ?? Random();
    setState(() {
      _featuredPassage =
          _allThematicPassages[random.nextInt(_allThematicPassages.length)];
    });
  }

  bool _isPassageBookmarked(ThematicPassage passage) {
    final nodeId = '${passage.sectionId}_${passage.itemIndex}';
    return _favorites.any(
      (f) => f.documentId == passage.bookId && f.nodeId == nodeId,
    );
  }

  Future<void> _toggleFeaturedBookmark(ThematicPassage passage) async {
    final nodeId = '${passage.sectionId}_${passage.itemIndex}';
    final existing = _favorites
        .where((f) => f.documentId == passage.bookId && f.nodeId == nodeId)
        .firstOrNull;

    try {
      if (existing != null) {
        await BibleDatabaseHelper.db.deleteLibraryBookmark(existing.id);
        await _loadFavorites();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from saved bookmarks'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await BibleDatabaseHelper.db.saveLibraryBookmark(
          LibraryBookmarksCompanion.insert(
            documentId: passage.bookId,
            sectionIndex: 0,
            nodeId: nodeId,
            textPreview: passage.keyExcerpt.isNotEmpty
                ? passage.keyExcerpt
                : passage.oneSentenceSummary,
            createdAt: DateTime.now(),
          ),
        );
        HapticFeedback.lightImpact();
        await _loadFavorites();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to bookmarks ❤️'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _loadLatestReadingPosition() async {
    try {
      final pos = await BibleDatabaseHelper.db.getLatestBookReadingPosition();
      if (mounted) {
        setState(() {
          _latestReadingPosition = pos;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    setState(() => _loadingFavorites = true);
    try {
      final favs = await BibleDatabaseHelper.db.getLibraryBookmarks();
      if (mounted) {
        setState(() {
          _favorites = favs;
          _loadingFavorites = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final allComments = await BibleDatabaseHelper.db.getComments();
      final nonBibleComments = allComments
          .where((c) => !catholicBooks.any((b) => b.abbrev == c.documentId))
          .toList();
      if (mounted) {
        setState(() {
          _comments = nonBibleComments;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  void _openThemeBrowser({String? themeId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ThematicQuoteBrowserScreen(initialThemeId: themeId),
      ),
    ).then((_) {
      _loadFavorites();
      _loadComments();
      _loadLatestReadingPosition();
    });
  }

  void _openReaderForPassage(ThematicPassage passage) {
    final catalog = _catalog;
    LibraryBookItem? matchedBook;
    String? matchedVolumeKey;
    String? matchedAssetPath;

    for (final b in catalog) {
      if (b.id == passage.bookId) {
        matchedBook = b;
        break;
      }
      if (b.isSeries && b.volumes != null) {
        for (final v in b.volumes!) {
          if (v.volumeKey == passage.bookId ||
              v.assetPath == passage.bookId ||
              v.assetPath.endsWith('/${passage.bookId}.json') ||
              v.assetPath.contains(passage.bookId)) {
            matchedBook = b;
            matchedVolumeKey = v.volumeKey;
            matchedAssetPath = v.assetPath;
            break;
          }
        }
      }
      if (matchedBook != null) break;
    }

    if (matchedBook != null) {
      _openReader(
        context,
        matchedBook,
        volumeKey: matchedVolumeKey,
        assetPath: matchedAssetPath,
        sectionId: passage.sectionId,
        itemIndex: passage.itemIndex,
        questionNumber: passage.questionNumber,
      );
    }
  }

  Future<void> _openReader(
    BuildContext context,
    LibraryBookItem bookItem, {
    String? volumeKey,
    String? assetPath,
    String? sectionId,
    int? sectionIndex,
    int? questionNumber,
    int? itemIndex,
  }) async {
    String? targetVolumeKey = volumeKey;
    String? targetAssetPath = assetPath;
    String? targetSectionId = sectionId;
    int? targetSectionIndex = sectionIndex;

    if (volumeKey == null &&
        assetPath == null &&
        sectionId == null &&
        sectionIndex == null &&
        questionNumber == null &&
        itemIndex == null) {
      try {
        final savedPos = await BibleDatabaseHelper.db.getBookReadingPosition(
          bookItem.id,
        );
        if (savedPos != null) {
          if (bookItem.isSeries && savedPos.volumeKey != null) {
            final vol = bookItem.volumes?.firstWhere(
              (v) => v.volumeKey == savedPos.volumeKey,
              orElse: () => bookItem.volumes!.first,
            );
            if (vol != null) {
              targetVolumeKey = vol.volumeKey;
              targetAssetPath = vol.assetPath;
            }
          }
          targetSectionIndex = savedPos.sectionIndex;
          targetSectionId = savedPos.sectionId;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryReaderScreen(
          bookItem: bookItem,
          initialVolumeKey: targetVolumeKey,
          initialAssetPath: targetAssetPath,
          initialSectionId: targetSectionId,
          initialSectionIndex: targetSectionIndex,
          initialQuestionNumber: questionNumber,
          initialItemIndex: itemIndex,
          navigationSessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          onFavoriteSaved: _loadFavorites,
        ),
      ),
    ).then((_) {
      _loadFavorites();
      _loadComments();
      _loadLatestReadingPosition();
    });
  }

  void _showSavedModalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (childContext, scrollController) {
            return LibrarySavedSheet(
              scrollController: scrollController,
              catalog: _catalog,
              favorites: _favorites,
              loadingFavorites: _loadingFavorites,
              comments: _comments,
              loadingComments: _loadingComments,
              onFavoritesChanged: _loadFavorites,
              onCommentsChanged: _loadComments,
              onOpenReader:
                  (
                    book, {
                    volumeKey,
                    assetPath,
                    sectionIndex,
                    itemIndex,
                    questionNumber,
                  }) {
                    Navigator.of(sheetContext).pop();
                    if (!mounted) return;
                    _openReader(
                      context,
                      book,
                      volumeKey: volumeKey,
                      assetPath: assetPath,
                      sectionIndex: sectionIndex,
                      itemIndex: itemIndex,
                      questionNumber: questionNumber,
                    );
                  },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LibraryCatalogView(
      catalog: widget.catalog,
      latestReadingPosition: _latestReadingPosition,
      searchHintText: 'Search catechisms, library & topics...',
      searchTrailing: Badge(
        isLabelVisible: (_favorites.length + _comments.length) > 0,
        label: Text('${_favorites.length + _comments.length}'),
        child: IconButton.filledTonal(
          key: const Key('library_saved_button'),
          icon: const Icon(Icons.bookmarks_outlined),
          tooltip: 'Saved Passages & Notes',
          onPressed: _showSavedModalSheet,
        ),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_featuredPassage != null) ...[
            LibraryThematicSparkCard(
              passage: _featuredPassage!,
              isBookmarked: _isPassageBookmarked(_featuredPassage!),
              onShuffle: _shuffleFeaturedQuote,
              onToggleBookmark: () =>
                  _toggleFeaturedBookmark(_featuredPassage!),
              onOpenTheme: (themeId) => _openThemeBrowser(themeId: themeId),
              onOpenReader: () => _openReaderForPassage(_featuredPassage!),
            ),
            const SizedBox(height: 20),
          ],
          LibraryThematicShelf(
            onOpenTheme: (themeId) => _openThemeBrowser(themeId: themeId),
          ),
        ],
      ),
      onOpenReader:
          (
            book, {
            volumeKey,
            assetPath,
            sectionId,
            sectionIndex,
            questionNumber,
            itemIndex,
          }) => _openReader(
            context,
            book,
            volumeKey: volumeKey,
            assetPath: assetPath,
            sectionId: sectionId,
            sectionIndex: sectionIndex,
            questionNumber: questionNumber,
            itemIndex: itemIndex,
          ),
    );
  }
}
