import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/thematic_database.dart';

class LibraryThematicShelf extends StatelessWidget {
  final ValueChanged<String> onOpenTheme;

  static const List<({String label, String themeId})> _quickTopics = [
    (label: '🕊️ Eucharist', themeId: 'sacraments.eucharist'),
    (label: '🕯️ Mental Prayer', themeId: 'prayer.vocal_mental_meditation'),
    (label: '⚔️ Spiritual Warfare', themeId: 'combat.spiritual_warfare'),
    (label: '👑 Our Lady', themeId: 'devotion.our_lady'),
    (label: '🌿 Humility', themeId: 'virtues.humility_meekness'),
    (label: '🕊️ Confession', themeId: 'sacraments.penance'),
    (label: '⚔️ Suffering & Cross', themeId: 'combat.suffering_cross'),
    (label: '🏛️ Holy Trinity', themeId: 'theology.trinity'),
    (label: '🌿 Faith, Hope & Charity', themeId: 'virtues.faith_hope_charity'),
    (
      label: '👑 Heaven & Eternity',
      themeId: 'eschatology.heaven_beatific_vision',
    ),
  ];

  const LibraryThematicShelf({super.key, required this.onOpenTheme});

  void _showAllThemesPicker(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                        'Explore by Spiritual Theme',
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
                        initiallyExpanded: idx == 0,
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
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              entry.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              onOpenTheme(entry.key);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.explore_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'EXPLORE BY THEME',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showAllThemesPicker(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('All Themes (${ThematicHelper.allThemes.length})'),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Swipe through curated quotations by sacrament, virtue, & doctrine',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // 7 Category Pillars Horizontal List
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ThematicHelper.categoryGroups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final group = ThematicHelper.categoryGroups[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onOpenTheme(group.themes.keys.first),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${group.themes.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        group.name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Quick Topic Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickTopics.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: const Icon(Icons.label_outline_rounded, size: 14),
                  label: Text(item.label),
                  onPressed: () => onOpenTheme(item.themeId),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
