import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_models.dart';

/// Modal bottom sheet widget displaying detailed biographical, liturgical,
/// and patronage information for a [Saint].
class SaintDetailsSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Expanded(
                    child: Text(
                      saint.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (saint.isDoctor)
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
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
              const SizedBox(height: 12),

              if (saint.patronage != null && saint.patronage!.isNotEmpty) ...[
                _buildInfoRow(
                  context,
                  icon: Icons.shield_outlined,
                  label: 'Patronage',
                  value: saint.patronage!,
                ),
                const SizedBox(height: 12),
              ],

              if (saint.summary != null && saint.summary!.isNotEmpty) ...[
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Confirmation Tip: Choose a confirmation patron saint whose virtues and life inspire your Christian vocation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
