import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';

class BibleTranslationSelectorCard extends StatelessWidget {
  final String primaryCode;
  final String? compareCode;
  final Function(BibleTranslationTarget target) onOpenSelector;
  final VoidCallback onSwap;
  final VoidCallback onClearCompare;

  const BibleTranslationSelectorCard({
    super.key,
    required this.primaryCode,
    required this.compareCode,
    required this.onOpenSelector,
    required this.onSwap,
    required this.onClearCompare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryItem = BibleTranslationInfo.getByCode(primaryCode);
    final compareItem = compareCode == null || compareCode == 'none'
        ? null
        : BibleTranslationInfo.getByCode(compareCode!);

    return Card(
      key: const ValueKey('bible_translation_selector_card'),
      margin: EdgeInsets.zero,
      elevation: 6.0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            // Primary Translation Selector Button
            Expanded(
              child: InkWell(
                onTap: () => onOpenSelector(BibleTranslationTarget.primary),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Translation',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        primaryItem.shortName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Swap Translations Button
            IconButton(
              icon: Icon(
                Icons.swap_horiz,
                color: compareItem != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 22,
              ),
              tooltip: 'Swap Primary & Secondary',
              onPressed: compareItem == null ? null : onSwap,
            ),
            const SizedBox(width: 4),

            // Secondary Translation Selector Button & Clear Button
            Expanded(
              child: InkWell(
                onTap: () => onOpenSelector(BibleTranslationTarget.compare),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Secondary Translation',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (compareItem != null) ...[
                            InkWell(
                              onTap: onClearCompare,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        compareItem?.shortName ?? 'None',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: compareItem == null
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
