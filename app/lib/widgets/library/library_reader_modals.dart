import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/widgets/library_section_view.dart';
import 'package:twelve_stars/widgets/library_toc_drawer.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/reader/library_cross_ref_sheet.dart';
import 'package:twelve_stars/widgets/reader/library_scripture_modal.dart';
import 'package:twelve_stars/widgets/reader/library_search_results_view.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
import 'package:twelve_stars/widgets/reader/reader_text_options_sheet.dart';

/// Shows a modal bottom sheet allowing the user to pick a volume/edition from
/// a multi-volume [LibraryBookItem] or explicit [volumes] list.
Future<BaltimoreVolume?> showLibraryReaderVolumePickerSheet({
  required BuildContext context,
  List<BaltimoreVolume>? volumes,
  LibraryBookItem? bookItem,
  String? currentVolumeKey,
  String? selectedVolumeKey,
  ValueChanged<BaltimoreVolume>? onVolumeSelected,
}) async {
  final effectiveVolumes =
      volumes ?? bookItem?.volumes ?? const <BaltimoreVolume>[];
  if (effectiveVolumes.isEmpty) return null;

  final effectiveSelectedKey = currentVolumeKey ?? selectedVolumeKey;
  final theme = Theme.of(context);
  final headerTitle = bookItem?.title ?? 'Select Volume';

  return showModalBottomSheet<BaltimoreVolume>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (sheetCtx, scrollController) {
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
                      headerTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select from ${effectiveVolumes.length} volumes',
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
                  itemCount: effectiveVolumes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (itemCtx, idx) {
                    final vol = effectiveVolumes[idx];
                    final isSelected = vol.volumeKey == effectiveSelectedKey;
                    return ListTile(
                      selected: isSelected,
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.menu_book_rounded,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        vol.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: vol.description.isNotEmpty
                          ? Text(
                              vol.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      trailing:
                          vol.shortName.isNotEmpty && vol.shortName != vol.name
                          ? Text(
                              vol.shortName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop(vol);
                        onVolumeSelected?.call(vol);
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

/// Shows the Table of Contents bottom sheet for [book].
Future<void> showLibraryReaderTocSheet({
  required BuildContext context,
  required ParsedBookData book,
  required int currentSectionIndex,
  required ValueChanged<int> onSectionSelected,
}) {
  return LibraryTocDrawer.show(
    context,
    book: book,
    currentSectionIndex: currentSectionIndex,
    onSectionSelected: onSectionSelected,
  );
}

/// Shows an interactive in-book search dialog for [book] and invokes
/// [onResultSelected] when a matching [BookSearchResult] is tapped.
Future<BookSearchResult?> showLibraryReaderSearchDialog({
  required BuildContext context,
  required ParsedBookData book,
  LibraryReaderAdapter? adapter,
  List<BookSearchResult> Function(String query)? onSearch,
  ValueChanged<BookSearchResult>? onResultSelected,
  String initialQuery = '',
}) {
  final searchFn =
      onSearch ??
      (String query) => adapter != null
          ? adapter.searchInBook(book, query)
          : LibraryHelper.searchInBook(book, query);

  return showDialog<BookSearchResult>(
    context: context,
    builder: (dialogCtx) {
      return _LibraryReaderSearchDialog(
        bookTitle: book.title,
        initialQuery: initialQuery,
        onSearch: searchFn,
        onResultSelected: (res) {
          Navigator.of(dialogCtx).pop(res);
          onResultSelected?.call(res);
        },
      );
    },
  );
}

class _LibraryReaderSearchDialog extends StatefulWidget {
  final String bookTitle;
  final String initialQuery;
  final List<BookSearchResult> Function(String query) onSearch;
  final ValueChanged<BookSearchResult> onResultSelected;

  const _LibraryReaderSearchDialog({
    required this.bookTitle,
    required this.initialQuery,
    required this.onSearch,
    required this.onResultSelected,
  });

  @override
  State<_LibraryReaderSearchDialog> createState() =>
      _LibraryReaderSearchDialogState();
}

class _LibraryReaderSearchDialogState
    extends State<_LibraryReaderSearchDialog> {
  late final TextEditingController _controller;
  late String _query;
  late List<BookSearchResult> _results;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: _query);
    _results = _query.trim().isNotEmpty ? widget.onSearch(_query) : const [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateQuery(String val) {
    setState(() {
      _query = val;
      _results = val.trim().isNotEmpty ? widget.onSearch(val) : const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search in ${widget.bookTitle}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close Search',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search in book...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                          onPressed: () {
                            _controller.clear();
                            _updateQuery('');
                          },
                        )
                      : null,
                ),
                onChanged: _updateQuery,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: LibrarySearchResultsView(
                searchQuery: _query,
                searchResults: _results,
                onResultTap: widget.onResultSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the Baltimore Catechism cross-reference modal sheet for
/// [questionNumber].
Future<void> showLibraryReaderCrossRefModal({
  required BuildContext context,
  required int questionNumber,
  required LibraryBookItem bookItem,
  void Function(
    BaltimoreVolume volume,
    int sectionIndex, [
    int? questionNumber,
  ])?
  onSwitchVolume,
}) {
  return showBaltimoreCrossRefSheet(
    context: context,
    questionNumber: questionNumber,
    bookItem: bookItem,
    onSwitchVolume: onSwitchVolume ?? (_, _, [_]) {},
  );
}

/// Shows the text options bottom sheet for adjusting reader [fontSize].
Future<void> showLibraryReaderTextOptionsSheet({
  required BuildContext context,
  required double fontSize,
  required ValueChanged<double> onFontSizeChanged,
}) {
  return ReaderTextOptionsSheet.show(
    context,
    fontSize: fontSize,
    onFontSizeChanged: onFontSizeChanged,
  );
}

/// Shows the add-comment dialog for a selected library passage.
Future<void> showLibraryReaderAddCommentModal({
  required BuildContext context,
  required String citation,
  required String textPreview,
  required String documentId,
  required int sectionIndex,
  required String nodeId,
  required VoidCallback onCommentSaved,
}) {
  return showAddCommentDialog(
    context: context,
    citation: citation,
    textPreview: textPreview,
    documentId: documentId,
    sectionIndex: sectionIndex,
    nodeId: nodeId,
    onCommentSaved: onCommentSaved,
  );
}

/// Shows the comments modal for an annotated library item and allows adding
/// a new comment.
Future<void> showLibraryReaderCommentsModal({
  required BuildContext context,
  required String documentId,
  required int sectionIndex,
  required String nodeId,
  required String citation,
  required String textPreview,
  required List<UserComment> comments,
  required VoidCallback onCommentsChanged,
}) {
  return showVerseCommentsModal(
    context: context,
    title: citation,
    nodeId: nodeId,
    textPreview: textPreview,
    comments: comments,
    onCommentsChanged: onCommentsChanged,
    onAddComment: () => showLibraryReaderAddCommentModal(
      context: context,
      citation: citation,
      textPreview: textPreview,
      documentId: documentId,
      sectionIndex: sectionIndex,
      nodeId: nodeId,
      onCommentSaved: onCommentsChanged,
    ),
  );
}

/// Builds the [AppBar] for `LibraryReaderScreen`, supporting both normal
/// navigation actions and inline search mode.
PreferredSizeWidget buildLibraryReaderAppBar({
  required ThemeData theme,
  required String bookTitle,
  required ParsedBookData? book,
  required bool isSearching,
  required TextEditingController searchController,
  required ValueChanged<String> onSearchChanged,
  required VoidCallback onClearSearch,
  required VoidCallback onStartSearch,
  required VoidCallback onCloseSearch,
  required VoidCallback onOpenToc,
  required VoidCallback onOpenFontOptions,
}) {
  return AppBar(
    title: isSearching
        ? TextField(
            controller: searchController,
            autofocus: true,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: const InputDecoration(
              hintText: 'Search in book...',
              border: InputBorder.none,
            ),
            onChanged: onSearchChanged,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (book != null)
                Text(
                  book.subtitle.isNotEmpty ? book.subtitle : book.title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
    actions: [
      if (isSearching)
        IconButton(icon: const Icon(Icons.clear), onPressed: onClearSearch)
      else ...[
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search in Book',
          onPressed: onStartSearch,
        ),
        IconButton(
          icon: const Icon(Icons.list),
          tooltip: 'Table of Contents',
          onPressed: onOpenToc,
        ),
        IconButton(
          icon: const Icon(Icons.text_fields),
          tooltip: 'Text Options',
          onPressed: onOpenFontOptions,
        ),
      ],
    ],
    leading: isSearching
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onCloseSearch,
          )
        : null,
  );
}

/// Builds the floating selection action bar for `LibraryReaderScreen`.
Widget buildLibraryReaderSelectionActionBar({
  required BuildContext context,
  required LibraryReaderAdapter adapter,
  required String documentId,
  required int sectionIndex,
  required String nodeId,
  required String citation,
  required String textPreview,
  required int selectedCount,
  required VoidCallback onClearSelection,
  required Future<void> Function() onCommentSaved,
  VoidCallback? onFavoriteSaved,
}) {
  return ReaderSelectionActionBar(
    title: citation,
    selectedCount: selectedCount,
    itemLabel: 'passage',
    onSaveFavorite: () async {
      await adapter.saveBookmark(
        ReaderBookmark(
          id: '',
          documentId: documentId,
          sectionIndex: sectionIndex,
          nodeId: nodeId,
          textPreview: '$citation\n$textPreview',
          timestamp: DateTime.now(),
        ),
      );

      onFavoriteSaved?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $citation to Favorites'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        onClearSelection();
      }
    },
    onAddComment: () => showLibraryReaderAddCommentModal(
      context: context,
      citation: citation,
      textPreview: textPreview,
      documentId: documentId,
      sectionIndex: sectionIndex,
      nodeId: nodeId,
      onCommentSaved: () async {
        onClearSelection();
        await onCommentSaved();
      },
    ),
    onCopy: () async {
      final clipboardContent = '$citation\n\n$textPreview';
      await Clipboard.setData(ClipboardData(text: clipboardContent));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $citation to clipboard'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        onClearSelection();
      }
    },
    onClearSelection: onClearSelection,
  );
}

/// Builds the main paged section reader view with comment, cross-reference,
/// and scripture modal wiring.
Widget buildLibraryReaderSectionContentView({
  required BuildContext context,
  required ParsedBookData book,
  required LibraryBookItem bookItem,
  required PageController pageController,
  required int currentSectionIndex,
  required double fontSize,
  required String? currentVolumeKey,
  required Map<int, Map<int, GlobalKey>> sectionQuestionKeys,
  required Map<int, Map<int, GlobalKey>> sectionItemKeys,
  required Map<String, List<UserComment>> sectionCommentsMap,
  required int? selectedStartIndex,
  required int? selectedEndIndex,
  required ValueChanged<int> onPageChanged,
  required ValueChanged<int> onItemLongPress,
  required ValueChanged<int> onItemTap,
  required VoidCallback onCommentsChanged,
  required void Function(BaltimoreVolume vol, int secIdx, [int? targetQNum])
  onSwitchVolume,
  Widget? selectionActionBar,
}) {
  if (book.sections.isEmpty) {
    return const Center(child: Text('No content found in this volume.'));
  }

  return Stack(
    children: [
      PageView.builder(
        controller: pageController,
        itemCount: book.sections.length,
        onPageChanged: onPageChanged,
        itemBuilder: (ctx, index) {
          final isCurrent = index == currentSectionIndex;
          return LibrarySectionView(
            section: book.sections[index],
            fontSize: fontSize,
            verseSystem: bookItem.verseSystem,
            volumeKey: currentVolumeKey,
            questionKeys: isCurrent
                ? (sectionQuestionKeys[index] ?? const {})
                : const {},
            itemKeys: isCurrent
                ? (sectionItemKeys[index] ?? const {})
                : const {},
            selectedStartIndex: isCurrent ? selectedStartIndex : null,
            selectedEndIndex: isCurrent ? selectedEndIndex : null,
            onItemLongPress: isCurrent ? onItemLongPress : null,
            onItemTap: isCurrent ? onItemTap : null,
            commentsMap: isCurrent ? sectionCommentsMap : null,
            onTapComments: (nodeId, citation, textPreview, itemComments) =>
                showLibraryReaderCommentsModal(
                  context: context,
                  documentId: bookItem.id,
                  sectionIndex: currentSectionIndex,
                  nodeId: nodeId,
                  citation: citation,
                  textPreview: textPreview,
                  comments: itemComments,
                  onCommentsChanged: onCommentsChanged,
                ),
            onShowCrossRefModal: (qNum) => showLibraryReaderCrossRefModal(
              context: context,
              questionNumber: qNum,
              bookItem: bookItem,
              onSwitchVolume: (vol, idx, [targetQNum]) =>
                  onSwitchVolume(vol, idx, targetQNum ?? qNum),
            ),
            onShowScriptureModal: (citation) =>
                showLibraryScriptureModal(context: context, citation: citation),
          );
        },
      ),
      if (selectionActionBar != null)
        Positioned(left: 16, right: 16, bottom: 16, child: selectionActionBar),
    ],
  );
}
