import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';

Future<void> showReverseCitationsModal({
  required BuildContext context,
  required String title,
  required List<ReverseCitation> citations,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (sheetCtx, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Library References to $title',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: citations.length,
                          itemBuilder: (lCtx, index) {
                            final item = citations[index];
                            final qText = item.questionNumber != null
                                ? 'Q. ${item.questionNumber}. '
                                : '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.sourceBookTitle,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          item.citation.displayLabel,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  if (item.sourceAuthor.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'By ${item.sourceAuthor}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '$qText${item.sectionTitle}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.snippet.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.snippet,
                                      maxLines: 6,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Read in Library'),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        final catalog =
                                            LibraryHelper.getCatalog();
                                        final book = catalog.firstWhere(
                                          (b) =>
                                              b.id == item.sourceBookId ||
                                              b.defaultAssetPath ==
                                                  item.sourceAssetPath ||
                                              (b.volumes?.any(
                                                    (v) =>
                                                        v.assetPath ==
                                                        item.sourceAssetPath,
                                                  ) ??
                                                  false),
                                          orElse: () => catalog[0],
                                        );

                                        // For series books, find the volume containing this section
                                        String? targetAssetPath;
                                        String? targetVolumeKey;
                                        if (book.isSeries &&
                                            book.volumes != null &&
                                            book.volumes!.isNotEmpty) {
                                          final matchingVol = book.volumes!
                                              .firstWhere(
                                                (v) =>
                                                    v.assetPath ==
                                                    item.sourceAssetPath,
                                                orElse: () =>
                                                    book.volumes!.first,
                                              );
                                          targetVolumeKey =
                                              matchingVol.volumeKey;
                                          targetAssetPath =
                                              matchingVol.assetPath;
                                        } else {
                                          targetAssetPath =
                                              item.sourceAssetPath;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LibraryReaderScreen(
                                              bookItem: book,
                                              initialAssetPath: targetAssetPath,
                                              initialVolumeKey: targetVolumeKey,
                                              initialSectionId: item.sectionId,
                                              initialQuestionNumber:
                                                  item.questionNumber,
                                              initialItemIndex: item.itemIndex,
                                              navigationSessionId:
                                                  DateTime.now()
                                                      .millisecondsSinceEpoch
                                                      .toString(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showVerseCommentsModal({
  required BuildContext context,
  required String title,
  required String nodeId,
  required String textPreview,
  required List<UserComment> comments,
  required FutureOr<void> Function() onCommentsChanged,
  required VoidCallback onAddComment,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.comment_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comments for $title',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  textPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 24),
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No comments yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (lCtx, index) {
                        final comment = comments[index];
                        final formattedDate =
                            '${comment.createdAt.year}-${comment.createdAt.month.toString().padLeft(2, '0')}-${comment.createdAt.day.toString().padLeft(2, '0')} ${comment.createdAt.hour.toString().padLeft(2, '0')}:${comment.createdAt.minute.toString().padLeft(2, '0')}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(comment.commentText),
                            subtitle: Text(
                              formattedDate,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  tooltip: 'Edit comment',
                                  color: theme.colorScheme.primary,
                                  onPressed: () async {
                                    await showEditCommentDialog(
                                      context: context,
                                      citation: title,
                                      textPreview: textPreview,
                                      commentId: comment.id,
                                      initialText: comment.commentText,
                                      onCommentUpdated: (newText) async {
                                        setSheetState(() {
                                          comments[index] = comment.copyWith(
                                            commentText: newText,
                                          );
                                        });
                                        await onCommentsChanged();
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete comment',
                                  color: theme.colorScheme.error,
                                  onPressed: () async {
                                    final confirmed =
                                        await showDeleteConfirmationDialog(
                                          context: context,
                                          title: 'Delete Comment',
                                          content:
                                              'Are you sure you want to delete this comment?',
                                          confirmLabel: 'Delete',
                                        );
                                    if (!confirmed) return;
                                    await BibleDatabaseHelper.db.deleteComment(
                                      comment.id,
                                    );
                                    setSheetState(() {
                                      comments.removeAt(index);
                                    });
                                    await onCommentsChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_comment),
                    label: const Text('Add Another Comment'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onAddComment();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showEditCommentDialog({
  required BuildContext context,
  required String citation,
  required String textPreview,
  required int commentId,
  required String initialText,
  FutureOr<void> Function(String updatedText)? onCommentUpdated,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final controller = TextEditingController(text: initialText);

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Edit Comment for $citation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (textPreview.isNotEmpty) ...[
              Text(
                '"$textPreview"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(ctx).colorScheme.outline,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (result != null && result.isNotEmpty) {
    final db = BibleDatabaseHelper.db;
    await db.updateComment(commentId, result);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Updated comment for $citation'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (onCommentUpdated != null) {
      await onCommentUpdated(result);
    }
  }
}

Future<void> showAddCommentDialog({
  required BuildContext context,
  required String citation,
  required String textPreview,
  required String documentId,
  required int sectionIndex,
  required String nodeId,
  FutureOr<void> Function()? onCommentSaved,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Add Comment for $citation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$textPreview"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(ctx).colorScheme.outline,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (result != null && result.isNotEmpty) {
    final db = BibleDatabaseHelper.db;
    await db.saveComment(
      UserCommentsCompanion.insert(
        documentId: documentId,
        sectionIndex: sectionIndex,
        nodeId: nodeId,
        commentText: result,
        textPreview: Value(textPreview),
        createdAt: DateTime.now(),
      ),
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text('Saved comment for $citation'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (onCommentSaved != null) {
      await onCommentSaved();
    }
  }
}

Future<void> showVerseFavoritesModal({
  required BuildContext context,
  required String title,
  required List<FavoritePassage> favorites,
  required FutureOr<void> Function() onFavoritesChanged,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        favorites.length > 1
                            ? 'Favorite Passages for $title'
                            : 'Favorite Passage for $title',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (favorites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No favorite passages found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: favorites.length,
                      itemBuilder: (lCtx, index) {
                        final fav = favorites[index];
                        final citation = fav.startVerse == fav.endVerse
                            ? '${fav.bookName} ${fav.chapter}:${fav.startVerse}'
                            : '${fav.bookName} ${fav.chapter}:${fav.startVerse}-${fav.endVerse}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              citation,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            subtitle: Text(
                              fav.textPreview,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: theme.colorScheme.error,
                              onPressed: () async {
                                final confirmed =
                                    await showDeleteConfirmationDialog(
                                      context: context,
                                      title: 'Remove Favorite',
                                      content:
                                          'Are you sure you want to remove this favorite passage?',
                                      confirmLabel: 'Remove',
                                    );
                                if (!confirmed) return;
                                await BibleDatabaseHelper.db.deleteFavorite(
                                  fav.id,
                                );
                                setSheetState(() {
                                  favorites.removeAt(index);
                                });
                                await onFavoritesChanged();
                                if (favorites.isEmpty && ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
