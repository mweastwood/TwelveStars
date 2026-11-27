import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/saints/saint_sprite.dart';
import 'package:twelve_stars/widgets/saints/saint_ui_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal bottom sheet widget displaying detailed biographical, liturgical,
/// and patronage information for a [Saint].
class SaintDetailsSheet extends StatefulWidget {
  final Saint saint;

  const SaintDetailsSheet({super.key, required this.saint});

  /// Displays the [SaintDetailsSheet] in a modal bottom sheet.
  static Future<void> show(BuildContext context, Saint saint) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SaintDetailsSheet(saint: saint),
    );
  }

  @override
  State<SaintDetailsSheet> createState() => _SaintDetailsSheetState();
}

class _SaintDetailsSheetState extends State<SaintDetailsSheet> {
  int _selectedSpriteIndex = 0;

  Future<void> _openWikipedia(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void didUpdateWidget(covariant SaintDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saint.id != widget.saint.id) {
      _selectedSpriteIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saint = widget.saint;
    final variants = saint.spriteVariants;
    final activeVariant =
        variants[_selectedSpriteIndex.clamp(0, variants.length - 1)];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SaintSpriteAvatar(
                    saint: saint,
                    assetPath: activeVariant.assetPath,
                    size: 72,
                    imageSize: 64,
                    borderRadius: 16,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                saint.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            if (saint.isDoctor) ...[
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Doctor of the Church',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.shade700,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Doctor',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (saint.hasMultipleSprites) ...[
                          const SizedBox(height: 2),
                          Text(
                            activeVariant.label,
                            key: const Key('saint_active_sprite_label'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: saint.categoryColor(theme),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (saint.dateRange.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            saint.dateRange,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (saint.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: saint.categories.map((cat) {
                    final color = cat.color(theme);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 13, color: color),
                          const SizedBox(width: 4),
                          Text(
                            cat.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (saint.hasMultipleSprites) ...[
                const SizedBox(height: 16),
                _buildSpriteGallery(context, saint, variants),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              if (saint.feastDay != null) ...[
                _buildInfoRow(
                  context,
                  icon: Icons.calendar_month_outlined,
                  label: 'Feast Day',
                  value: saint.feastDay!,
                ),
                const SizedBox(height: 12),
              ],

              if (saint.gender != null && saint.gender!.isNotEmpty) ...[
                _buildInfoRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'Gender',
                  value: saint.gender == 'male'
                      ? 'Male'
                      : saint.gender == 'female'
                      ? 'Female'
                      : saint.gender == 'group'
                      ? 'Group'
                      : saint.gender == 'other'
                      ? 'Other (Pure Spirit)'
                      : saint.gender!,
                ),
                const SizedBox(height: 12),
              ],

              _buildInfoRow(
                context,
                icon: Icons.public_outlined,
                label: 'Nationality & Origin',
                value: saint.nationality,
              ),
              const SizedBox(height: 12),

              _buildInfoRow(
                context,
                icon: Icons.work_outline,
                label: 'Vocation & Profession',
                value: saint.profession,
              ),

              if (saint.patronage != null && saint.patronage!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.shield_outlined,
                  label: 'Patronage',
                  value: saint.patronage!,
                ),
              ],

              if (saint.summary != null && saint.summary!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Biography & Significance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  saint.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              if (saint.wikipediaUrl != null &&
                  saint.wikipediaUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('saint_wikipedia_link_button'),
                  onPressed: () => _openWikipedia(saint.wikipediaUrl!),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Read on Wikipedia'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpriteGallery(
    BuildContext context,
    Saint saint,
    List<SaintSpriteVariant> variants,
  ) {
    final theme = Theme.of(context);
    final catColor = saint.categoryColor(theme);

    return Column(
      key: Key('saint_sprite_gallery_${saint.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marian Titles',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            const columns = 3;
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(variants.length, (index) {
                final variant = variants[index];
                final isSelected = index == _selectedSpriteIndex;

                return SizedBox(
                  width: tileWidth,
                  child: Material(
                    color: isSelected
                        ? catColor.withValues(alpha: 0.16)
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: Key('saint_sprite_variant_$index'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedSpriteIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : theme.colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SaintSpriteImage(
                              assetPath: variant.assetPath,
                              size: 48,
                              fallbackIcon: saint.categoryIcon,
                              fallbackColor: catColor,
                              fallbackIconSize: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              variant.displayLabel,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? catColor
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.secondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
