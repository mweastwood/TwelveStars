import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart' show LectionaryReading;
import 'package:twelve_stars/logic/liturgical_calendar.dart';

class MissalSectionHeader extends StatelessWidget {
  final String title;

  const MissalSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}

class MissalMassPartPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const MissalMassPartPlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}

class MissalLiturgicalCard extends StatelessWidget {
  final LiturgicalDay currentDay;

  const MissalLiturgicalCard({super.key, required this.currentDay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 10, color: currentDay.colorWidget),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentDay.seasonName.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Cycle ${currentDay.sundayCycle} • Year ${currentDay.weekdayCycle}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentDay.weekName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.lens,
                          size: 10,
                          color: currentDay.colorWidget,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Color: ${currentDay.colorName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MissalFeastAlertCard extends StatelessWidget {
  final LiturgicalDay currentDay;

  const MissalFeastAlertCard({super.key, required this.currentDay});

  @override
  Widget build(BuildContext context) {
    if (currentDay.name == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: currentDay.colorWidget.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.church, color: currentDay.colorWidget, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOLEMNITY / FEAST',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: currentDay.colorWidget,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentDay.name!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MissalHomilySectionCard extends StatelessWidget {
  final LiturgicalDay currentDay;
  final List<LectionaryReading> readings;
  final void Function(
    BuildContext context,
    LiturgicalDay day,
    List<LectionaryReading> readings,
  )
  onOpenHomilyReflection;

  const MissalHomilySectionCard({
    super.key,
    required this.currentDay,
    required this.readings,
    required this.onOpenHomilyReflection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.hearing, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Homily',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reflective instruction by the priest',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (readings.isNotEmpty) ...[
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () =>
                    onOpenHomilyReflection(context, currentDay, readings),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('AI Reflection'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
