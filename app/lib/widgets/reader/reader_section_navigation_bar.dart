import 'package:flutter/material.dart';

class ReaderSectionNavigationBar extends StatelessWidget {
  final int currentIndex;
  final int totalSections;
  final String? sectionTitle;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const ReaderSectionNavigationBar({
    super.key,
    required this.currentIndex,
    required this.totalSections,
    this.sectionTitle,
    this.onPrevious,
    this.onNext,
  });

  bool get _canGoPrevious => currentIndex > 0 && onPrevious != null;
  bool get _canGoNext => currentIndex < totalSections - 1 && onNext != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTitle = sectionTitle != null && sectionTitle!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('prev_section_button'),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Section',
            onPressed: _canGoPrevious ? onPrevious : null,
          ),
          Expanded(
            child: hasTitle
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Section ${currentIndex + 1} of $totalSections',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        sectionTitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Text(
                    'Section ${currentIndex + 1} of $totalSections',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          IconButton(
            key: const Key('next_section_button'),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Section',
            onPressed: _canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}
