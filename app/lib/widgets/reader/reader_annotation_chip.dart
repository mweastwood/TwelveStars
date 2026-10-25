import 'package:flutter/material.dart';

/// Visual style variant for [ReaderAnnotationChip].
enum ReaderAnnotationChipVariant {
  /// Primary container styling (used for Favorites / Starred items).
  favorite,

  /// Secondary container styling (used for Comments / Notes).
  comments,

  /// Tertiary container styling (used for Library / Reverse Citations).
  citations,
}

/// Reusable pill chip displaying an annotation badge (favorite star, comment
/// count/label, or reverse citation count) in Bible and Library reader views.
class ReaderAnnotationChip extends StatelessWidget {
  final ReaderAnnotationChipVariant variant;
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const ReaderAnnotationChip({
    super.key,
    required this.variant,
    required this.icon,
    this.label,
    this.onTap,
  });

  /// Creates a favorite star badge (with optional [label], e.g. `'Favorite'`).
  const ReaderAnnotationChip.favorite({super.key, this.label, this.onTap})
    : variant = ReaderAnnotationChipVariant.favorite,
      icon = Icons.star_rounded;

  /// Creates a comments/notes badge displaying [count] or [label].
  factory ReaderAnnotationChip.comments({
    Key? key,
    int? count,
    String? label,
    VoidCallback? onTap,
  }) {
    return ReaderAnnotationChip(
      key: key,
      variant: ReaderAnnotationChipVariant.comments,
      icon: Icons.comment_rounded,
      label: label ?? (count != null ? '$count' : null),
      onTap: onTap,
    );
  }

  /// Creates a reverse-citations badge displaying [count] or [label].
  factory ReaderAnnotationChip.citations({
    Key? key,
    int? count,
    String? label,
    VoidCallback? onTap,
  }) {
    return ReaderAnnotationChip(
      key: key,
      variant: ReaderAnnotationChipVariant.citations,
      icon: Icons.auto_stories_rounded,
      label: label ?? (count != null ? '$count' : null),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color backgroundColor;
    final Color borderColor;
    final Color foregroundColor;

    switch (variant) {
      case ReaderAnnotationChipVariant.favorite:
        backgroundColor = theme.colorScheme.primaryContainer.withValues(
          alpha: 0.8,
        );
        borderColor = theme.colorScheme.primary.withValues(alpha: 0.4);
        foregroundColor = theme.colorScheme.onPrimaryContainer;
      case ReaderAnnotationChipVariant.comments:
        backgroundColor = theme.colorScheme.secondaryContainer.withValues(
          alpha: 0.8,
        );
        borderColor = theme.colorScheme.secondary.withValues(alpha: 0.4);
        foregroundColor = theme.colorScheme.onSecondaryContainer;
      case ReaderAnnotationChipVariant.citations:
        backgroundColor = theme.colorScheme.tertiaryContainer.withValues(
          alpha: 0.8,
        );
        borderColor = theme.colorScheme.tertiary.withValues(alpha: 0.4);
        foregroundColor = theme.colorScheme.onTertiaryContainer;
    }

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foregroundColor),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return pill;
    }

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: pill,
    );
  }
}
