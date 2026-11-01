import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_annotations_list_shell.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';

class LibraryCommentsView extends StatelessWidget {
  final List<LibraryBookItem>? catalog;
  final List<UserComment> comments;
  final bool isLoading;
  final VoidCallback onRefresh;
  final ScrollController? scrollController;
  final LibraryOpenReaderCallback onOpenReader;

  const LibraryCommentsView({
    super.key,
    this.catalog,
    this.scrollController,
    required this.comments,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenReader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LibraryAnnotationsListShell<UserComment>(
      catalog: catalog,
      scrollController: scrollController,
      items: comments,
      isLoading: isLoading,
      emptyIcon: Icons.comment_outlined,
      emptyTitle: 'No comments on library books yet.',
      emptySubtitle: 'Long-press on a passage, then tap Comment to add a note.',
      documentIdOf: (comment) => comment.documentId,
      itemBuilder: (context, comment, catalog) {
        final resolved = resolveLibraryAnnotation(
          documentId: comment.documentId,
          nodeId: comment.nodeId,
          catalog: catalog,
        );
        final book = resolved.book;
        String header = book?.title ?? comment.documentId;
        final headerVol = book?.resolveVolume(
          volumeKey: resolved.volumeKey,
          fallbackToFirst: false,
        );
        if (book != null && headerVol != null) {
          header = '${book.title} (${headerVol.shortName})';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(
              header,
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
                  ),
                ),
                if (comment.textPreview != null &&
                    comment.textPreview!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${comment.textPreview}"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () async {
                final confirmed = await showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Comment',
                  content: 'Are you sure you want to delete this comment?',
                  confirmLabel: 'Delete',
                );
                if (!confirmed || !context.mounted) return;
                await BibleDatabaseHelper.db.deleteComment(comment.id);
                if (!context.mounted) return;
                onRefresh();
              },
            ),
            onTap: () => LibraryAnnotationsListShell.openResolvedAnnotation(
              context: context,
              resolved: resolved,
              sectionIndex: comment.sectionIndex,
              onOpenReader: onOpenReader,
            ),
          ),
        );
      },
    );
  }
}
