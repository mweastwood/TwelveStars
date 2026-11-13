import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_annotations_list_shell.dart';

class LibraryFavoritesView extends StatelessWidget {
  final List<LibraryBookItem>? catalog;
  final List<LibraryBookmark> favorites;
  final bool isLoading;
  final VoidCallback onRefresh;
  final ScrollController? scrollController;
  final LibraryOpenReaderCallback onOpenReader;

  const LibraryFavoritesView({
    super.key,
    this.catalog,
    this.scrollController,
    required this.favorites,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenReader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LibraryAnnotationsListShell<LibraryBookmark>(
      catalog: catalog,
      scrollController: scrollController,
      items: favorites,
      isLoading: isLoading,
      emptyIcon: Icons.bookmark_outline,
      emptyTitle: 'No favorite passages saved in Library yet.',
      emptySubtitle: 'Long-press on any passage in a book to select and save.',
      documentIdOf: (fav) => fav.documentId,
      itemBuilder: (context, fav, catalog) {
        final parts = fav.textPreview.split('\n');
        final citation = parts.first;
        final preview = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        final resolved = resolveLibraryAnnotation(
          documentId: fav.documentId,
          nodeId: fav.nodeId,
          catalog: catalog,
        );

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
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () async {
                await BibleDatabaseHelper.db.deleteLibraryBookmark(fav.id);
                if (!context.mounted) return;
                onRefresh();
              },
            ),
            onTap: () => LibraryAnnotationsListShell.openResolvedAnnotation(
              context: context,
              resolved: resolved,
              sectionIndex: fav.sectionIndex,
              onOpenReader: onOpenReader,
            ),
          ),
        );
      },
    );
  }
}
