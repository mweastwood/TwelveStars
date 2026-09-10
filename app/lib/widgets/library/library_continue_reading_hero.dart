import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';

class LibraryContinueReadingHero extends StatelessWidget {
  final BookReadingPosition readingPosition;
  final List<LibraryBookItem> catalog;
  final void Function(
    LibraryBookItem book, {
    String? volumeKey,
    String? assetPath,
    int? sectionIndex,
    String? sectionId,
  })
  onResume;

  const LibraryContinueReadingHero({
    super.key,
    required this.readingPosition,
    required this.catalog,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = catalog
        .where((b) => b.id == readingPosition.bookId)
        .firstOrNull;
    if (book == null) return const SizedBox.shrink();

    String? volumeName;
    String? volumeAssetPath;
    if (book.isSeries && readingPosition.volumeKey != null) {
      final vol = book.volumes
          ?.where((v) => v.volumeKey == readingPosition.volumeKey)
          .firstOrNull;
      if (vol != null) {
        volumeName = vol.name;
        volumeAssetPath = vol.assetPath;
      }
    }

    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark_added_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'CONTINUE READING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (volumeName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          volumeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'Section ${readingPosition.sectionIndex + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => onResume(
                    book,
                    volumeKey: readingPosition.volumeKey,
                    assetPath: volumeAssetPath,
                    sectionIndex: readingPosition.sectionIndex,
                    sectionId: readingPosition.sectionId,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Resume'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
