import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_node_parser.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';

class LibraryCommentsView extends StatefulWidget {
  final List<UserComment> comments;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(
    LibraryBookItem book, {
    String? volumeKey,
    String? assetPath,
    int? sectionIndex,
    int? itemIndex,
    int? questionNumber,
  })
  onOpenReader;

  const LibraryCommentsView({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenReader,
  });

  @override
  State<LibraryCommentsView> createState() => _LibraryCommentsViewState();
}

class _LibraryCommentsViewState extends State<LibraryCommentsView> {
  String _selectedCommentBookId = 'all';

  @override
  void didUpdateWidget(covariant LibraryCommentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCommentBookId != 'all' &&
        !widget.comments.any((c) => c.documentId == _selectedCommentBookId)) {
      _selectedCommentBookId = 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.comments.isEmpty) {
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
                'No comments on library books yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Long-press on a passage, then tap Comment to add a note.',
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

    final catalog = LibraryHelper.getCatalog();
    final distinctBookIds = widget.comments
        .map((c) => c.documentId)
        .toSet()
        .toList();

    final filteredComments = _selectedCommentBookId == 'all'
        ? widget.comments
        : widget.comments
              .where((c) => c.documentId == _selectedCommentBookId)
              .toList();

    return Column(
      children: [
        if (distinctBookIds.length > 1) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _selectedCommentBookId == 'all',
                      label: Text('All (${widget.comments.length})'),
                      onSelected: (val) {
                        setState(() {
                          _selectedCommentBookId = 'all';
                        });
                      },
                    ),
                  ),
                  ...distinctBookIds.map((bookId) {
                    final book = catalog
                        .where((b) => b.id == bookId)
                        .firstOrNull;
                    final bookTitle = book?.title ?? bookId;
                    final count = widget.comments
                        .where((c) => c.documentId == bookId)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: _selectedCommentBookId == bookId,
                        label: Text('$bookTitle ($count)'),
                        onSelected: (val) {
                          setState(() {
                            _selectedCommentBookId = val ? bookId : 'all';
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: filteredComments.length,
            itemBuilder: (context, index) {
              final comment = filteredComments[index];
              final book = catalog
                  .where((b) => b.id == comment.documentId)
                  .firstOrNull;

              final (volKey, itemIdx, qNum) = parseLibraryNodeId(
                comment.nodeId,
              );
              String header = book?.title ?? comment.documentId;
              if (book != null &&
                  volKey != null &&
                  book.isSeries &&
                  book.volumes != null) {
                final vol = book.volumes!
                    .where((v) => v.volumeKey == volKey)
                    .firstOrNull;
                if (vol != null) {
                  header = '${book.title} (${vol.shortName})';
                }
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
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () async {
                      final confirmed = await showDeleteConfirmationDialog(
                        context: context,
                        title: 'Delete Comment',
                        content:
                            'Are you sure you want to delete this comment?',
                        confirmLabel: 'Delete',
                      );
                      if (!confirmed || !context.mounted) return;
                      await BibleDatabaseHelper.db.deleteComment(comment.id);
                      widget.onRefresh();
                    },
                  ),
                  onTap: () {
                    if (book == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Book not found in library'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    String? targetAssetPath;
                    String? targetVolKey = volKey;
                    if (book.isSeries && book.volumes != null) {
                      final match =
                          book.volumes!
                              .where((v) => v.volumeKey == volKey)
                              .firstOrNull ??
                          book.volumes!.firstOrNull;
                      if (match != null) {
                        targetVolKey = match.volumeKey;
                        targetAssetPath = match.assetPath;
                      }
                    }

                    widget.onOpenReader(
                      book,
                      volumeKey: targetVolKey,
                      assetPath: targetAssetPath,
                      sectionIndex: comment.sectionIndex,
                      itemIndex: itemIdx,
                      questionNumber: qNum,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
