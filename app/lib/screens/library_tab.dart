import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import 'package:twelve_stars/widgets/library/library_catalog_view.dart';
import 'package:twelve_stars/widgets/library/library_comments_view.dart';
import 'package:twelve_stars/widgets/library/library_favorites_view.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  List<LibraryBookmark> _favorites = [];
  bool _loadingFavorites = true;

  List<UserComment> _comments = [];
  bool _loadingComments = true;

  BookReadingPosition? _latestReadingPosition;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadComments();
    _loadLatestReadingPosition();
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Books'),
              Tab(text: 'Quotes & Themes'),
              Tab(text: 'Favorites'),
              Tab(text: 'Comments'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                LibraryCatalogView(
                  latestReadingPosition: _latestReadingPosition,
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
                ),
                const ThematicQuoteBrowserScreen(embedded: true),
                LibraryFavoritesView(
                  favorites: _favorites,
                  isLoading: _loadingFavorites,
                  onRefresh: _loadFavorites,
                  onOpenReader:
                      (
                        book, {
                        volumeKey,
                        assetPath,
                        sectionIndex,
                        itemIndex,
                        questionNumber,
                      }) => _openReader(
                        context,
                        book,
                        volumeKey: volumeKey,
                        assetPath: assetPath,
                        sectionIndex: sectionIndex,
                        itemIndex: itemIndex,
                        questionNumber: questionNumber,
                      ),
                ),
                LibraryCommentsView(
                  comments: _comments,
                  isLoading: _loadingComments,
                  onRefresh: _loadComments,
                  onOpenReader:
                      (
                        book, {
                        volumeKey,
                        assetPath,
                        sectionIndex,
                        itemIndex,
                        questionNumber,
                      }) => _openReader(
                        context,
                        book,
                        volumeKey: volumeKey,
                        assetPath: assetPath,
                        sectionIndex: sectionIndex,
                        itemIndex: itemIndex,
                        questionNumber: questionNumber,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
