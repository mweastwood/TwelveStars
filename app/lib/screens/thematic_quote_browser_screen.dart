import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/website_viewer_screen.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import 'package:twelve_stars/widgets/thematic_quote_card.dart';

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
  final Map<String, int> _bookmarkedIds = {};

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
        _bookmarkedIds['${b.documentId}_${b.nodeId}'] = b.id;
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

  List<String> _bookmarkKeysForPassage(ThematicPassage passage) {
    final target = LibraryCatalog.resolveTarget(bookId: passage.bookId);
    final legacyNodeId = '${passage.sectionId}_${passage.itemIndex}';
    final canonicalNodeId = ReaderNodeId.libraryItem(
      sectionId: passage.sectionId,
      itemIndex: passage.itemIndex,
      volumeKey: target?.volumeKey,
    );
    final keys = <String>{
      '${passage.bookId}_$legacyNodeId',
      '${passage.bookId}_$canonicalNodeId',
      if (target != null) ...[
        '${target.book.id}_$legacyNodeId',
        '${target.book.id}_$canonicalNodeId',
      ],
    };
    return keys.toList();
  }

  Future<void> _toggleBookmark(ThematicPassage passage) async {
    final target = LibraryCatalog.resolveTarget(bookId: passage.bookId);
    final legacyNodeId = '${passage.sectionId}_${passage.itemIndex}';
    final canonicalNodeId = ReaderNodeId.libraryItem(
      sectionId: passage.sectionId,
      itemIndex: passage.itemIndex,
      volumeKey: target?.volumeKey,
    );
    final candidateKeys = _bookmarkKeysForPassage(passage);
    final matchingKey = candidateKeys
        .where(_bookmarkedIds.containsKey)
        .firstOrNull;
    final isBookmarked = matchingKey != null;

    try {
      if (isBookmarked) {
        final existingId = _bookmarkedIds[matchingKey];
        if (existingId != null) {
          await BibleDatabaseHelper.db.deleteLibraryBookmark(existingId);
        } else {
          final bookmarks = await BibleDatabaseHelper.db.getLibraryBookmarks(
            documentId: passage.bookId,
          );
          final match = bookmarks
              .where(
                (b) => b.nodeId == canonicalNodeId || b.nodeId == legacyNodeId,
              )
              .firstOrNull;
          if (match != null) {
            await BibleDatabaseHelper.db.deleteLibraryBookmark(match.id);
          }
        }
        if (!mounted) return;
        setState(() {
          for (final k in candidateKeys) {
            _bookmarkedIds.remove(k);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        int resolvedSectionIndex = 0;
        if (target?.assetPath != null) {
          final cachedBook = LibraryHelper.getCachedBookData(
            target!.assetPath!,
          );
          if (cachedBook != null) {
            final idx = cachedBook.sections.indexWhere(
              (s) => s.id == passage.sectionId,
            );
            if (idx >= 0) resolvedSectionIndex = idx;
          }
        }
        final citation = passage.sectionTitle.isNotEmpty
            ? '${passage.bookTitle} — ${passage.sectionTitle}'
            : passage.bookTitle;
        final excerpt = passage.keyExcerpt.isNotEmpty
            ? passage.keyExcerpt
            : passage.oneSentenceSummary;
        final newId = await BibleDatabaseHelper.db.saveLibraryBookmark(
          LibraryBookmarksCompanion.insert(
            documentId: passage.bookId,
            sectionIndex: resolvedSectionIndex,
            nodeId: canonicalNodeId,
            textPreview: '$citation\n$excerpt',
            createdAt: DateTime.now(),
          ),
        );
        if (!mounted) return;
        setState(
          () => _bookmarkedIds['${passage.bookId}_$canonicalNodeId'] = newId,
        );
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to favorites! ❤️'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update bookmark'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openReaderContext(ThematicPassage passage) {
    final target =
        LibraryCatalog.resolveTarget(bookId: passage.bookId) ??
        LibraryCatalog.buildFallbackTarget(
          bookId: passage.bookId,
          bookTitle: passage.bookTitle,
          author: passage.author,
          authorSaintId: passage.authorSaintId,
        );
    final matchedBook = target.book;

    if (matchedBook.isWeb && matchedBook.webUrl != null) {
      final bookTitle = matchedBook.title;
      final bookUrl = matchedBook.webUrl!;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WebsiteViewerScreen(title: bookTitle, url: bookUrl),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryReaderScreen(
          bookItem: matchedBook,
          initialVolumeKey: target.volumeKey,
          initialAssetPath: target.assetPath,
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
                  final passage = _passages[index];
                  final isBookmarked = _bookmarkKeysForPassage(
                    passage,
                  ).any(_bookmarkedIds.containsKey);
                  return ThematicQuoteCard(
                    passage: passage,
                    isBookmarked: isBookmarked,
                    onToggleBookmark: () => _toggleBookmark(passage),
                    onOpenReaderContext: () => _openReaderContext(passage),
                    onShowSaintDetails: _showSaintSheet,
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
}
