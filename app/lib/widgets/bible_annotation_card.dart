import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';

enum BibleAnnotationType { favorite, comment }

class BibleAnnotationItem {
  final int bookNumber;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String textPreview;
  final BibleAnnotationType type;
  final FavoritePassage? favorite;
  final UserComment? comment;
  final DateTime createdAt;

  BibleAnnotationItem({
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.textPreview,
    required this.type,
    this.favorite,
    this.comment,
    required this.createdAt,
  });

  String get citation {
    if (type == BibleAnnotationType.favorite && startVerse != endVerse) {
      return '$bookName $chapter:$startVerse-$endVerse';
    }
    return '$bookName $chapter:$startVerse';
  }
}

class BibleAnnotationCard extends StatelessWidget {
  final BibleAnnotationItem item;
  final VoidCallback? onOpen;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BibleAnnotationCard({
    super.key,
    required this.item,
    this.onOpen,
    this.onCopy,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFav = item.type == BibleAnnotationType.favorite;

    return Card(
      key:
          key ??
          Key(
            'bible_annotation_${item.type.name}_${item.bookNumber}_${item.chapter}_${item.startVerse}',
          ),
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Citation + Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.citation,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFav
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.8,
                            )
                          : theme.colorScheme.secondaryContainer.withValues(
                              alpha: 0.8,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFav
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.secondary.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFav ? Icons.star_rounded : Icons.comment_rounded,
                          size: 13,
                          color: isFav
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFav ? 'Favorite' : 'Note',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFav
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // Scripture Verse Preview
              if (item.textPreview.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: Text(
                    '"${item.textPreview}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),

              // Personal Note Block (if comment)
              if (item.comment != null) ...[
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Personal Reflection',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  item.comment!.commentText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 8.0),
              const Divider(height: 16),

              // Action buttons footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.menu_book_rounded, size: 16),
                    label: const Text('Open'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onCopy,
                  ),
                  if (item.type == BibleAnnotationType.comment)
                    IconButton(
                      tooltip: 'Edit note',
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                    ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
