import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayers.dart';

class BibleBottomNavigationPanel extends StatelessWidget {
  final Animation<double> panelHeightAnimation;
  final bool isPanelExpanded;
  final BibleBook currentBook;
  final int currentChapter;
  final BibleNumberingSystem numberingSystem;
  final TabController sheetTabController;
  final BibleBook selectedBookForPicker;
  final ValueChanged<BibleBook> onBookSelectedForPicker;
  final void Function(BibleBook book, int chapter) onChapterSelected;
  final List<FavoritePassage> favorites;
  final bool loadingFavorites;
  final ValueChanged<FavoritePassage> onFavoriteTapped;
  final ValueChanged<FavoritePassage> onDeleteFavorite;
  final List<UserComment> comments;
  final bool loadingComments;
  final ValueChanged<UserComment> onCommentTapped;
  final ValueChanged<UserComment> onEditComment;
  final ValueChanged<UserComment> onDeleteComment;
  final VoidCallback onTogglePanel;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  const BibleBottomNavigationPanel({
    super.key,
    required this.panelHeightAnimation,
    required this.isPanelExpanded,
    required this.currentBook,
    required this.currentChapter,
    required this.numberingSystem,
    required this.sheetTabController,
    required this.selectedBookForPicker,
    required this.onBookSelectedForPicker,
    required this.onChapterSelected,
    required this.favorites,
    required this.loadingFavorites,
    required this.onFavoriteTapped,
    required this.onDeleteFavorite,
    required this.comments,
    required this.loadingComments,
    required this.onCommentTapped,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.onTogglePanel,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  Widget _buildBookGroup(
    BuildContext context,
    String title,
    List<BibleBook> books,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: books.map((book) {
              final isSelected =
                  selectedBookForPicker.bookNumber == book.bookNumber;
              return ChoiceChip(
                label: Text(book.bookName),
                selected: isSelected,
                onSelected: (selected) {
                  onBookSelectedForPicker(book);
                  sheetTabController.animateTo(1); // Switch to Chapter tab
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context, ThemeData theme) {
    if (loadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (favorites.isEmpty) {
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
                'No favorite passages saved yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Long-press on a verse to start selection, then save.',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final fav = favorites[index];
        final citation = fav.startVerse == fav.endVerse
            ? '${fav.bookName} ${fav.chapter}:${fav.startVerse}'
            : '${fav.bookName} ${fav.chapter}:${fav.startVerse}-${fav.endVerse}';

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
            subtitle: Text(
              fav.textPreview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () => onDeleteFavorite(fav),
            ),
            onTap: () => onFavoriteTapped(fav),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab(BuildContext context, ThemeData theme) {
    if (loadingComments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (comments.isEmpty) {
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
                'No comments on Bible verses yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Long-press on a verse, then tap Comment to add a note.',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final verseNum = int.tryParse(comment.nodeId.split('_').last) ?? 1;
        final book = catholicBooks.firstWhere(
          (b) => b.abbrev == comment.documentId,
          orElse: () => catholicBooks.first,
        );
        final citation = '${book.bookName} ${comment.sectionIndex}:$verseNum';

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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  comment.commentText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (comment.textPreview != null &&
                    comment.textPreview!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment.textPreview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Edit comment',
                  onPressed: () => onEditComment(comment),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Delete comment',
                  onPressed: () => onDeleteComment(comment),
                ),
              ],
            ),
            onTap: () => onCommentTapped(comment),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: panelHeightAnimation,
      builder: (context, child) {
        return Container(
          height: panelHeightAnimation.value,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28.0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          // Drag Handle & Location Header
          GestureDetector(
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            onTap: onTogglePanel,
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
              child: Column(
                children: [
                  // Drag Handle Pill
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Current location title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        BibleVerseResolver.formatChapterTitle(
                          bookNumber: currentBook.bookNumber,
                          bookName: currentBook.bookName,
                          chapter: currentChapter,
                          numberingSystem: numberingSystem,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isPanelExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar and Tab Views
          if (isPanelExpanded)
            Expanded(
              child: AnimatedBuilder(
                animation: panelHeightAnimation,
                builder: (context, _) {
                  if (panelHeightAnimation.value <= 150.0) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      TabBar(
                        controller: sheetTabController,
                        tabs: const [
                          Tab(text: 'Books'),
                          Tab(text: 'Chapters'),
                          Tab(text: 'Favorites'),
                          Tab(text: 'Comments'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: sheetTabController,
                          children: [
                            // Tab 1: Book List grouped by Category
                            ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: [
                                _buildBookGroup(
                                  context,
                                  'Pentateuch',
                                  catholicBooks
                                      .where((b) => b.category == 'Pentateuch')
                                      .toList(),
                                ),
                                _buildBookGroup(
                                  context,
                                  'Historical Books',
                                  catholicBooks
                                      .where(
                                        (b) => b.category == 'Historical Books',
                                      )
                                      .toList(),
                                ),
                                _buildBookGroup(
                                  context,
                                  'Wisdom Books',
                                  catholicBooks
                                      .where(
                                        (b) => b.category == 'Wisdom Books',
                                      )
                                      .toList(),
                                ),
                                _buildBookGroup(
                                  context,
                                  'Prophets',
                                  catholicBooks
                                      .where((b) => b.category == 'Prophets')
                                      .toList(),
                                ),
                                _buildBookGroup(
                                  context,
                                  'Gospels & Acts',
                                  catholicBooks
                                      .where(
                                        (b) => b.category == 'Gospels & Acts',
                                      )
                                      .toList(),
                                ),
                                _buildBookGroup(
                                  context,
                                  'Epistles',
                                  catholicBooks
                                      .where((b) => b.category == 'Epistles')
                                      .toList(),
                                ),
                                _buildBookGroup(
                                  context,
                                  'Prophecy',
                                  catholicBooks
                                      .where((b) => b.category == 'Prophecy')
                                      .toList(),
                                ),
                              ],
                            ),

                            // Tab 2: Chapter Grid
                            GridView.builder(
                              padding: const EdgeInsets.all(16.0),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    mainAxisSpacing: 12.0,
                                    crossAxisSpacing: 12.0,
                                  ),
                              itemCount: selectedBookForPicker.chaptersCount,
                              itemBuilder: (context, index) {
                                final chapterNum = index + 1;
                                final chapterLabel =
                                    BibleVerseResolver.formatChapterPickerLabel(
                                      bookNumber:
                                          selectedBookForPicker.bookNumber,
                                      chapter: chapterNum,
                                      numberingSystem: numberingSystem,
                                    );
                                return InkWell(
                                  onTap: () => onChapterSelected(
                                    selectedBookForPicker,
                                    chapterNum,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        chapterLabel,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  selectedBookForPicker
                                                              .bookNumber ==
                                                          21 &&
                                                      numberingSystem ==
                                                          BibleNumberingSystem
                                                              .dual &&
                                                      chapterLabel.contains('(')
                                                  ? 11.0
                                                  : null,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Tab 3: Favorites List
                            _buildFavoritesTab(context, theme),

                            // Tab 4: Comments List
                            _buildCommentsTab(context, theme),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
