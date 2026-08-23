import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

/// Card-based presentation for a [Saint] aligning with the prayer card aesthetic.
class SaintCard extends StatelessWidget {
  final Saint saint;
  final VoidCallback? onTap;

  const SaintCard({super.key, required this.saint, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = saint.categoryColor(theme);

    return Card(
      key: Key('saint_tile_${saint.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: AppThemeTokens.cardRadius,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => SaintDetailsSheet.show(context, saint),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Icon Avatar + Saint Name & Badges + Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(saint.categoryIcon, color: catColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                saint.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (saint.isDoctor) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Doctor of the Church',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.amber.shade700,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Doctor',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              color: Colors.amber.shade900,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (saint.isBlessed) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Blessed',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (saint.dateRange.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            saint.dateRange,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 2. Metadata Tags: Feast Day, Nationality, Category
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (saint.feastDay != null && saint.feastDay!.isNotEmpty)
                    _buildPill(
                      theme,
                      icon: Icons.calendar_month_outlined,
                      label: saint.feastDay!,
                      isFeast: true,
                    ),
                  if (saint.nationality.isNotEmpty)
                    _buildPill(
                      theme,
                      icon: Icons.public_outlined,
                      label: saint.nationality,
                    ),
                  _buildPill(
                    theme,
                    icon: saint.categoryIcon,
                    label: saint.category.label,
                    tintColor: catColor,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 3. Vocation / Profession
              Text(
                saint.profession,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // 4. Patronage Highlight
              if (saint.patronage != null && saint.patronage!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        saint.patronage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // 5. Summary snippet
              if (saint.summary != null && saint.summary!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  saint.summary!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.85,
                    ),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(
    ThemeData theme, {
    required IconData icon,
    required String label,
    bool isFeast = false,
    Color? tintColor,
  }) {
    final bgColor = isFeast
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
        : tintColor != null
        ? tintColor.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final textColor = isFeast
        ? theme.colorScheme.primary
        : tintColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
