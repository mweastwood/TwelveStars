import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/thematic_bookmark_helper.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/website_viewer_screen.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import 'package:twelve_stars/widgets/thematic_quote_card.dart';
import 'package:twelve_stars/widgets/thematic_theme_picker_sheet.dart';

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
  List<LibraryBookmark> _bookmarks = [];
  int _loadGeneration = 0;

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

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await BibleDatabaseHelper.db.getLibraryBookmarks();
      if (!mounted) return;
      setState(() {
        _bookmarks = bookmarks;
      });
    } catch (_) {}
  }

  Future<void> _loadThemeData({bool reshuffle = true}) async {
    final generation = ++_loadGeneration;
    setState(() => _isLoading = true);
    final selectedTheme = _selectedThemeId;
    final counts = await ThematicHelper.getThemeCounts();
    final items = await ThematicHelper.getPassagesForTheme(
      selectedTheme,
      shuffle: reshuffle,
    );

    List<LibraryBookmark> bookmarks = _bookmarks;
    try {
      bookmarks = await BibleDatabaseHelper.db.getLibraryBookmarks();
    } catch (_) {}

    if (!mounted || generation != _loadGeneration) return;

    setState(() {
      _themeCounts = counts;
      _passages = items;
      _bookmarks = bookmarks;
      _currentIndex = 0;
      _isLoading = false;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
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
    try {
      final result = await ThematicBookmarkHelper.togglePassageBookmark(
        passage: passage,
        currentBookmarks: _bookmarks,
      );
      if (!mounted) return;
      setState(() {
        _bookmarks = result.updatedBookmarks;
      });
      if (result.isNowBookmarked) {
        HapticFeedback.lightImpact();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isNowBookmarked
                ? 'Saved to favorites! ❤️'
                : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
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
    final target = ThematicBookmarkHelper.resolveReaderLaunchTarget(
      passage,
      fallbackIfMissing: true,
    );
    if (target == null) return;
    final matchedBook = target.bookItem;

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
          initialVolumeKey: target.initialVolume?.volumeKey,
          initialAssetPath:
              target.initialVolume?.assetPath ?? matchedBook.defaultAssetPath,
          initialSectionId: target.initialSectionId,
          initialItemIndex: passage.itemIndex,
          initialQuestionNumber: target.initialQuestionNumber,
          navigationSessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ),
    ).then((_) => _loadBookmarks());
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

  void _showThemePickerSheet() {
    ThematicThemePickerSheet.show(
      context,
      selectedThemeId: _selectedThemeId,
      themeCounts: _themeCounts,
      onThemeSelected: _selectTheme,
    );
  }

  Widget _buildThemeSelectorButton(ThemeData theme, String themeTitle) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _showThemePickerSheet,
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
                  final isBookmarked =
                      ThematicBookmarkHelper.isPassageBookmarked(
                        passage,
                        _bookmarks,
                      );
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
              onPressed: _showThemePickerSheet,
              icon: const Icon(Icons.category_rounded),
              label: const Text('Change Theme'),
            ),
          ],
        ),
      ),
    );
  }
}
