import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/thematic_database.dart';

/// Modal bottom sheet allowing users to browse and select a thematic category.
class ThematicThemePickerSheet extends StatelessWidget {
  final String selectedThemeId;
  final Map<String, int> themeCounts;
  final ValueChanged<String> onThemeSelected;

  const ThematicThemePickerSheet({
    super.key,
    required this.selectedThemeId,
    required this.themeCounts,
    required this.onThemeSelected,
  });

  /// Displays [ThematicThemePickerSheet] in a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String selectedThemeId,
    required Map<String, int> themeCounts,
    required ValueChanged<String> onThemeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ThematicThemePickerSheet(
        selectedThemeId: selectedThemeId,
        themeCounts: themeCounts,
        onThemeSelected: onThemeSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Select Theme',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ThematicHelper.allThemes.length} Themes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: ThematicHelper.categoryGroups.length,
                itemBuilder: (ctx, idx) {
                  final group = ThematicHelper.categoryGroups[idx];
                  return ExpansionTile(
                    initiallyExpanded: group.themes.containsKey(
                      selectedThemeId,
                    ),
                    leading: Text(
                      group.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(
                      group.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: group.themes.entries.map((entry) {
                      final isSelected = entry.key == selectedThemeId;
                      final count = themeCounts[entry.key] ?? 0;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          entry.value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onThemeSelected(entry.key);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
