import 'discernment_models.dart';

/// Full state machine for the 16-entrant single elimination tournament.
class TournamentState {
  final List<TournamentSeed> initialSeeds;
  final List<List<TournamentMatch>> rounds;
  int currentRoundIndex;
  int currentMatchIndex;

  TournamentState({
    required this.initialSeeds,
    required this.rounds,
    this.currentRoundIndex = 0,
    this.currentMatchIndex = 0,
  });

  int get totalMatches => 15; // 8 + 4 + 2 + 1

  int get completedMatchCount {
    int count = 0;
    for (final round in rounds) {
      for (final match in round) {
        if (match.isDecided) count++;
      }
    }
    return count;
  }

  TournamentMatch? get currentMatch {
    if (isComplete) return null;
    if (currentRoundIndex < rounds.length &&
        currentMatchIndex < rounds[currentRoundIndex].length) {
      return rounds[currentRoundIndex][currentMatchIndex];
    }
    return null;
  }

  bool get isComplete {
    return rounds.isNotEmpty &&
        rounds.last.isNotEmpty &&
        rounds.last.first.isDecided;
  }

  TournamentSeed? get champion {
    if (isComplete) {
      return rounds.last.first.winner;
    }
    return null;
  }

  void recordWinner(TournamentSeed winner) {
    if (isComplete) return;
    final match = currentMatch;
    if (match == null) return;

    match.winner = winner;

    // Propagate winner to next round
    final nextRoundIdx = currentRoundIndex + 1;
    if (nextRoundIdx < rounds.length) {
      final nextMatchIdx = currentMatchIndex ~/ 2;
      final nextMatch = rounds[nextRoundIdx][nextMatchIdx];
      if (currentMatchIndex % 2 == 0) {
        rounds[nextRoundIdx][nextMatchIdx] = TournamentMatch(
          round: nextRoundIdx,
          matchIndex: nextMatchIdx,
          entrant1: winner,
          entrant2: nextMatch.entrant2,
          winner: nextMatch.winner,
        );
      } else {
        rounds[nextRoundIdx][nextMatchIdx] = TournamentMatch(
          round: nextRoundIdx,
          matchIndex: nextMatchIdx,
          entrant1: nextMatch.entrant1,
          entrant2: winner,
          winner: nextMatch.winner,
        );
      }
    }

    // Advance to next match
    currentMatchIndex++;
    if (currentMatchIndex >= rounds[currentRoundIndex].length) {
      currentRoundIndex++;
      currentMatchIndex = 0;
    }
  }
}
