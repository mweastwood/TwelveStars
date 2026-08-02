import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';

class ReaderTocBottomSheet extends StatelessWidget {
  final String documentTitle;
  final List<ReaderTocEntry> tocEntries;
  final int currentSectionIndex;
  final ValueChanged<int> onSectionSelected;

  const ReaderTocBottomSheet({
    super.key,
    required this.documentTitle,
    required this.tocEntries,
    required this.currentSectionIndex,
    required this.onSectionSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String documentTitle,
    required List<ReaderTocEntry> tocEntries,
    required int currentSectionIndex,
    required ValueChanged<int> onSectionSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
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
                      ),
                    ),
                    Text(
                      documentTitle,
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
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: tocEntries.length,
            itemBuilder: (context, index) {
              final entry = tocEntries[index];
              final isSelected = entry.index == currentSectionIndex;

              return ListTile(
                selected: isSelected,
                selectedTileColor: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                title: Text(
                  entry.title,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: entry.subtitle != null ? Text(entry.subtitle!) : null,
                onTap: () {
                  onSectionSelected(entry.index);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
