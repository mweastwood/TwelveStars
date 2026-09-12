import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_comments_view.dart';
import 'package:twelve_stars/widgets/library/library_favorites_view.dart';

class LibrarySavedSheet extends StatefulWidget {
  final ScrollController? scrollController;
  final List<LibraryBookItem>? catalog;
  final List<LibraryBookmark> favorites;
  final bool loadingFavorites;
  final List<UserComment> comments;
  final bool loadingComments;
  final VoidCallback? onFavoritesChanged;
  final VoidCallback? onCommentsChanged;
  final void Function(
    LibraryBookItem book, {
    String? volumeKey,
    String? assetPath,
    int? sectionIndex,
    int? itemIndex,
    int? questionNumber,
  })
  onOpenReader;

  const LibrarySavedSheet({
    super.key,
    this.scrollController,
    this.catalog,
    required this.favorites,
    required this.loadingFavorites,
    required this.comments,
    required this.loadingComments,
    this.onFavoritesChanged,
    this.onCommentsChanged,
    required this.onOpenReader,
  });

  @override
  State<LibrarySavedSheet> createState() => _LibrarySavedSheetState();
}

class _LibrarySavedSheetState extends State<LibrarySavedSheet> {
  late List<LibraryBookmark> _favorites;
  late List<UserComment> _comments;
  late bool _loadingFavorites;
  late bool _loadingComments;

  @override
  void initState() {
    super.initState();
    _favorites = List.from(widget.favorites);
    _comments = List.from(widget.comments);
    _loadingFavorites = widget.loadingFavorites;
    _loadingComments = widget.loadingComments;
  }

  Future<void> _refreshFavorites() async {
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
    widget.onFavoritesChanged?.call();
  }

  Future<void> _refreshComments() async {
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
    widget.onCommentsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
            child: Row(
              children: [
                Icon(
                  Icons.bookmarks_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Saved in Library',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Favorites'),
              Tab(text: 'Comments'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                LibraryFavoritesView(
                  catalog: widget.catalog,
                  favorites: _favorites,
                  isLoading: _loadingFavorites,
                  onRefresh: _refreshFavorites,
                  scrollController: widget.scrollController,
                  onOpenReader: widget.onOpenReader,
                ),
                LibraryCommentsView(
                  catalog: widget.catalog,
                  comments: _comments,
                  isLoading: _loadingComments,
                  onRefresh: _refreshComments,
                  scrollController: widget.scrollController,
                  onOpenReader: widget.onOpenReader,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
