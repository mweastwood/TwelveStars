import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';

class BibleVerseRow extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final String? compareVerseText;
  final String? alternateVerseNumber;
  final bool isSelected;
  final double? fontSize;
  final int citationsCount;
  final int commentsCount;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapCitations;
  final VoidCallback? onTapComments;
  final VoidCallback? onTapFavorite;

  const BibleVerseRow({
    super.key,
    required this.verseNumber,
    required this.verseText,
    this.compareVerseText,
    this.alternateVerseNumber,
    this.isSelected = false,
    this.fontSize,
    this.citationsCount = 0,
    this.commentsCount = 0,
    this.isFavorite = false,
    this.onTap,
    this.onLongPress,
    this.onTapCitations,
    this.onTapComments,
    this.onTapFavorite,
  });

  Widget _buildFavoriteChip(BuildContext context, ThemeData theme) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTapFavorite,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 13,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationsChip(BuildContext context, ThemeData theme) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTapCitations,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 13,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$citationsCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsChip(BuildContext context, ThemeData theme) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTapComments,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_rounded,
              size: 13,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$commentsCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = isWideScreen(context);
    final hasAlternateVerse =
        alternateVerseNumber != null && alternateVerseNumber!.isNotEmpty;
    final verseNumText = hasAlternateVerse
        ? '$verseNumber ($alternateVerseNumber)'
        : '$verseNumber';

    final chips = <Widget>[
      if (isFavorite) _buildFavoriteChip(context, theme),
      if (citationsCount > 0) _buildCitationsChip(context, theme),
      if (commentsCount > 0) _buildCommentsChip(context, theme),
    ];

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        margin: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: hasAlternateVerse
                  ? 52
                  : (verseNumText.length > 2 ? 34 : 28),
              child: Text(
                verseNumText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: fontSize != null
                      ? (fontSize! * 0.85).clamp(10.0, 20.0)
                      : (hasAlternateVerse ? 11.0 : null),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
            if (compareVerseText == null)
              Expanded(
                child: Text(
                  verseText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: fontSize,
                    height: 1.5,
                  ),
                ),
              )
            else ...[
              Expanded(
                child: Text(
                  verseText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: fontSize,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  compareVerseText!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: fontSize,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (chips.isNotEmpty) ...[
              const SizedBox(width: 8),
              if (isWide)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < chips.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      chips[i],
                    ],
                  ],
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < chips.length; i++) ...[
                      if (i > 0) const SizedBox(height: 4),
                      chips[i],
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
