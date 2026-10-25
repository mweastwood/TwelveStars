import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/widgets/reader/reader_annotation_chip.dart';

class BibleVerseRow extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final String? compareVerseText;
  final String? alternateVerseNumber;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
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
    this.padding,
    this.margin,
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

  Widget _buildFavoriteChip() {
    return ReaderAnnotationChip.favorite(onTap: onTapFavorite);
  }

  Widget _buildCitationsChip() {
    return ReaderAnnotationChip.citations(
      count: citationsCount,
      onTap: onTapCitations,
    );
  }

  Widget _buildCommentsChip() {
    return ReaderAnnotationChip.comments(
      count: commentsCount,
      onTap: onTapComments,
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
      if (isFavorite) _buildFavoriteChip(),
      if (citationsCount > 0) _buildCitationsChip(),
      if (commentsCount > 0) _buildCommentsChip(),
    ];

    final resolvedMargin = (margin ?? const EdgeInsets.symmetric(vertical: 2.0))
        .resolve(Directionality.of(context));
    final resolvedPadding =
        (padding ?? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0))
            .resolve(Directionality.of(context));
    // When horizontal margin is applied to shift the highlight box (e.g. to avoid
    // overlapping bookmark ribbons in Bible chapter view), compensate the inner
    // padding and verse number container width so the verse number and text remain
    // stationary at their original anchored positions.
    final effectivePadding = EdgeInsets.only(
      left: (resolvedPadding.left - resolvedMargin.left).clamp(
        0.0,
        double.infinity,
      ),
      right: (resolvedPadding.right - resolvedMargin.right).clamp(
        0.0,
        double.infinity,
      ),
      top: resolvedPadding.top,
      bottom: resolvedPadding.bottom,
    );

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final leadMargin = isRtl ? resolvedMargin.right : resolvedMargin.left;
    final leadPadding = isRtl ? resolvedPadding.right : resolvedPadding.left;
    final horizontalShift = (leadMargin - leadPadding).clamp(
      0.0,
      double.infinity,
    );
    final baseNumWidth = hasAlternateVerse
        ? (verseNumText.length > 7 ? 68.0 : 52.0)
        : (verseNumText.length > 2 ? 34.0 : 28.0);
    final effectiveNumWidth = (baseNumWidth - horizontalShift).clamp(
      0.0,
      double.infinity,
    );

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
        padding: effectivePadding,
        margin: resolvedMargin,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: effectiveNumWidth,
                    child: Text(
                      verseNumText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        height: 1.5,
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
                ],
              ),
            ),
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
