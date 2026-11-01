import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/widgets/library/library_volume_picker_sheet.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

class LibraryCategoryIcons {
  const LibraryCategoryIcons._();

  static IconData forCategory(String category) {
    switch (category) {
      case 'Apostolic Fathers':
        return Icons.history_edu_rounded;
      case 'Early Apologists':
        return Icons.shield_outlined;
      case 'Church Fathers':
        return Icons.church_rounded;
      case 'Patristics':
        return Icons.account_balance_rounded;
      case 'Doctors of the Church':
      case 'Doctors of the Church / Spiritual Classics':
        return Icons.school_rounded;
      case 'Marian & Spiritual Classics':
        return Icons.flare_rounded;
      case 'Monastic & Spiritual Classics':
        return Icons.cottage_rounded;
      case 'Spiritual Classics':
        return Icons.self_improvement_rounded;
      case 'Catechisms':
      default:
        return Icons.menu_book_rounded;
    }
  }
}

class LibraryBookCard extends StatelessWidget {
  final LibraryBookItem bookItem;
  final void Function(
    LibraryBookItem book, {
    String? volumeKey,
    String? assetPath,
  })
  onOpenReader;
  final VoidCallback? onBrowseVolumes;

  const LibraryBookCard({
    super.key,
    required this.bookItem,
    required this.onOpenReader,
    this.onBrowseVolumes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryIcon = LibraryCategoryIcons.forCategory(bookItem.category);

    return Card(
      key: ValueKey('book_card_${bookItem.id}'),
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookItem.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bookItem.subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (bookItem.authorSaintId != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final saint = await SaintDatabase.getSaintById(
                              bookItem.authorSaintId!,
                            );
                            if (!context.mounted) return;
                            if (saint != null) {
                              SaintDetailsSheet.show(context, saint);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'By ${bookItem.author}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'By ${bookItem.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: [
                          if (bookItem.era != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bookItem.era!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bookItem.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (bookItem.isSeries)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${bookItem.volumes!.length} Volumes',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          if (bookItem.isWeb)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.language_rounded,
                                    size: 11,
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Online Work',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bookItem.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (bookItem.isSeries) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Volume (${bookItem.volumes!.length}):',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.layers_outlined, size: 16),
                    label: const Text('Browse All ▾'),
                    onPressed:
                        onBrowseVolumes ??
                        () => LibraryVolumePickerSheet.show(
                          context,
                          bookItem: bookItem,
                          onSelectVolume: (vol) => onOpenReader(
                            bookItem,
                            volumeKey: vol.volumeKey,
                            assetPath: vol.assetPath,
                          ),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: bookItem.volumes!.map((vol) {
                  return ActionChip(
                    avatar: Icon(
                      Icons.bookmark_border,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(vol.name),
                    onPressed: () => onOpenReader(
                      bookItem,
                      volumeKey: vol.volumeKey,
                      assetPath: vol.assetPath,
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: Icon(
                    bookItem.isWeb
                        ? Icons.open_in_browser_rounded
                        : Icons.menu_book,
                    size: 18,
                  ),
                  label: Text(bookItem.isWeb ? 'Read Online' : 'Read Book'),
                  onPressed: () => onOpenReader(bookItem),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
