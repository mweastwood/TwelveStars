import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/widgets/confirmation_bracket_view.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

class ConfirmationTournamentView extends StatelessWidget {
  final TournamentState tournament;
  final ValueChanged<TournamentSeed> onSelectWinner;

  const ConfirmationTournamentView({
    super.key,
    required this.tournament,
    required this.onSelectWinner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final match = tournament.currentMatch;
    if (match == null || !match.isReady) return const SizedBox.shrink();

    final matchNum = tournament.completedMatchCount + 1;
    final totalMatches = tournament.totalMatches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saint Showdown'),
        actions: [
          IconButton(
            key: const Key('view_bracket_button'),
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'View Bracket Tree',
            onPressed: () => ConfirmationBracketView.show(context, tournament),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header progress
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MATCH $matchNum OF $totalMatches • ${match.roundName.toUpperCase()}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.account_tree, size: 14),
                    label: const Text('Bracket'),
                    onPressed: () =>
                        ConfirmationBracketView.show(context, tournament),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Arena Matchup Cards
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  if (isWide) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildMatchupCard(
                              context,
                              seed: match.entrant1!,
                              onSelect: () => onSelectWinner(match.entrant1!),
                              theme: theme,
                              keyPrefix: 'entrant_1',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.amber,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'VS',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildMatchupCard(
                              context,
                              seed: match.entrant2!,
                              onSelect: () => onSelectWinner(match.entrant2!),
                              theme: theme,
                              keyPrefix: 'entrant_2',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Mobile layout (Stacked)
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildMatchupCard(
                          context,
                          seed: match.entrant1!,
                          onSelect: () => onSelectWinner(match.entrant1!),
                          theme: theme,
                          keyPrefix: 'entrant_1',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.amber,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'VS',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ),
                        _buildMatchupCard(
                          context,
                          seed: match.entrant2!,
                          onSelect: () => onSelectWinner(match.entrant2!),
                          theme: theme,
                          keyPrefix: 'entrant_2',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchupCard(
    BuildContext context, {
    required TournamentSeed seed,
    required VoidCallback onSelect,
    required ThemeData theme,
    required String keyPrefix,
  }) {
    final saint = seed.saint;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top badges (Seed + Match %)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SEED #${seed.seed}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${seed.matchPercentage}% Match',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Icon + Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: saint.categoryColor(theme).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: saint.categoryColor(theme).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    saint.categoryIcon,
                    color: saint.categoryColor(theme),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        saint.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (saint.dateRange.isNotEmpty)
                        Text(
                          saint.dateRange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Profession & Patronage
            Text(
              saint.profession,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (saint.patronage != null && saint.patronage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Patron of ${saint.patronage}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Summary excerpt
            if (saint.summary != null) ...[
              if (isWideScreen(context))
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      saint.summary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  saint.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
            ],
            const SizedBox(height: 12),

            // Actions: Read Full Bio & Choose Saint
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => SaintDetailsSheet.show(context, saint),
                  child: const Text('Read Bio'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: Key('${keyPrefix}_select_button'),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      'Choose ${saint.shortName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: onSelect,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
