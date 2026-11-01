import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/bible_numbering_mapper.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/widgets/bible_annotation_card.dart';
import 'package:twelve_stars/widgets/bible_chapter_view.dart';
import 'package:twelve_stars/widgets/reader/bible_notes_filter_header.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';

export 'package:twelve_stars/widgets/bible_annotation_card.dart'
    show BibleAnnotationItem, BibleAnnotationType;
export 'package:twelve_stars/widgets/reader/bible_notes_filter_header.dart'
    show BibleNotesScope, BibleNotesFilterHeader;

class BibleNotesScreen extends StatefulWidget {
  static ValueNotifier<int> get annotationsRevision =>
      BibleChapterView.annotationsRevision;

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

class _BibleNotesScreenState extends State<BibleNotesScreen>
    with UserSettingsStateMixin<BibleNotesScreen> {
  List<FavoritePassage> _favorites = [];
  List<UserComment> _comments = [];
  List<BibleAnnotationItem> _cachedUnifiedItems = const [];
  bool _isLoading = true;
  bool _hasMutatedData = false;

  BibleBook? _activeBook;
  int? _activeChapter;
  late BibleNotesScope _scope;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  BibleAnnotationType? _selectedTypeFilter;

  BibleNumberingSystem get _numberingSystem =>
      currentSettings.bibleNumberingSystem;

  @override
  void onUserSettingsChanged(UserSettings settings) {
    setState(() {});
  }

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
    if (!_hasMutatedData &&
        widget.initialFavorites != null &&
        widget.initialComments != null) {
      setState(() {
        _favorites = List<FavoritePassage>.from(widget.initialFavorites!);
        _comments = widget.initialComments!
            .where(
              (c) => catholicBookAbbrevs.contains(c.documentId.toUpperCase()),
            )
            .toList();
        _recomputeUnifiedItems();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dbFavs = await BibleDatabaseHelper.db.getFavorites();
      final favs = _hasMutatedData
          ? (widget.initialFavorites == null || dbFavs.isNotEmpty
                ? dbFavs
                : _favorites)
          : (widget.initialFavorites != null
                ? List<FavoritePassage>.from(widget.initialFavorites!)
                : dbFavs);

      final dbComments = await BibleDatabaseHelper.db.getBibleComments();
      final bibleComments = _hasMutatedData
          ? (widget.initialComments == null || dbComments.isNotEmpty
                ? dbComments
                : _comments)
          : (widget.initialComments != null
                ? widget.initialComments!
                      .where(
                        (c) => catholicBookAbbrevs.contains(
                          c.documentId.toUpperCase(),
                        ),
                      )
                      .toList()
                : dbComments);

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
        setState(() {
          _recomputeUnifiedItems();
          _isLoading = false;
        });
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
      final verseNum = ReaderNodeId.parseBibleVerseNumber(comment.nodeId);

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
      final matchCitation =
          item
              .formatCitation(BibleNumberingSystem.vulgate)
              .toLowerCase()
              .contains(query) ||
          item
              .formatCitation(BibleNumberingSystem.modern)
              .toLowerCase()
              .contains(query) ||
          item
              .formatCitation(BibleNumberingSystem.dual)
              .toLowerCase()
              .contains(query);
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
    final verseNum = ReaderNodeId.parseBibleVerseNumber(comment.nodeId);
    final citation = BibleVerseResolver.formatVerseCitation(
      bookNumber: book.bookNumber,
      bookName: book.bookName,
      startChapter: comment.sectionIndex,
      startVerse: verseNum,
      numberingSystem: _numberingSystem,
    );

    await showEditCommentDialog(
      context: context,
      citation: citation,
      textPreview: comment.textPreview ?? '',
      commentId: comment.id,
      initialText: comment.commentText,
      onCommentUpdated: (updatedText) async {
        _hasMutatedData = true;
        _comments = _comments
            .map(
              (c) =>
                  c.id == comment.id ? c.copyWith(commentText: updatedText) : c,
            )
            .toList();
        await _loadData();
        BibleChapterView.annotationsRevision.value++;
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
      _favorites = _favorites.where((f) => f.id != item.favorite!.id).toList();
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
      _comments = _comments.where((c) => c.id != item.comment!.id).toList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted note on ${item.citation}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    _hasMutatedData = true;
    await _loadData();
    BibleChapterView.annotationsRevision.value++;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Bible Notes')),
      body: Column(
        children: [
          // 1. Search Bar & Filter Header
          BibleNotesFilterHeader(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (val) {
              setState(() => _searchQuery = val);
            },
            onSearchCleared: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            scope: _scope,
            activeBook: _activeBook,
            activeChapter: _activeChapter,
            numberingSystem: _numberingSystem,
            selectedTypeFilter: _selectedTypeFilter,
            favCount: favCount,
            noteCount: noteCount,
            allCount: allCount,
            bookCount: bookCount,
            chapterCount: chapterCount,
            onBookChanged: (newBook) {
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
            onChapterChanged: (newChapter) {
              setState(() {
                _activeChapter = newChapter;
                if (newChapter != null) {
                  _scope = BibleNotesScope.chapter;
                } else {
                  _scope = BibleNotesScope.book;
                }
              });
            },
            onSelectBibleScope: () {
              setState(() {
                _activeBook = null;
                _activeChapter = null;
                _scope = BibleNotesScope.all;
              });
            },
            onSelectBookScope: () {
              setState(() {
                _activeChapter = null;
                _scope = BibleNotesScope.book;
              });
            },
            onToggleTypeFilter: (type) {
              setState(() {
                if (_selectedTypeFilter == type) {
                  _selectedTypeFilter = null;
                } else {
                  _selectedTypeFilter = type;
                }
              });
            },
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

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    String subMessage;

    final typeLabel = switch (_selectedTypeFilter) {
      BibleAnnotationType.favorite => 'favorites',
      BibleAnnotationType.comment => 'notes',
      null => 'notes or favorites',
    };

    if (_searchQuery.isNotEmpty) {
      final searchTarget = switch (_selectedTypeFilter) {
        BibleAnnotationType.favorite => 'favorites',
        BibleAnnotationType.comment => 'notes',
        null => 'annotations',
      };
      message = 'No $searchTarget found matching "$_searchQuery"';
      subMessage = 'Try checking for typos or clear your search query.';
    } else if (_scope == BibleNotesScope.chapter &&
        _activeBook != null &&
        _activeChapter != null) {
      final chapterRef = BibleVerseResolver.formatChapterReference(
        bookNumber: _activeBook!.bookNumber,
        bookName: _activeBook!.bookName,
        chapter: _activeChapter!,
        numberingSystem: _numberingSystem,
      );
      message = 'No $typeLabel in $chapterRef.';
      subMessage =
          'Try switching to "${_activeBook!.bookName}" or "All Bible" above.';
    } else if (_scope == BibleNotesScope.book && _activeBook != null) {
      message = 'No $typeLabel in ${_activeBook!.bookName}.';
      subMessage = 'Try switching to "All Bible" or selecting another book.';
    } else if (_selectedTypeFilter == BibleAnnotationType.favorite) {
      message = 'No saved favorites yet.';
      subMessage =
          'Long-press any verse in the Bible reader to save passages to your favorites.';
    } else if (_selectedTypeFilter == BibleAnnotationType.comment) {
      message = 'No saved notes yet.';
      subMessage = 'Long-press any verse in the Bible reader to add notes.';
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

  Widget _buildAnnotationCard(BibleAnnotationItem item) {
    return BibleAnnotationCard(
      item: item,
      onOpen: () => _onOpenItem(item),
      onCopy: () => _copyItem(item),
      onEdit: item.comment != null ? () => _editComment(item.comment!) : null,
      onDelete: () => _deleteItem(item),
    );
  }

  Widget _buildSingleColumnLayout(List<BibleAnnotationItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildAnnotationCard(items[index]),
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
            child: Column(children: col1.map(_buildAnnotationCard).toList()),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(children: col2.map(_buildAnnotationCard).toList()),
          ),
        ],
      ),
    );
  }
}
