import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';

/// Modal dialog / sheet widget to display the visual 16-entrant tournament bracket tree.
class ConfirmationBracketView extends StatelessWidget {
  final TournamentState tournament;

  const ConfirmationBracketView({super.key, required this.tournament});

  static const double _kMatchCardWidth = 170.0;
  static const double _kMatchCardHeight = 68.0;
  static const double _kRound0Gap = 16.0;
  static const double _kSlotHeight0 = _kMatchCardHeight + _kRound0Gap; // 84.0
  static const double _kTotalBracketHeight = 8 * _kSlotHeight0; // 672.0
  static const double _kHeaderHeight = 32.0;
  static const double _kConnectorWidth = 24.0;
  static const double _kChampionCardHeight = 112.0;

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
              _buildConnectorColumn(theme, targetRound: 1),
              _buildRoundColumn(
                context,
                title: 'Quarterfinals',
                matches: tournament.rounds[1],
                theme: theme,
              ),
              _buildConnectorColumn(theme, targetRound: 2),
              _buildRoundColumn(
                context,
                title: 'Semifinals',
                matches: tournament.rounds[2],
                theme: theme,
              ),
              _buildConnectorColumn(theme, targetRound: 3),
              _buildRoundColumn(
                context,
                title: 'Championship',
                matches: tournament.rounds[3],
                theme: theme,
                isFinal: true,
              ),
              if (tournament.champion != null) ...[
                _buildConnectorColumn(theme, targetRound: 3),
                _buildChampionColumn(context, tournament.champion!, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _matchTopOffset(int round, int matchIndex) {
    final double initialOffset = ((1 << round) - 1) * 0.5 * _kSlotHeight0;
    final double spacing = (1 << round) * _kSlotHeight0;
    return initialOffset + matchIndex * spacing;
  }

  Widget _buildRoundColumn(
    BuildContext context, {
    required String title,
    required List<TournamentMatch> matches,
    required ThemeData theme,
    bool isFinal = false,
  }) {
    final round = matches.isNotEmpty ? matches.first.round : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: _kHeaderHeight,
          child: Center(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        SizedBox(
          width: _kMatchCardWidth,
          height: _kTotalBracketHeight,
          child: Stack(
            children: [
              for (int i = 0; i < matches.length; i++)
                Positioned(
                  top: _matchTopOffset(round, i),
                  left: 0,
                  right: 0,
                  child: _buildMatchCard(context, matches[i], theme),
                ),
            ],
          ),
        ),
      ],
    );
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
      width: _kMatchCardWidth,
      height: _kMatchCardHeight,
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
        children: [
          Expanded(
            child: _buildEntrantTile(match.entrant1, match.winner, theme),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: _buildEntrantTile(match.entrant2, match.winner, theme),
          ),
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'TBD',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final isWinner = winner != null && winner.seed == entrant.seed;
    final isLoser = winner != null && !isWinner;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.amber.withValues(alpha: 0.15)
            : Colors.transparent,
      ),
      alignment: Alignment.center,
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

  Widget _buildConnectorColumn(ThemeData theme, {required int targetRound}) {
    final int count = 8 >> targetRound;
    const double iconSize = 20.0;
    return Column(
      children: [
        const SizedBox(height: _kHeaderHeight),
        SizedBox(
          width: _kConnectorWidth,
          height: _kTotalBracketHeight,
          child: Stack(
            children: [
              for (int i = 0; i < count; i++)
                Positioned(
                  top:
                      _matchTopOffset(targetRound, i) +
                      (_kMatchCardHeight - iconSize) / 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.outlineVariant,
                      size: iconSize,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChampionColumn(
    BuildContext context,
    TournamentSeed champion,
    ThemeData theme,
  ) {
    final double champTop =
        _matchTopOffset(3, 0) + (_kMatchCardHeight - _kChampionCardHeight) / 2;

    return Column(
      children: [
        const SizedBox(height: _kHeaderHeight),
        SizedBox(
          width: _kMatchCardWidth,
          height: _kTotalBracketHeight,
          child: Stack(
            children: [
              Positioned(
                top: champTop,
                left: 0,
                right: 0,
                child: Container(
                  height: _kChampionCardHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CHAMPION',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.amber.shade900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        champion.saint.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
