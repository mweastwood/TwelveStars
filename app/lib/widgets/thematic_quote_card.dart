import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/thematic_database.dart';

class ThematicQuoteCard extends StatelessWidget {
  final ThematicPassage passage;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpenReaderContext;
  final ValueChanged<String>? onShowSaintDetails;

  const ThematicQuoteCard({
    super.key,
    required this.passage,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onOpenReaderContext,
    this.onShowSaintDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Source Title + Bookmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passage.bookTitle.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          passage.sectionTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isBookmarked
                          ? Colors.redAccent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onToggleBookmark,
                  ),
                ],
              ),

              const Divider(height: 20),

              // Quote Body & Insight Excerpt
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 36,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        passage.keyExcerpt.isNotEmpty
                            ? passage.keyExcerpt
                            : passage.fullText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'serif',
                          fontSize: 19,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Insight / Summary Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                passage.oneSentenceSummary,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Author attribution and Jump Link
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap:
                          passage.authorSaintId != null &&
                                  onShowSaintDetails != null
                              ? () => onShowSaintDetails!(passage.authorSaintId!)
                              : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                passage.author,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration:
                                      passage.authorSaintId != null
                                          ? TextDecoration.underline
                                          : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: onOpenReaderContext,
                    icon: const Icon(Icons.auto_stories_rounded, size: 16),
                    label: const Text('Read in Context'),
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
