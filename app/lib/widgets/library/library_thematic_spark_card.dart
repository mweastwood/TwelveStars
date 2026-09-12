import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

class LibraryThematicSparkCard extends StatelessWidget {
  final ThematicPassage passage;
  final bool isBookmarked;
  final VoidCallback onShuffle;
  final VoidCallback onToggleBookmark;
  final ValueChanged<String> onOpenTheme;
  final VoidCallback onOpenReader;

  const LibraryThematicSparkCard({
    super.key,
    required this.passage,
    required this.isBookmarked,
    required this.onShuffle,
    required this.onToggleBookmark,
    required this.onOpenTheme,
    required this.onOpenReader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeTitle = ThematicHelper.getThemeTitle(passage.primaryTheme);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Spark Label + Theme Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "TODAY'S THEMATIC SPARK",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onOpenTheme(passage.primaryTheme),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            themeTitle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quote text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 28,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    passage.keyExcerpt.isNotEmpty
                        ? passage.keyExcerpt
                        : passage.fullText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'serif',
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Summary / Insight box
            if (passage.oneSentenceSummary.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        passage.oneSentenceSummary,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Attribution & Actions Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (passage.authorSaintId != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () async {
                            final saint = await SaintDatabase.getSaintById(
                              passage.authorSaintId!,
                            );
                            if (context.mounted && saint != null) {
                              SaintDetailsSheet.show(context, saint);
                            }
                          },
                          child: Text(
                            '— ${passage.author}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Text(
                          '— ${passage.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        passage.bookTitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Shuffle reflection',
                  icon: const Icon(Icons.shuffle_rounded, size: 20),
                  onPressed: onShuffle,
                ),
                IconButton(
                  tooltip: isBookmarked
                      ? 'Remove bookmark'
                      : 'Bookmark reflection',
                  icon: Icon(
                    isBookmarked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isBookmarked
                        ? Colors.redAccent
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: onToggleBookmark,
                ),
              ],
            ),
            const Divider(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => onOpenTheme(passage.primaryTheme),
                    icon: const Icon(Icons.style_rounded, size: 18),
                    label: const Text('Swipe Theme'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenReader,
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Read in Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
