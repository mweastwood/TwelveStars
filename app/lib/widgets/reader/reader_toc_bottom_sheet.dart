import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';

class ReaderTocBottomSheet extends StatelessWidget {
  final String? documentTitle;
  final List<ReaderTocEntry> tocEntries;
  final int currentSectionIndex;
  final ValueChanged<int> onSectionSelected;
  final bool popOnSelect;
  final ScrollController? scrollController;

  const ReaderTocBottomSheet({
    super.key,
    this.documentTitle,
    required this.tocEntries,
    required this.currentSectionIndex,
    required this.onSectionSelected,
    this.popOnSelect = true,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    String? documentTitle,
    required List<ReaderTocEntry> tocEntries,
    required int currentSectionIndex,
    required ValueChanged<int> onSectionSelected,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ReaderTocBottomSheet(
              documentTitle: documentTitle,
              tocEntries: tocEntries,
              currentSectionIndex: currentSectionIndex,
              onSectionSelected: onSectionSelected,
              popOnSelect: true,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.list_alt, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table of Contents',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (documentTitle != null && documentTitle!.isNotEmpty)
                      Text(
                        documentTitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: tocEntries.length,
              itemBuilder: (context, index) {
                final entry = tocEntries[index];
                final isSelected = entry.index == currentSectionIndex;

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    entry.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle:
                      (entry.subtitle != null && entry.subtitle!.isNotEmpty)
                      ? Text(
                          entry.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () {
                    onSectionSelected(entry.index);
                    if (popOnSelect) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
