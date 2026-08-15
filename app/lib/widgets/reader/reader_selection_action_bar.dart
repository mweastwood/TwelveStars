import 'package:flutter/material.dart';

class ReaderSelectionActionBar extends StatelessWidget {
  final String title;
  final int selectedCount;
  final String? itemLabel;
  final VoidCallback onSaveFavorite;
  final VoidCallback onCopy;
  final VoidCallback? onAddComment;
  final VoidCallback? onClearSelection;

  const ReaderSelectionActionBar({
    super.key,
    required this.title,
    required this.selectedCount,
    this.itemLabel,
    required this.onSaveFavorite,
    required this.onCopy,
    this.onAddComment,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$selectedCount ${itemLabel ?? "item"}${selectedCount > 1 ? "s" : ""} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.star),
              tooltip: 'Save',
              onPressed: onSaveFavorite,
            ),
            if (onAddComment != null)
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                tooltip: 'Add Comment',
                onPressed: onAddComment,
              ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy selection',
              onPressed: onCopy,
            ),
            if (onClearSelection != null)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear Selection',
                onPressed: onClearSelection,
              ),
          ],
        ),
      ),
    );
  }
}
