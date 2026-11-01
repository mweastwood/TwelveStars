import 'package:flutter/material.dart';

/// Renders the prayer title and optional subtitle header in single-language
/// or dual-language side-by-side comparison mode.
class PrayerVersionHeader extends StatelessWidget {
  final String primaryTitle;
  final String primarySubtitle;
  final bool isDualMode;
  final String? compareTitle;
  final String? compareSubtitle;

  const PrayerVersionHeader({
    super.key,
    required this.primaryTitle,
    this.primarySubtitle = '',
    this.isDualMode = false,
    this.compareTitle,
    this.compareSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isDualMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column Title/Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (primarySubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    primarySubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 32,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          // Right Column Title/Subtitle with padding to avoid
          // overlaying split button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    compareTitle ?? '',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (compareSubtitle != null &&
                      compareSubtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      compareSubtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primaryTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (primarySubtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              primarySubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders the floating AI translation explainer action button anchored to the
/// selected target phrase via [layerLink].
class PrayerFloatingExplainButton extends StatelessWidget {
  final LayerLink layerLink;
  final double followerDx;
  final VoidCallback onPressed;

  const PrayerFloatingExplainButton({
    super.key,
    required this.layerLink,
    this.followerDx = 12.0,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.centerRight,
      followerAnchor: Alignment.centerLeft,
      offset: Offset(followerDx, 0),
      child: SizedBox(
        width: 28,
        height: 28,
        child: FloatingActionButton.small(
          onPressed: onPressed,
          elevation: 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.auto_awesome, size: 14),
        ),
      ),
    );
  }
}

/// Renders pagination indicator dots when multiple versions exist for a prayer.
class PrayerVersionDots extends StatelessWidget {
  final int versionCount;
  final int currentIndex;

  const PrayerVersionDots({
    super.key,
    required this.versionCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(versionCount, (index) {
        final isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        );
      }),
    );
  }
}
