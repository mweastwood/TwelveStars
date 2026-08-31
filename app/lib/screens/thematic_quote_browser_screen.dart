import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

class ThematicQuoteBrowserScreen extends StatefulWidget {
  final String? initialThemeId;
  final bool embedded;

  const ThematicQuoteBrowserScreen({
    super.key,
    this.initialThemeId,
    this.embedded = false,
  });

  @override
  State<ThematicQuoteBrowserScreen> createState() =>
      _ThematicQuoteBrowserScreenState();
}

class _ThematicQuoteBrowserScreenState
    extends State<ThematicQuoteBrowserScreen> {
  late String _selectedThemeId;
  late PageController _pageController;
  List<ThematicPassage> _passages = [];
  Map<String, int> _themeCounts = {};
  bool _isLoading = true;
  int _currentIndex = 0;
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.initialThemeId ?? 'sacraments.eucharist';
    _pageController = PageController();
    _loadThemeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadThemeData({bool reshuffle = true}) async {
    setState(() => _isLoading = true);
    final counts = await ThematicHelper.getThemeCounts();
    final items = await ThematicHelper.getPassagesForTheme(
      _selectedThemeId,
      shuffle: reshuffle,
    );

    // Check existing bookmarks
    try {
      final bookmarks = await BibleDatabaseHelper.db.getLibraryBookmarks();
      _bookmarkedIds.clear();
      for (final b in bookmarks) {
        _bookmarkedIds.add('${b.documentId}_${b.nodeId}');
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _themeCounts = counts;
        _passages = items;
        _currentIndex = 0;
        _isLoading = false;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  void _selectTheme(String themeId) {
    if (_selectedThemeId == themeId) return;
    setState(() {
      _selectedThemeId = themeId;
    });
    _loadThemeData(reshuffle: true);
  }

  Future<void> _toggleBookmark(ThematicPassage passage) async {
    final nodeId = '${passage.sectionId}_${passage.itemIndex}';
    final key = '${passage.bookId}_$nodeId';
    final isBookmarked = _bookmarkedIds.contains(key);

    try {
      if (isBookmarked) {
        final bookmarks = await BibleDatabaseHelper.db.getLibraryBookmarks();
        final match = bookmarks
            .where((b) => b.documentId == passage.bookId && b.nodeId == nodeId)
            .firstOrNull;
        if (match != null) {
          await BibleDatabaseHelper.db.deleteLibraryBookmark(match.id);
        }
        setState(() => _bookmarkedIds.remove(key));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
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
        setState(() => _bookmarkedIds.add(key));
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to favorites! ❤️'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _openReaderContext(ThematicPassage passage) {
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

    if (matchedBook == null) {
      // Robust category inference for non-catechism passages (e.g. Fathers, Doctors, Scriptures)
      String inferredCategory = 'Theology';
      final lowerTitle = passage.bookTitle.toLowerCase();
      final lowerAuthor = passage.author.toLowerCase();
      final lowerId = passage.bookId.toLowerCase();

      if (lowerTitle.contains('catechism') ||
          lowerId.contains('baltimore') ||
          lowerId.contains('trent')) {
        inferredCategory = 'Catechisms';
      } else if (lowerAuthor.contains('apostolic') ||
          lowerId.contains('didache') ||
          lowerId.contains('clement') ||
          lowerId.contains('ignatius') ||
          lowerId.contains('polycarp') ||
          lowerId.contains('diognetus')) {
        inferredCategory = 'Apostolic Fathers';
      } else if (lowerAuthor.contains('augustine') ||
          lowerAuthor.contains('chrysostom') ||
          lowerAuthor.contains('athanasius') ||
          lowerAuthor.contains('ambrose') ||
          lowerAuthor.contains('basil') ||
          lowerAuthor.contains('gregory') ||
          lowerAuthor.contains('jerome') ||
          lowerAuthor.contains('cyprian') ||
          lowerAuthor.contains('cyril') ||
          lowerAuthor.contains('damascene') ||
          lowerAuthor.contains('irenaeus') ||
          lowerAuthor.contains('justin')) {
        inferredCategory = 'Early Church Fathers';
      } else if (lowerAuthor.contains('aquinas') ||
          lowerAuthor.contains('anselm') ||
          lowerAuthor.contains('bonaventure') ||
          lowerAuthor.contains('teresa') ||
          lowerAuthor.contains('john of the cross') ||
          lowerAuthor.contains('francis de sales')) {
        inferredCategory = 'Doctor of the Church';
      }

      String assetPath = passage.bookId;
      if (!assetPath.startsWith('assets/')) {
        if (!assetPath.endsWith('.json')) {
          assetPath = 'assets/catechism/json/$assetPath.json';
        } else {
          assetPath = 'assets/catechism/json/$assetPath';
        }
      }

      matchedBook = LibraryBookItem(
        id: passage.bookId,
        title: passage.bookTitle,
        subtitle: '',
        category: inferredCategory,
        author: passage.author,
        authorSaintId: passage.authorSaintId,
        description: '',
        defaultAssetPath: assetPath,
      );
      matchedAssetPath = assetPath;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryReaderScreen(
          bookItem: matchedBook!,
          initialVolumeKey: matchedVolumeKey,
          initialAssetPath: matchedAssetPath,
          initialSectionId: passage.sectionId,
          initialItemIndex: passage.itemIndex,
          initialQuestionNumber: passage.questionNumber,
          navigationSessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ),
    );
  }

  void _showSaintSheet(String saintId) async {
    try {
      final saint = await SaintDatabase.getSaintById(saintId);
      if (saint != null && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SaintDetailsSheet(saint: saint),
        );
      }
    } catch (_) {}
  }

  void _showThemePickerSheet(ThemeData theme) {
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
                        'Select Theme',
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
                        initiallyExpanded: group.themes.containsKey(
                          _selectedThemeId,
                        ),
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
                          final isSelected = entry.key == _selectedThemeId;
                          final count = _themeCounts[entry.key] ?? 0;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: theme
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              entry.value,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _selectTheme(entry.key);
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

  Widget _buildThemeSelectorButton(ThemeData theme, String themeTitle) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showThemePickerSheet(theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                themeTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeTitle = ThematicHelper.getThemeTitle(_selectedThemeId);

    final bodyContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _passages.isEmpty
        ? _buildEmptyState(theme)
        : Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _passages.length,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                },
                itemBuilder: (context, index) {
                  return _buildInstagramQuoteCard(
                    theme,
                    _passages[index],
                    index,
                    _passages.length,
                  );
                },
              ),
              // Counter Pill top-right
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${_passages.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildThemeSelectorButton(theme, themeTitle),
                  ),
                ),
                IconButton(
                  tooltip: 'Reshuffle Quotes',
                  icon: const Icon(Icons.shuffle_rounded),
                  onPressed: () => _loadThemeData(reshuffle: true),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: bodyContent),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildThemeSelectorButton(theme, themeTitle),
        actions: [
          IconButton(
            tooltip: 'Reshuffle Quotes',
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: () => _loadThemeData(reshuffle: true),
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Quotes Available for this Theme',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try picking another category or dispatch subagents to index more books.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showThemePickerSheet(theme),
              icon: const Icon(Icons.category_rounded),
              label: const Text('Change Theme'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstagramQuoteCard(
    ThemeData theme,
    ThematicPassage passage,
    int index,
    int total,
  ) {
    final nodeId = '${passage.sectionId}_${passage.itemIndex}';
    final isBookmarked = _bookmarkedIds.contains('${passage.bookId}_$nodeId');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Source Title + Bookmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passage.bookTitle.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          passage.sectionTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isBookmarked
                          ? Colors.redAccent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _toggleBookmark(passage),
                  ),
                ],
              ),

              const Divider(height: 20),

              // Quote Body & Insight Excerpt
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 36,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        passage.keyExcerpt.isNotEmpty
                            ? passage.keyExcerpt
                            : passage.fullText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'serif',
                          fontSize: 19,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Insight / Summary Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                passage.oneSentenceSummary,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Author attribution and Jump Link
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: passage.authorSaintId != null
                          ? () => _showSaintSheet(passage.authorSaintId!)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                passage.author,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: passage.authorSaintId != null
                                      ? TextDecoration.underline
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => _openReaderContext(passage),
                    icon: const Icon(Icons.auto_stories_rounded, size: 16),
                    label: const Text('Read in Context'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
