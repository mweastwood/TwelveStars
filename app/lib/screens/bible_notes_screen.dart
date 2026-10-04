import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/widgets/bible_annotation_card.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';

enum BibleAnnotationType { favorite, comment }

enum BibleNotesScope { chapter, book, all }

class BibleAnnotationItem {
  final int bookNumber;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String textPreview;
  final BibleAnnotationType type;
  final FavoritePassage? favorite;
  final UserComment? comment;
  final DateTime createdAt;

  BibleAnnotationItem({
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.textPreview,
    required this.type,
    this.favorite,
    this.comment,
    required this.createdAt,
  });

  String get citation {
    if (type == BibleAnnotationType.favorite && startVerse != endVerse) {
      return '$bookName $chapter:$startVerse-$endVerse';
    }
    return '$bookName $chapter:$startVerse';
  }
}

class BibleNotesScreen extends StatefulWidget {
  final ValueChanged<FavoritePassage>? onSelectFavorite;
  final ValueChanged<UserComment>? onSelectComment;
  final VoidCallback? onFavoritesOrCommentsChanged;
  final List<FavoritePassage>? initialFavorites;
  final List<UserComment>? initialComments;
  final BibleBook? currentBook;
  final int? currentChapter;
  final BibleNotesScope? initialScope;

  const BibleNotesScreen({
    super.key,
    this.onSelectFavorite,
    this.onSelectComment,
    this.onFavoritesOrCommentsChanged,
    this.initialFavorites,
    this.initialComments,
    this.currentBook,
    this.currentChapter,
    this.initialScope,
  });

  @override
  State<BibleNotesScreen> createState() => _BibleNotesScreenState();
}

class _BibleNotesScreenState extends State<BibleNotesScreen> {
  List<FavoritePassage> _favorites = [];
  List<UserComment> _comments = [];
  List<BibleAnnotationItem> _cachedUnifiedItems = const [];
  bool _isLoading = true;

  BibleBook? _activeBook;
  int? _activeChapter;
  late BibleNotesScope _scope;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  BibleAnnotationType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _activeBook = widget.currentBook;
    _activeChapter = widget.currentChapter;
    _scope =
        widget.initialScope ??
        (_activeBook != null
            ? (_activeChapter != null
                  ? BibleNotesScope.chapter
                  : BibleNotesScope.book)
            : BibleNotesScope.all);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.initialFavorites != null && widget.initialComments != null) {
      setState(() {
        _favorites = widget.initialFavorites!;
        _comments = widget.initialComments!;
        _recomputeUnifiedItems();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final favs =
          widget.initialFavorites ??
          await BibleDatabaseHelper.db.getFavorites();
      final allComments =
          widget.initialComments ?? await BibleDatabaseHelper.db.getComments();

      // Only include comments on Bible verses (documentId matches a Bible book abbrev)
      final bibleComments = allComments.where((c) {
        return catholicBookAbbrevs.contains(c.documentId.toUpperCase());
      }).toList();

      if (mounted) {
        setState(() {
          _favorites = favs;
          _comments = bibleComments;
          _recomputeUnifiedItems();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _recomputeUnifiedItems() {
    final items = <BibleAnnotationItem>[];

    for (final fav in _favorites) {
      items.add(
        BibleAnnotationItem(
          bookNumber: fav.bookNumber,
          bookName: fav.bookName,
          chapter: fav.chapter,
          startVerse: fav.startVerse,
          endVerse: fav.endVerse,
          textPreview: fav.textPreview,
          type: BibleAnnotationType.favorite,
          favorite: fav,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    }

    for (final comment in _comments) {
      final book =
          catholicBooksByAbbrev[comment.documentId.toUpperCase()] ??
          catholicBooks.first;
      final verseNum = int.tryParse(comment.nodeId.split('_').last) ?? 1;

      items.add(
        BibleAnnotationItem(
          bookNumber: book.bookNumber,
          bookName: book.bookName,
          chapter: comment.sectionIndex,
          startVerse: verseNum,
          endVerse: verseNum,
          textPreview: comment.textPreview ?? '',
          type: BibleAnnotationType.comment,
          comment: comment,
          createdAt: comment.createdAt,
        ),
      );
    }

    // Canonical biblical order sorting (Book 1..73, Chapter, Verse, Type)
    items.sort((a, b) {
      if (a.bookNumber != b.bookNumber) {
        return a.bookNumber.compareTo(b.bookNumber);
      }
      if (a.chapter != b.chapter) {
        return a.chapter.compareTo(b.chapter);
      }
      if (a.startVerse != b.startVerse) {
        return a.startVerse.compareTo(b.startVerse);
      }
      if (a.endVerse != b.endVerse) {
        return a.endVerse.compareTo(b.endVerse);
      }
      return a.type.index.compareTo(b.type.index);
    });

    _cachedUnifiedItems = items;
  }

  bool _matchesScope(
    BibleAnnotationItem item, [
    BibleNotesScope? scopeOverride,
  ]) {
    final scope = scopeOverride ?? _scope;
    if (_activeBook == null) {
      return scope == BibleNotesScope.all;
    }
    switch (scope) {
      case BibleNotesScope.chapter:
        return _activeChapter != null &&
            item.bookNumber == _activeBook!.bookNumber &&
            item.chapter == _activeChapter;
      case BibleNotesScope.book:
        return item.bookNumber == _activeBook!.bookNumber;
      case BibleNotesScope.all:
        return true;
    }
  }

  List<BibleAnnotationItem> _getFilteredItems([
    List<BibleAnnotationItem>? items,
  ]) {
    final unified = items ?? _cachedUnifiedItems;
    final query = _searchQuery.trim().toLowerCase();

    return unified.where((item) {
      if (_selectedTypeFilter != null && item.type != _selectedTypeFilter) {
        return false;
      }

      if (!_matchesScope(item)) {
        return false;
      }

      if (query.isEmpty) return true;

      final matchBook = item.bookName.toLowerCase().contains(query);
      final matchCitation = item.citation.toLowerCase().contains(query);
      final matchPreview = item.textPreview.toLowerCase().contains(query);
      final matchComment =
          item.comment != null &&
          item.comment!.commentText.toLowerCase().contains(query);

      return matchBook || matchCitation || matchPreview || matchComment;
    }).toList();
  }

  void _onOpenItem(BibleAnnotationItem item) {
    if (item.type == BibleAnnotationType.favorite && item.favorite != null) {
      if (widget.onSelectFavorite != null) {
        widget.onSelectFavorite!(item.favorite!);
      } else {
        Navigator.pop(context, item.favorite);
      }
    } else if (item.type == BibleAnnotationType.comment &&
        item.comment != null) {
      if (widget.onSelectComment != null) {
        widget.onSelectComment!(item.comment!);
      } else {
        Navigator.pop(context, item.comment);
      }
    }
  }

  Future<void> _copyItem(BibleAnnotationItem item) async {
    final buffer = StringBuffer(item.citation);
    if (item.textPreview.isNotEmpty) {
      buffer.write('\n"${item.textPreview}"');
    }
    if (item.comment != null) {
      buffer.write('\nNote: ${item.comment!.commentText}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied ${item.citation} to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editComment(UserComment comment) async {
    final book =
        catholicBooksByAbbrev[comment.documentId.toUpperCase()] ??
        catholicBooks.first;
    final verseNum = int.tryParse(comment.nodeId.split('_').last) ?? 1;
    final citation = '${book.bookName} ${comment.sectionIndex}:$verseNum';

    await showEditCommentDialog(
      context: context,
      citation: citation,
      textPreview: comment.textPreview ?? '',
      commentId: comment.id,
      initialText: comment.commentText,
      onCommentUpdated: (_) async {
        await _loadData();
        widget.onFavoritesOrCommentsChanged?.call();
      },
    );
  }

  Future<void> _deleteItem(BibleAnnotationItem item) async {
    final isFav = item.type == BibleAnnotationType.favorite;
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: isFav ? 'Remove Favorite' : 'Delete Comment',
      content: isFav
          ? 'Are you sure you want to remove "${item.citation}" from your favorites?'
          : 'Are you sure you want to delete your note on ${item.citation}?',
      confirmLabel: isFav ? 'Remove' : 'Delete',
    );
    if (!confirmed || !mounted) return;

    if (item.type == BibleAnnotationType.favorite && item.favorite != null) {
      await BibleDatabaseHelper.db.deleteFavorite(item.favorite!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${item.citation} from Favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (item.type == BibleAnnotationType.comment &&
        item.comment != null) {
      await BibleDatabaseHelper.db.deleteComment(item.comment!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted note on ${item.citation}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    await _loadData();
    widget.onFavoritesOrCommentsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = isWideScreen(context);
    final unified = _cachedUnifiedItems;
    final filteredItems = _getFilteredItems(unified);

    // Scope counts (respecting _showFavorites / _showComments)
    int chapterCount = 0;
    int bookCount = 0;
    int allCount = 0;

    for (final item in unified) {
      final matchesType =
          _selectedTypeFilter == null || item.type == _selectedTypeFilter;
      if (!matchesType) continue;

      if (_matchesScope(item, BibleNotesScope.all)) {
        allCount++;
      }
      if (_matchesScope(item, BibleNotesScope.book)) {
        bookCount++;
      }
      if (_matchesScope(item, BibleNotesScope.chapter)) {
        chapterCount++;
      }
    }

    // Type counts (respecting active scope)
    int favCount = 0;
    int noteCount = 0;

    for (final item in unified) {
      if (!_matchesScope(item)) continue;

      if (item.type == BibleAnnotationType.favorite) {
        favCount++;
      } else if (item.type == BibleAnnotationType.comment) {
        noteCount++;
      }
    }

    final isChapterDropdownDisabled =
        _scope == BibleNotesScope.all || _activeBook == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Bible Notes')),
      body: Column(
        children: [
          // 1. Search Bar & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Search Bar
                TextField(
                  key: const Key('bible_notes_search_field'),
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search notes, favorites, or verses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),

                // 2. Book & Chapter Dropdowns
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BibleBook?>(
                            key: const Key('bible_notes_book_dropdown'),
                            value: _scope == BibleNotesScope.all
                                ? null
                                : _activeBook,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            hint: const Text('All Books'),
                            items: [
                              const DropdownMenuItem<BibleBook?>(
                                value: null,
                                child: Text('All Books'),
                              ),
                              ...catholicBooks.map(
                                (book) => DropdownMenuItem<BibleBook?>(
                                  value: book,
                                  child: Text(
                                    book.bookName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (newBook) {
                              setState(() {
                                _activeBook = newBook;
                                if (newBook != null) {
                                  _activeChapter = null;
                                  _scope = BibleNotesScope.book;
                                } else {
                                  _activeChapter = null;
                                  _scope = BibleNotesScope.all;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(
                                alpha: isChapterDropdownDisabled ? 0.2 : 0.5,
                              ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            key: const Key('bible_notes_chapter_dropdown'),
                            value: _scope == BibleNotesScope.chapter
                                ? _activeChapter
                                : null,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            hint: const Text('Chapter'),
                            disabledHint: Text(
                              'Chapter',
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            items: isChapterDropdownDisabled
                                ? null
                                : [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('All Chapters'),
                                    ),
                                    ...List.generate(
                                      _activeBook!.chaptersCount,
                                      (index) => DropdownMenuItem<int?>(
                                        value: index + 1,
                                        child: Text('Ch. ${index + 1}'),
                                      ),
                                    ),
                                  ],
                            onChanged: isChapterDropdownDisabled
                                ? null
                                : (newChapter) {
                                    setState(() {
                                      _activeChapter = newChapter;
                                      if (newChapter != null) {
                                        _scope = BibleNotesScope.chapter;
                                      } else {
                                        _scope = BibleNotesScope.book;
                                      }
                                    });
                                  },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // 3 & 4. Breadcrumb Scope Path & Type Selector
                _buildBreadcrumbPath(
                  theme,
                  favCount: favCount,
                  noteCount: noteCount,
                  allCount: allCount,
                  bookCount: bookCount,
                  chapterCount: chapterCount,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                ? _buildEmptyState(theme)
                : isWide
                ? _buildMasonryWideLayout(filteredItems)
                : _buildSingleColumnLayout(filteredItems),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbPath(
    ThemeData theme, {
    required int favCount,
    required int noteCount,
    required int allCount,
    required int bookCount,
    required int chapterCount,
  }) {
    final canWalkToBible = _scope != BibleNotesScope.all;
    final canWalkToBook = _scope == BibleNotesScope.chapter;

    return SingleChildScrollView(
      key: const Key('bible_notes_scope_segmented_button'),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Bible Crumb
          Tooltip(
            message: 'All Bible ($allCount)',
            child: InkWell(
              key: const Key('breadcrumb_bible'),
              borderRadius: BorderRadius.circular(8),
              onTap: canWalkToBible
                  ? () {
                      setState(() {
                        _activeBook = null;
                        _activeChapter = null;
                        _scope = BibleNotesScope.all;
                      });
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: _scope == BibleNotesScope.all
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bible',
                      style: TextStyle(
                        fontWeight: _scope == BibleNotesScope.all
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _scope == BibleNotesScope.all
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.primary,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Book Crumb
          if (_activeBook != null && _scope != BibleNotesScope.all) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ),
            Tooltip(
              message: '${_activeBook!.bookName} ($bookCount)',
              child: InkWell(
                key: const Key('breadcrumb_book'),
                borderRadius: BorderRadius.circular(8),
                onTap: canWalkToBook
                    ? () {
                        setState(() {
                          _activeChapter = null;
                          _scope = BibleNotesScope.book;
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    _activeBook!.bookName,
                    style: TextStyle(
                      fontWeight: _scope == BibleNotesScope.book
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: _scope == BibleNotesScope.book
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.primary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 3. Chapter Crumb
          if (_activeChapter != null && _scope == BibleNotesScope.chapter) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ),
            Tooltip(
              message: 'Chapter $_activeChapter ($chapterCount)',
              child: InkWell(
                key: const Key('breadcrumb_chapter'),
                borderRadius: BorderRadius.circular(8),
                onTap: null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    'Chapter $_activeChapter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.outline,
            ),
          ),

          // 4. Favorites & Notes Chips
          FilterChip(
            key: const Key('filter_favorites_chip'),
            showCheckmark: false,
            avatar: Icon(
              _selectedTypeFilter == BibleAnnotationType.favorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 16,
              color: _selectedTypeFilter == BibleAnnotationType.favorite
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.outline,
            ),
            label: Text('Favorites ($favCount)'),
            selected: _selectedTypeFilter == BibleAnnotationType.favorite,
            onSelected: (_) {
              setState(() {
                if (_selectedTypeFilter == BibleAnnotationType.favorite) {
                  _selectedTypeFilter = null;
                } else {
                  _selectedTypeFilter = BibleAnnotationType.favorite;
                }
              });
            },
          ),
          const SizedBox(width: 8.0),
          FilterChip(
            key: const Key('filter_notes_chip'),
            showCheckmark: false,
            avatar: Icon(
              _selectedTypeFilter == BibleAnnotationType.comment
                  ? Icons.comment_rounded
                  : Icons.comment_outlined,
              size: 16,
              color: _selectedTypeFilter == BibleAnnotationType.comment
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.outline,
            ),
            label: Text('Notes ($noteCount)'),
            selected: _selectedTypeFilter == BibleAnnotationType.comment,
            onSelected: (_) {
              setState(() {
                if (_selectedTypeFilter == BibleAnnotationType.comment) {
                  _selectedTypeFilter = null;
                } else {
                  _selectedTypeFilter = BibleAnnotationType.comment;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subMessage;

    if (_searchQuery.isNotEmpty) {
      message = 'No annotations found matching "$_searchQuery"';
      subMessage = 'Try checking for typos or clear your search query.';
    } else if (_scope == BibleNotesScope.chapter &&
        _activeBook != null &&
        _activeChapter != null) {
      message =
          'No notes or favorites in ${_activeBook!.bookName} $_activeChapter.';
      subMessage =
          'Try switching to "${_activeBook!.bookName}" or "All Bible" above.';
    } else if (_scope == BibleNotesScope.book && _activeBook != null) {
      message = 'No notes or favorites in ${_activeBook!.bookName}.';
      subMessage = 'Try switching to "All Bible" or selecting another book.';
    } else {
      message = 'No saved favorites or notes yet.';
      subMessage =
          'Long-press any verse in the Bible reader to add notes or save passages to your favorites.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.edit_note_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleColumnLayout(List<BibleAnnotationItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return BibleAnnotationCard(
          item: item,
          onOpen: () => _onOpenItem(item),
          onCopy: () => _copyItem(item),
          onEdit: item.comment != null
              ? () => _editComment(item.comment!)
              : null,
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }

  Widget _buildMasonryWideLayout(List<BibleAnnotationItem> items) {
    final col1 = <BibleAnnotationItem>[];
    final col2 = <BibleAnnotationItem>[];

    for (int i = 0; i < items.length; i++) {
      if (i % 2 == 0) {
        col1.add(items[i]);
      } else {
        col2.add(items[i]);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: col1
                  .map(
                    (item) => BibleAnnotationCard(
                      item: item,
                      onOpen: () => _onOpenItem(item),
                      onCopy: () => _copyItem(item),
                      onEdit: item.comment != null
                          ? () => _editComment(item.comment!)
                          : null,
                      onDelete: () => _deleteItem(item),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              children: col2
                  .map(
                    (item) => BibleAnnotationCard(
                      item: item,
                      onOpen: () => _onOpenItem(item),
                      onCopy: () => _copyItem(item),
                      onEdit: item.comment != null
                          ? () => _editComment(item.comment!)
                          : null,
                      onDelete: () => _deleteItem(item),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
