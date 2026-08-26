import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';

/// Modal dialog / sheet widget to display the visual 16-entrant tournament bracket tree.
class ConfirmationBracketView extends StatelessWidget {
  final TournamentState tournament;

  const ConfirmationBracketView({super.key, required this.tournament});

  static Future<void> show(BuildContext context, TournamentState tournament) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConfirmationBracketView(tournament: tournament),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Bracket'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoundColumn(
                context,
                title: 'Round of 16',
                matches: tournament.rounds[0],
                theme: theme,
              ),
              _buildConnectorColumn(theme),
              _buildRoundColumn(
                context,
                title: 'Quarterfinals',
                matches: tournament.rounds[1],
                theme: theme,
              ),
              _buildConnectorColumn(theme),
              _buildRoundColumn(
                context,
                title: 'Semifinals',
                matches: tournament.rounds[2],
                theme: theme,
              ),
              _buildConnectorColumn(theme),
              _buildRoundColumn(
                context,
                title: 'Championship',
                matches: tournament.rounds[3],
                theme: theme,
                isFinal: true,
              ),
              if (tournament.champion != null) ...[
                _buildConnectorColumn(theme),
                _buildChampionColumn(context, tournament.champion!, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundColumn(
    BuildContext context, {
    required String title,
    required List<TournamentMatch> matches,
    required ThemeData theme,
    bool isFinal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (int i = 0; i < matches.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: _verticalSpacingForRound(matches.first.round),
            ),
            child: _buildMatchCard(context, matches[i], theme),
          ),
      ],
    );
  }

  double _verticalSpacingForRound(int round) {
    switch (round) {
      case 0:
        return 6.0;
      case 1:
        return 28.0;
      case 2:
        return 80.0;
      case 3:
        return 180.0;
      default:
        return 8.0;
    }
  }

  Widget _buildMatchCard(
    BuildContext context,
    TournamentMatch match,
    ThemeData theme,
  ) {
    final isCurrentMatch =
        !tournament.isComplete &&
        tournament.currentRoundIndex == match.round &&
        tournament.currentMatchIndex == match.matchIndex;

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: isCurrentMatch
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(
          color: isCurrentMatch
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCurrentMatch ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEntrantTile(match.entrant1, match.winner, theme),
          const Divider(height: 1),
          _buildEntrantTile(match.entrant2, match.winner, theme),
        ],
      ),
    );
  }

  Widget _buildEntrantTile(
    TournamentSeed? entrant,
    TournamentSeed? winner,
    ThemeData theme,
  ) {
    if (entrant == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          'TBD',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    final isWinner = winner != null && winner.seed == entrant.seed;
    final isLoser = winner != null && !isWinner;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.amber.withValues(alpha: 0.15)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${entrant.seed}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entrant.saint.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isLoser
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : isWinner
                    ? Colors.amber.shade900
                    : theme.colorScheme.onSurface,
                decoration: isLoser ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isWinner)
            const Icon(Icons.check_circle, color: Colors.amber, size: 14),
        ],
      ),
    );
  }

  Widget _buildConnectorColumn(ThemeData theme) {
    return Container(
      width: 24,
      alignment: Alignment.center,
      child: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.outlineVariant,
        size: 20,
      ),
    );
  }

  Widget _buildChampionColumn(
    BuildContext context,
    TournamentSeed champion,
    ThemeData theme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 180),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            border: Border.all(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
              const SizedBox(height: 6),
              Text(
                'CHAMPION',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                champion.saint.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
