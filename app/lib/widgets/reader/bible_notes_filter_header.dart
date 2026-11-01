import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/bible_numbering_mapper.dart';
import 'package:twelve_stars/widgets/bible_annotation_card.dart';

enum BibleNotesScope { chapter, book, all }

/// Search bar, book/chapter dropdown pickers, breadcrumb scope bar, and
/// Favorites/Notes filter chips for `BibleNotesScreen`.
class BibleNotesFilterHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final BibleNotesScope scope;
  final BibleBook? activeBook;
  final int? activeChapter;
  final BibleNumberingSystem numberingSystem;
  final BibleAnnotationType? selectedTypeFilter;
  final int favCount;
  final int noteCount;
  final int allCount;
  final int bookCount;
  final int chapterCount;
  final ValueChanged<BibleBook?> onBookChanged;
  final ValueChanged<int?> onChapterChanged;
  final VoidCallback onSelectBibleScope;
  final VoidCallback onSelectBookScope;
  final ValueChanged<BibleAnnotationType> onToggleTypeFilter;

  const BibleNotesFilterHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.scope,
    required this.activeBook,
    required this.activeChapter,
    this.numberingSystem = BibleNumberingSystem.vulgate,
    required this.selectedTypeFilter,
    required this.favCount,
    required this.noteCount,
    required this.allCount,
    required this.bookCount,
    required this.chapterCount,
    required this.onBookChanged,
    required this.onChapterChanged,
    required this.onSelectBibleScope,
    required this.onSelectBookScope,
    required this.onToggleTypeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChapterDropdownDisabled =
        scope == BibleNotesScope.all || activeBook == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
          TextField(
            key: const Key('bible_notes_search_field'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search notes, favorites, or verses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onSearchCleared,
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
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
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BibleBook?>(
                      key: const Key('bible_notes_book_dropdown'),
                      value: scope == BibleNotesScope.all ? null : activeBook,
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
                      onChanged: onBookChanged,
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
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: isChapterDropdownDisabled ? 0.2 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      key: const Key('bible_notes_chapter_dropdown'),
                      value: scope == BibleNotesScope.chapter
                          ? activeChapter
                          : null,
                      isDense: true,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      hint: const Text('Chapter'),
                      disabledHint: Text(
                        'Chapter',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                      items: isChapterDropdownDisabled
                          ? null
                          : [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('All Chapters'),
                              ),
                              ...List.generate(activeBook!.chaptersCount, (
                                index,
                              ) {
                                final chapNum = index + 1;
                                final chapLabel =
                                    BibleVerseResolver.formatChapterPickerLabel(
                                      bookNumber: activeBook!.bookNumber,
                                      chapter: chapNum,
                                      numberingSystem: numberingSystem,
                                    );
                                return DropdownMenuItem<int?>(
                                  value: chapNum,
                                  child: Text('Ch. $chapLabel'),
                                );
                              }),
                            ],
                      onChanged: isChapterDropdownDisabled
                          ? null
                          : onChapterChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // 3 & 4. Breadcrumb Scope Path & Type Selector
          _buildBreadcrumbPath(theme),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbPath(ThemeData theme) {
    final canWalkToBible = scope != BibleNotesScope.all;
    final canWalkToBook = scope == BibleNotesScope.chapter;

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
              onTap: canWalkToBible ? onSelectBibleScope : null,
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
                      color: scope == BibleNotesScope.all
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bible',
                      style: TextStyle(
                        fontWeight: scope == BibleNotesScope.all
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: scope == BibleNotesScope.all
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
          if (activeBook != null && scope != BibleNotesScope.all) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ),
            Tooltip(
              message: '${activeBook!.bookName} ($bookCount)',
              child: InkWell(
                key: const Key('breadcrumb_book'),
                borderRadius: BorderRadius.circular(8),
                onTap: canWalkToBook ? onSelectBookScope : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    activeBook!.bookName,
                    style: TextStyle(
                      fontWeight: scope == BibleNotesScope.book
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: scope == BibleNotesScope.book
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
          if (activeChapter != null && scope == BibleNotesScope.chapter) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ),
            Builder(
              builder: (context) {
                final chapLabel = activeBook != null
                    ? BibleVerseResolver.formatChapterPickerLabel(
                        bookNumber: activeBook!.bookNumber,
                        chapter: activeChapter!,
                        numberingSystem: numberingSystem,
                      )
                    : '$activeChapter';
                return Tooltip(
                  message: 'Chapter $chapLabel ($chapterCount)',
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
                        'Chapter $chapLabel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
          ..._buildFilterChips(theme),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips(ThemeData theme) {
    final isFavoritesSelected =
        selectedTypeFilter == BibleAnnotationType.favorite;
    final isNotesSelected = selectedTypeFilter == BibleAnnotationType.comment;

    return [
      FilterChip(
        key: const Key('filter_favorites_chip'),
        showCheckmark: false,
        avatar: Icon(
          isFavoritesSelected ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: isFavoritesSelected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.outline,
        ),
        label: Text('Favorites ($favCount)'),
        selected: isFavoritesSelected,
        onSelected: (_) => onToggleTypeFilter(BibleAnnotationType.favorite),
      ),
      const SizedBox(width: 8.0),
      FilterChip(
        key: const Key('filter_notes_chip'),
        showCheckmark: false,
        avatar: Icon(
          isNotesSelected ? Icons.comment_rounded : Icons.comment_outlined,
          size: 16,
          color: isNotesSelected
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.outline,
        ),
        label: Text('Notes ($noteCount)'),
        selected: isNotesSelected,
        onSelected: (_) => onToggleTypeFilter(BibleAnnotationType.comment),
      ),
    ];
  }
}
