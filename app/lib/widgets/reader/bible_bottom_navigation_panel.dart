import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
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
