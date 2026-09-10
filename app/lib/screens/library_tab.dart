import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

class LibraryTab extends StatefulWidget {
  static DateTime? mockNow;

  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => LibraryTabState();
}

class LibraryTabState extends State<LibraryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchingGlobal = false;
  List<BookSearchResult> _globalSearchResults = [];
  int _searchSessionId = 0;

  List<LibraryBookmark> _favorites = [];
  bool _loadingFavorites = true;
  String _selectedFavoriteBookId = 'all';

  List<UserComment> _comments = [];
  bool _loadingComments = true;
  String _selectedCommentBookId = 'all';

  List<ThematicPassage> _allThematicPassages = [];
  ThematicPassage? _featuredPassage;

  BookReadingPosition? _latestReadingPosition;
  String _selectedCategory = 'All';

  List<String> get _categories => [
    'All',
    ...{for (final b in LibraryHelper.getCatalog()) b.category},
  ];

  static const List<(String label, String themeId)> _quickTopics = [
    ('🕊️ Eucharist', 'sacraments.eucharist'),
    ('🕯️ Mental Prayer', 'prayer.vocal_mental_meditation'),
    ('⚔️ Spiritual Warfare', 'combat.spiritual_warfare'),
    ('👑 Our Lady', 'devotion.our_lady'),
    ('🌿 Humility', 'virtues.humility_meekness'),
    ('🕊️ Confession', 'sacraments.penance'),
    ('⚔️ Suffering & Cross', 'combat.suffering_cross'),
    ('🏛️ Holy Trinity', 'theology.trinity'),
    ('🌿 Faith, Hope & Charity', 'virtues.faith_hope_charity'),
    ('👑 Heaven & Eternity', 'eschatology.heaven_beatific_vision'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadComments();
    _loadLatestReadingPosition();
    _loadThematicPassages();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          if (_selectedFavoriteBookId != 'all' &&
              !favs.any((f) => f.documentId == _selectedFavoriteBookId)) {
            _selectedFavoriteBookId = 'all';
          }
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
          if (_selectedCommentBookId != 'all' &&
              !nonBibleComments.any(
                (c) => c.documentId == _selectedCommentBookId,
              )) {
            _selectedCommentBookId = 'all';
          }
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _performGlobalSearch(String query) async {
    final sessionId = ++_searchSessionId;
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      setState(() {
        _globalSearchResults = [];
        _isSearchingGlobal = false;
      });
      return;
    }

    setState(() {
      _isSearchingGlobal = true;
    });

    final allResults = await LibraryHelper.searchCatalog(cleanQuery);

    if (mounted && sessionId == _searchSessionId) {
      setState(() {
        _globalSearchResults = allResults;
        _isSearchingGlobal = false;
      });
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

  void _openReaderForPassage(ThematicPassage passage) {
    final catalog = LibraryHelper.getCatalog();
    LibraryBookItem? matchedBook;
    String? matchedVolumeKey;
    String? matchedAssetPath;

    for (final b in catalog) {
      if (b.id == passage.bookId) {
        matchedBook = b;
        matchedAssetPath = b.defaultAssetPath;
        break;
      }
      if (b.defaultAssetPath != null &&
          (b.defaultAssetPath == passage.bookId ||
              b.defaultAssetPath!.endsWith('/${passage.bookId}.json') ||
              b.defaultAssetPath!.contains(passage.bookId))) {
        matchedBook = b;
        matchedAssetPath = b.defaultAssetPath;
        break;
      }
      if (b.volumes != null) {
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

  void _showAllThemesPicker(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Explore by Spiritual Theme',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${ThematicHelper.allThemes.length} Themes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: ThematicHelper.categoryGroups.length,
                    itemBuilder: (ctx, idx) {
                      final group = ThematicHelper.categoryGroups[idx];
                      return ExpansionTile(
                        initiallyExpanded: idx == 0,
                        leading: Text(
                          group.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          group.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: group.themes.entries.map((entry) {
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              entry.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openThemeBrowser(themeId: entry.key);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showSavedModalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return _LibrarySavedSheet(
              scrollController: scrollController,
              favorites: _favorites,
              loadingFavorites: _loadingFavorites,
              selectedFavoriteBookId: _selectedFavoriteBookId,
              comments: _comments,
              loadingComments: _loadingComments,
              selectedCommentBookId: _selectedCommentBookId,
              onDeleteFavorite: (id) async {
                await BibleDatabaseHelper.db.deleteLibraryBookmark(id);
                await _loadFavorites();
              },
              onDeleteComment: (id) async {
                await BibleDatabaseHelper.db.deleteComment(id);
                await _loadComments();
              },
              onSelectFavoriteBookId: (id) {
                setState(() => _selectedFavoriteBookId = id);
              },
              onSelectCommentBookId: (id) {
                setState(() => _selectedCommentBookId = id);
              },
              onOpenReader: _openReader,
              parseNodeId: _parseNodeId,
            );
          },
        );
      },
    );
  }

  (String? volKey, int? itemIdx, int? qNum) _parseNodeId(String nodeId) {
    String? volumeKey;
    int? itemIndex;
    int? questionNumber;

    String cleanNodeId = nodeId;
    if (nodeId.contains(':')) {
      final parts = nodeId.split(':');
      volumeKey = parts.first;
      cleanNodeId = parts.sublist(1).join(':');
    }

    if (cleanNodeId.contains('_')) {
      final lastPart = cleanNodeId.split('_').last;
      if (lastPart.startsWith('q')) {
        questionNumber = int.tryParse(lastPart.substring(1));
      } else {
        itemIndex = int.tryParse(lastPart);
      }
    } else if (cleanNodeId.contains('-')) {
      final lastPart = cleanNodeId.split('-').last;
      itemIndex = int.tryParse(lastPart);
    }

    return (volumeKey, itemIndex, questionNumber);
  }

  Widget _buildDailyQuoteCard(ThemeData theme, ThematicPassage passage) {
    final isBookmarked = _isPassageBookmarked(passage);
    final themeTitle = ThematicHelper.getThemeTitle(passage.primaryTheme);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Spark Label + Theme Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "TODAY'S THEMATIC SPARK",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openThemeBrowser(themeId: passage.primaryTheme),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            themeTitle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quote text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 28,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    passage.keyExcerpt.isNotEmpty
                        ? passage.keyExcerpt
                        : passage.fullText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'serif',
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Summary / Insight box
            if (passage.oneSentenceSummary.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        passage.oneSentenceSummary,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Attribution & Actions Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (passage.authorSaintId != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () async {
                            final saint = await SaintDatabase.getSaintById(
                              passage.authorSaintId!,
                            );
                            if (mounted && saint != null) {
                              SaintDetailsSheet.show(context, saint);
                            }
                          },
                          child: Text(
                            '— ${passage.author}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Text(
                          '— ${passage.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        passage.bookTitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Shuffle reflection',
                  icon: const Icon(Icons.shuffle_rounded, size: 20),
                  onPressed: _shuffleFeaturedQuote,
                ),
                IconButton(
                  tooltip: isBookmarked
                      ? 'Remove bookmark'
                      : 'Bookmark reflection',
                  icon: Icon(
                    isBookmarked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isBookmarked
                        ? Colors.redAccent
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => _toggleFeaturedBookmark(passage),
                ),
              ],
            ),
            const Divider(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        _openThemeBrowser(themeId: passage.primaryTheme),
                    icon: const Icon(Icons.style_rounded, size: 18),
                    label: const Text('Swipe Theme'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openReaderForPassage(passage),
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Read in Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThematicShelf(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.explore_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'EXPLORE BY THEME',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showAllThemesPicker(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('All Themes (${ThematicHelper.allThemes.length})'),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Swipe through curated quotations by sacrament, virtue, & doctrine',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // 7 Category Pillars Horizontal List
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ThematicHelper.categoryGroups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final group = ThematicHelper.categoryGroups[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    _openThemeBrowser(themeId: group.themes.keys.first),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${group.themes.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        group.name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Quick Topic Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickTopics.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: const Icon(Icons.label_outline_rounded, size: 14),
                  label: Text(item.$1),
                  onPressed: () => _openThemeBrowser(themeId: item.$2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingHero(
    ThemeData theme,
    List<LibraryBookItem> catalog,
  ) {
    if (_latestReadingPosition == null) return const SizedBox.shrink();

    final book = catalog
        .where((b) => b.id == _latestReadingPosition!.bookId)
        .firstOrNull;
    if (book == null) return const SizedBox.shrink();

    String? volumeName;
    String? volumeAssetPath;
    if (book.isSeries && _latestReadingPosition!.volumeKey != null) {
      final vol = book.volumes
          ?.where((v) => v.volumeKey == _latestReadingPosition!.volumeKey)
          .firstOrNull;
      if (vol != null) {
        volumeName = vol.name;
        volumeAssetPath = vol.assetPath;
      }
    }

    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark_added_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'CONTINUE READING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (volumeName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          volumeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'Section ${_latestReadingPosition!.sectionIndex + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _openReader(
                    context,
                    book,
                    volumeKey: _latestReadingPosition!.volumeKey,
                    assetPath: volumeAssetPath,
                    sectionIndex: _latestReadingPosition!.sectionIndex,
                    sectionId: _latestReadingPosition!.sectionId,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Resume'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Apostolic Fathers':
        return Icons.history_edu_rounded;
      case 'Early Apologists':
        return Icons.shield_outlined;
      case 'Church Fathers':
        return Icons.church_rounded;
      case 'Patristics':
        return Icons.account_balance_rounded;
      case 'Doctors of the Church':
      case 'Doctors of the Church / Spiritual Classics':
        return Icons.school_rounded;
      case 'Marian & Spiritual Classics':
        return Icons.flare_rounded;
      case 'Monastic & Spiritual Classics':
        return Icons.cottage_rounded;
      case 'Spiritual Classics':
        return Icons.self_improvement_rounded;
      case 'Catechisms':
      default:
        return Icons.menu_book_rounded;
    }
  }

  void _showVolumePickerModal(BuildContext context, LibraryBookItem bookItem) {
    if (bookItem.volumes == null || bookItem.volumes!.isEmpty) return;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookItem.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select from ${bookItem.volumes!.length} volumes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: bookItem.volumes!.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final vol = bookItem.volumes![idx];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            (idx + 1).toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          vol.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: vol.description.isNotEmpty
                            ? Text(
                                vol.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openReader(
                            context,
                            bookItem,
                            volumeKey: vol.volumeKey,
                            assetPath: vol.assetPath,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = LibraryHelper.getCatalog();
    final displayedBooks = _selectedCategory == 'All'
        ? catalog
        : catalog.where((b) => b.category == _selectedCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Search Bar + Saved Button
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search catechisms, library & topics...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                              _performGlobalSearch(val);
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _globalSearchResults = [];
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: (_favorites.length + _comments.length) > 0,
                label: Text('${_favorites.length + _comments.length}'),
                child: IconButton.filledTonal(
                  key: const Key('library_saved_button'),
                  icon: const Icon(Icons.bookmarks_outlined),
                  tooltip: 'Saved Passages & Notes',
                  onPressed: showSavedModalSheet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Results View if Searching
          if (_searchQuery.trim().isNotEmpty) ...[
            Text(
              'SEARCH RESULTS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            if (_isSearchingGlobal)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_globalSearchResults.isEmpty)
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No search results found for "$_searchQuery".',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              ...() {
                final Map<String, List<BookSearchResult>> groups = {};
                for (final res in _globalSearchResults) {
                  groups.putIfAbsent(res.bookTitle, () => []).add(res);
                }

                return groups.entries.map((entry) {
                  final bookTitle = entry.key;
                  final results = entry.value;
                  final matchingBook = catalog.firstWhere(
                    (b) => b.title == bookTitle,
                    orElse: () => catalog.first,
                  );
                  final categoryIcon = _getCategoryIcon(matchingBook.category);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                categoryIcon,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bookTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${results.length} ${results.length == 1 ? 'match' : 'matches'}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...results.map((res) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _openReader(
                                context,
                                matchingBook,
                                sectionId: res.sectionId,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 4.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.sectionTitle,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.secondary,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      res.matchedSnippet,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                });
              }(),
            ],
            const SizedBox(height: 80),
          ] else ...[
            // 1. Today's Thematic Reflection (Hero Quote Card)
            if (_featuredPassage != null) ...[
              _buildDailyQuoteCard(theme, _featuredPassage!),
              const SizedBox(height: 20),
            ],

            // 2. Explore by Theme Section
            _buildThematicShelf(theme),
            const SizedBox(height: 20),

            // 3. Continue Reading Hero Card if available
            if (_latestReadingPosition != null) ...[
              _buildContinueReadingHero(theme, catalog),
              const SizedBox(height: 16),
            ],

            // 4. Complete Works & Tradition Header
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory == 'All'
                      ? 'CATECHISMS & DOCTRINE'
                      : _selectedCategory.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${displayedBooks.length} ${displayedBooks.length == 1 ? 'WORK' : 'WORKS'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Catalog Book Cards
            ...displayedBooks.map((bookItem) {
              final categoryIcon = _getCategoryIcon(bookItem.category);

              return Card(
                key: ValueKey('book_card_${bookItem.id}'),
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              categoryIcon,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookItem.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bookItem.subtitle,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (bookItem.authorSaintId != null)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () async {
                                      final saint =
                                          await SaintDatabase.getSaintById(
                                            bookItem.authorSaintId!,
                                          );
                                      if (mounted &&
                                          context.mounted &&
                                          saint != null) {
                                        SaintDetailsSheet.show(context, saint);
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'By ${bookItem.author}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    'By ${bookItem.author}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                // Metadata Badges
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  children: [
                                    if (bookItem.era != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .secondaryContainer
                                              .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          bookItem.era!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        bookItem.isSeries
                                            ? '${bookItem.volumes!.length} Volumes'
                                            : 'COMPLETE WORK',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bookItem.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Volume chips if series, or Read Book button if single book
                      if (bookItem.isSeries) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Volume (${bookItem.volumes!.length}):',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              icon: const Icon(Icons.layers_outlined, size: 16),
                              label: const Text('Browse All ▾'),
                              onPressed: () =>
                                  _showVolumePickerModal(context, bookItem),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 6.0,
                          children: bookItem.volumes!.map((vol) {
                            return ActionChip(
                              avatar: Icon(
                                Icons.bookmark_border,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(vol.name),
                              onPressed: () => _openReader(
                                context,
                                bookItem,
                                volumeKey: vol.volumeKey,
                                assetPath: vol.assetPath,
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.menu_book, size: 18),
                            label: const Text('Read Book'),
                            onPressed: () => _openReader(context, bookItem),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }
}

class _LibrarySavedSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<LibraryBookmark> favorites;
  final bool loadingFavorites;
  final String selectedFavoriteBookId;
  final List<UserComment> comments;
  final bool loadingComments;
  final String selectedCommentBookId;
  final Future<void> Function(int id) onDeleteFavorite;
  final Future<void> Function(int id) onDeleteComment;
  final ValueChanged<String> onSelectFavoriteBookId;
  final ValueChanged<String> onSelectCommentBookId;
  final void Function(
    BuildContext context,
    LibraryBookItem bookItem, {
    String? volumeKey,
    String? assetPath,
    String? sectionId,
    int? sectionIndex,
    int? questionNumber,
    int? itemIndex,
  })
  onOpenReader;
  final (String?, int?, int?) Function(String nodeId) parseNodeId;

  const _LibrarySavedSheet({
    required this.scrollController,
    required this.favorites,
    required this.loadingFavorites,
    required this.selectedFavoriteBookId,
    required this.comments,
    required this.loadingComments,
    required this.selectedCommentBookId,
    required this.onDeleteFavorite,
    required this.onDeleteComment,
    required this.onSelectFavoriteBookId,
    required this.onSelectCommentBookId,
    required this.onOpenReader,
    required this.parseNodeId,
  });

  @override
  State<_LibrarySavedSheet> createState() => _LibrarySavedSheetState();
}

class _LibrarySavedSheetState extends State<_LibrarySavedSheet> {
  late String _currentFavoriteBookId;
  late String _currentCommentBookId;
  late List<LibraryBookmark> _favorites;
  late List<UserComment> _comments;

  @override
  void initState() {
    super.initState();
    _favorites = List.from(widget.favorites);
    _comments = List.from(widget.comments);
    _currentFavoriteBookId = widget.selectedFavoriteBookId;
    _currentCommentBookId = widget.selectedCommentBookId;
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
              children: [_buildFavoritesList(theme), _buildCommentsList(theme)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(ThemeData theme) {
    if (widget.loadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_outline,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No favorite passages saved in Library yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the heart icon on any reflection or long-press in a book.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final catalog = LibraryHelper.getCatalog();
    final distinctBookIds = _favorites
        .map((f) => f.documentId)
        .toSet()
        .toList();

    final filteredFavorites = _currentFavoriteBookId == 'all'
        ? _favorites
        : _favorites
              .where((f) => f.documentId == _currentFavoriteBookId)
              .toList();

    return Column(
      children: [
        if (distinctBookIds.length > 1) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _currentFavoriteBookId == 'all',
                      label: Text('All (${_favorites.length})'),
                      onSelected: (val) {
                        setState(() {
                          _currentFavoriteBookId = 'all';
                        });
                        widget.onSelectFavoriteBookId('all');
                      },
                    ),
                  ),
                  ...distinctBookIds.map((bookId) {
                    final book = catalog
                        .where((b) => b.id == bookId)
                        .firstOrNull;
                    final bookTitle = book?.title ?? bookId;
                    final count = _favorites
                        .where((f) => f.documentId == bookId)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: _currentFavoriteBookId == bookId,
                        label: Text('$bookTitle ($count)'),
                        onSelected: (val) {
                          final selectedId = val ? bookId : 'all';
                          setState(() {
                            _currentFavoriteBookId = selectedId;
                          });
                          widget.onSelectFavoriteBookId(selectedId);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: filteredFavorites.length,
            itemBuilder: (context, index) {
              final fav = filteredFavorites[index];
              final parts = fav.textPreview.split('\n');
              final citation = parts.first;
              final preview = parts.length > 1
                  ? parts.sublist(1).join(' ')
                  : '';

              final (volKey, itemIdx, qNum) = widget.parseNodeId(fav.nodeId);
              final book = catalog
                  .where((b) => b.id == fav.documentId)
                  .firstOrNull;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    citation,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  subtitle: preview.isNotEmpty
                      ? Text(
                          preview,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () {
                      setState(() {
                        _favorites.removeWhere((f) => f.id == fav.id);
                      });
                      widget.onDeleteFavorite(fav.id);
                    },
                  ),
                  onTap: () {
                    if (book == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Book not found in library'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    String? targetAssetPath;
                    String? targetVolKey = volKey;
                    if (book.isSeries && book.volumes != null) {
                      final match =
                          book.volumes!
                              .where((v) => v.volumeKey == volKey)
                              .firstOrNull ??
                          book.volumes!.firstOrNull;
                      if (match != null) {
                        targetVolKey = match.volumeKey;
                        targetAssetPath = match.assetPath;
                      }
                    }

                    Navigator.pop(context);
                    widget.onOpenReader(
                      context,
                      book,
                      volumeKey: targetVolKey,
                      assetPath: targetAssetPath,
                      sectionIndex: fav.sectionIndex,
                      itemIndex: itemIdx,
                      questionNumber: qNum,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsList(ThemeData theme) {
    if (widget.loadingComments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No comments on library books yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Long-press on a passage, then tap Comment to add a note.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final catalog = LibraryHelper.getCatalog();
    final distinctBookIds = _comments.map((c) => c.documentId).toSet().toList();

    final filteredComments = _currentCommentBookId == 'all'
        ? _comments
        : _comments
              .where((c) => c.documentId == _currentCommentBookId)
              .toList();

    return Column(
      children: [
        if (distinctBookIds.length > 1) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _currentCommentBookId == 'all',
                      label: Text('All (${_comments.length})'),
                      onSelected: (val) {
                        setState(() {
                          _currentCommentBookId = 'all';
                        });
                        widget.onSelectCommentBookId('all');
                      },
                    ),
                  ),
                  ...distinctBookIds.map((bookId) {
                    final book = catalog
                        .where((b) => b.id == bookId)
                        .firstOrNull;
                    final bookTitle = book?.title ?? bookId;
                    final count = _comments
                        .where((f) => f.documentId == bookId)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: _currentCommentBookId == bookId,
                        label: Text('$bookTitle ($count)'),
                        onSelected: (val) {
                          final selectedId = val ? bookId : 'all';
                          setState(() {
                            _currentCommentBookId = selectedId;
                          });
                          widget.onSelectCommentBookId(selectedId);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: filteredComments.length,
            itemBuilder: (context, index) {
              final comment = filteredComments[index];
              final (volKey, itemIdx, qNum) = widget.parseNodeId(
                comment.nodeId,
              );
              final book = catalog
                  .where((b) => b.id == comment.documentId)
                  .firstOrNull;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    comment.commentText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (comment.textPreview != null &&
                          comment.textPreview!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          comment.textPreview!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        book?.title ?? comment.documentId,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Comment'),
                          content: const Text(
                            'Are you sure you want to delete this comment?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                setState(() {
                                  _comments.removeWhere(
                                    (c) => c.id == comment.id,
                                  );
                                });
                                await widget.onDeleteComment(comment.id);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    if (book == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Book not found in library'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    String? targetAssetPath;
                    String? targetVolKey = volKey;
                    if (book.isSeries && book.volumes != null) {
                      final match =
                          book.volumes!
                              .where((v) => v.volumeKey == volKey)
                              .firstOrNull ??
                          book.volumes!.firstOrNull;
                      if (match != null) {
                        targetVolKey = match.volumeKey;
                        targetAssetPath = match.assetPath;
                      }
                    }

                    Navigator.pop(context);
                    widget.onOpenReader(
                      context,
                      book,
                      volumeKey: targetVolKey,
                      assetPath: targetAssetPath,
                      sectionIndex: comment.sectionIndex,
                      itemIndex: itemIdx,
                      questionNumber: qNum,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
