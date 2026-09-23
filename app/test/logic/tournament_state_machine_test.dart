import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_models.dart';

Saint _createMockSaint(int id, String name) {
  return Saint(
    id: 'saint_$id',
    name: name,
    title: 'Saint $name',
    feastDay: 'Jan 1',
    patronage: 'Testing',
    bio: 'Bio of $name',
    categories: const [SaintCategory.doctor],
    attributes: const ['Faith', 'Hope'],
    quote: 'Pray always.',
    era: SaintEra.ancient,
  );
}

TournamentSeed _createSeed(int seedNum) {
  return TournamentSeed(
    seed: seedNum,
    saint: _createMockSaint(seedNum, 'Saint $seedNum'),
    matchScore: 0.50 + (16 - seedNum) * 0.03,
    primaryHighlight: 'Highlight for seed $seedNum',
  );
}

List<TournamentSeed> _create16Seeds() {
  return List.generate(16, (i) => _createSeed(i + 1));
}

void main() {
  group('TournamentSeed & TournamentMatch Model Tests', () {
    test('TournamentSeed properties and percentage calculation', () {
      final seed = TournamentSeed(
        seed: 1,
        saint: _createMockSaint(1, 'Francis'),
        matchScore: 0.954,
        primaryHighlight: 'Poverello of Assisi',
      );

      expect(seed.seed, 1);
      expect(seed.saint.name, 'Francis');
      expect(seed.matchScore, 0.954);
      expect(seed.primaryHighlight, 'Poverello of Assisi');
      expect(seed.matchPercentage, 95);
    });

    test('TournamentSeed matchPercentage bounds clamping', () {
      final lowSeed = TournamentSeed(
        seed: 16,
        saint: _createMockSaint(16, 'Test'),
        matchScore: -0.5,
        primaryHighlight: 'Low score',
      );
      expect(lowSeed.matchPercentage, 1);

      final highSeed = TournamentSeed(
        seed: 1,
        saint: _createMockSaint(1, 'Test'),
        matchScore: 1.5,
        primaryHighlight: 'High score',
      );
      expect(highSeed.matchPercentage, 99);
    });

    test('TournamentMatch state and round names', () {
      final entrant1 = _createSeed(1);
      final entrant2 = _createSeed(16);

      final match0 = TournamentMatch(
        round: 0,
        matchIndex: 0,
        entrant1: entrant1,
        entrant2: entrant2,
      );

      expect(match0.round, 0);
      expect(match0.matchIndex, 0);
      expect(match0.isReady, isTrue);
      expect(match0.isDecided, isFalse);
      expect(match0.winner, isNull);
      expect(match0.roundName, 'Round of 16');

      final qfMatch = TournamentMatch(round: 1, matchIndex: 0);
      expect(qfMatch.isReady, isFalse);
      expect(qfMatch.roundName, 'Quarterfinals');

      final sfMatch = TournamentMatch(round: 2, matchIndex: 0);
      expect(sfMatch.roundName, 'Semifinals');

      final finalMatch = TournamentMatch(round: 3, matchIndex: 0);
      expect(finalMatch.roundName, 'Championship Match');

      final customMatch = TournamentMatch(round: 4, matchIndex: 0);
      expect(customMatch.roundName, 'Round 5');
    });
  });

  group('Bracket Initialization Tests', () {
    test('createTournament creates valid 16-seed tournament bracket', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      expect(tournament.initialSeeds.length, 16);
      expect(tournament.rounds.length, 4);
      expect(tournament.totalMatches, 15);
      expect(tournament.completedMatchCount, 0);
      expect(tournament.currentRoundIndex, 0);
      expect(tournament.currentMatchIndex, 0);
      expect(tournament.isComplete, isFalse);
      expect(tournament.champion, isNull);

      // Verify round match counts: 8, 4, 2, 1
      expect(tournament.rounds[0].length, 8);
      expect(tournament.rounds[1].length, 4);
      expect(tournament.rounds[2].length, 2);
      expect(tournament.rounds[3].length, 1);
    });

    test('Canonical seeding pairings for Round of 16', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      final expectedPairings = [
        [1, 16],
        [8, 9],
        [4, 13],
        [5, 12],
        [2, 15],
        [7, 10],
        [3, 14],
        [6, 11],
      ];

      for (int i = 0; i < expectedPairings.length; i++) {
        final match = tournament.rounds[0][i];
        expect(match.round, 0);
        expect(match.matchIndex, i);
        expect(match.isReady, isTrue);
        expect(match.entrant1?.seed, expectedPairings[i][0]);
        expect(match.entrant2?.seed, expectedPairings[i][1]);
        expect(match.isDecided, isFalse);
      }
    });

    test('createTournament throws ArgumentError when seeds count < 16', () {
      final shortSeeds = List.generate(15, (i) => _createSeed(i + 1));
      expect(
        () => ConfirmationDiscernmentEngine.createTournament(shortSeeds),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Matchup Progression & Winner Propagation Tests', () {
    test('currentMatch retrieves current active matchup correctly', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      final match = tournament.currentMatch;
      expect(match, isNotNull);
      expect(match!.round, 0);
      expect(match.matchIndex, 0);
      expect(match.entrant1?.seed, 1);
      expect(match.entrant2?.seed, 16);
    });

    test('recordWinner advances currentMatchIndex and updates match winner', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      final match0 = tournament.currentMatch!;
      final winner = match0.entrant1!;
      tournament.recordWinner(winner);

      expect(match0.isDecided, isTrue);
      expect(match0.winner, winner);
      expect(tournament.completedMatchCount, 1);

      // Advanced to round 0, match 1
      expect(tournament.currentRoundIndex, 0);
      expect(tournament.currentMatchIndex, 1);
      expect(tournament.currentMatch?.entrant1?.seed, 8);
      expect(tournament.currentMatch?.entrant2?.seed, 9);
    });

    test('Winner propagation to entrant1 (even match index) in next round', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      // Round 0, Match 0 (even match index: 0)
      final winnerSeed1 = tournament.currentMatch!.entrant1!;
      tournament.recordWinner(winnerSeed1);

      // Check Round 1, Match 0: entrant1 should be winnerSeed1, entrant2 still null
      final qfMatch0 = tournament.rounds[1][0];
      expect(qfMatch0.entrant1?.seed, 1);
      expect(qfMatch0.entrant2, isNull);
      expect(qfMatch0.isReady, isFalse);
    });

    test('Winner propagation to entrant2 (odd match index) in next round', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      // Win match 0 (Seed 1)
      tournament.recordWinner(tournament.currentMatch!.entrant1!);

      // Round 0, Match 1 (odd match index: 1)
      final winnerSeed8 = tournament.currentMatch!.entrant1!;
      tournament.recordWinner(winnerSeed8);

      // Check Round 1, Match 0: both entrant1 (Seed 1) and entrant2 (Seed 8) set and ready!
      final qfMatch0 = tournament.rounds[1][0];
      expect(qfMatch0.entrant1?.seed, 1);
      expect(qfMatch0.entrant2?.seed, 8);
      expect(qfMatch0.isReady, isTrue);
    });

    test('Progression across all Round of 16 matches to Quarterfinals', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      // Play all 8 Round of 16 matches
      for (int i = 0; i < 8; i++) {
        expect(tournament.currentRoundIndex, 0);
        expect(tournament.currentMatchIndex, i);
        // Entrant 1 wins every match (higher seed wins)
        tournament.recordWinner(tournament.currentMatch!.entrant1!);
      }

      // Should now be at Round 1 (Quarterfinals), match 0
      expect(tournament.currentRoundIndex, 1);
      expect(tournament.currentMatchIndex, 0);
      expect(tournament.completedMatchCount, 8);

      // Verify all 4 Quarterfinal matches are populated and ready
      // Expected QF matchups: 1 vs 8, 4 vs 5, 2 vs 7, 3 vs 6
      final expectedQF = [
        [1, 8],
        [4, 5],
        [2, 7],
        [3, 6],
      ];
      for (int i = 0; i < 4; i++) {
        final match = tournament.rounds[1][i];
        expect(match.isReady, isTrue);
        expect(match.entrant1?.seed, expectedQF[i][0]);
        expect(match.entrant2?.seed, expectedQF[i][1]);
      }
    });

    test('Progression through Quarterfinals to Semifinals', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      // Round 0: Entrant 1 wins all 8 matches
      for (int i = 0; i < 8; i++) {
        tournament.recordWinner(tournament.currentMatch!.entrant1!);
      }

      // Round 1 (Quarterfinals): Play 4 matches, lower seed (entrant2) wins odd matches
      for (int i = 0; i < 4; i++) {
        expect(tournament.currentRoundIndex, 1);
        expect(tournament.currentMatchIndex, i);
        final match = tournament.currentMatch!;
        // Choose entrant1 for even matchIndex, entrant2 for odd matchIndex
        final chosenWinner = (i % 2 == 0) ? match.entrant1! : match.entrant2!;
        tournament.recordWinner(chosenWinner);
      }

      // Advanced to Round 2 (Semifinals), match 0
      expect(tournament.currentRoundIndex, 2);
      expect(tournament.currentMatchIndex, 0);
      expect(tournament.completedMatchCount, 12);

      // Verify Semifinal matchups: SF0 = Seed 1 vs Seed 5, SF1 = Seed 2 vs Seed 6
      final sf0 = tournament.rounds[2][0];
      final sf1 = tournament.rounds[2][1];

      expect(sf0.isReady, isTrue);
      expect(sf0.entrant1?.seed, 1);
      expect(sf0.entrant2?.seed, 5);

      expect(sf1.isReady, isTrue);
      expect(sf1.entrant1?.seed, 2);
      expect(sf1.entrant2?.seed, 6);
    });

    test('Progression through Semifinals to Championship Match', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      // Play 8 R16 matches
      for (int i = 0; i < 8; i++) {
        tournament.recordWinner(tournament.currentMatch!.entrant1!);
      }
      // Play 4 QF matches
      for (int i = 0; i < 4; i++) {
        tournament.recordWinner(tournament.currentMatch!.entrant1!);
      }
      // Play 2 SF matches
      for (int i = 0; i < 2; i++) {
        expect(tournament.currentRoundIndex, 2);
        expect(tournament.currentMatchIndex, i);
        tournament.recordWinner(tournament.currentMatch!.entrant1!);
      }

      // Advanced to Round 3 (Finals), match 0
      expect(tournament.currentRoundIndex, 3);
      expect(tournament.currentMatchIndex, 0);
      expect(tournament.completedMatchCount, 14);

      final finalMatch = tournament.rounds[3][0];
      expect(finalMatch.isReady, isTrue);
      expect(finalMatch.entrant1?.seed, 1);
      expect(finalMatch.entrant2?.seed, 2);
      expect(finalMatch.isDecided, isFalse);
    });
  });

  group('Champion Resolution & State Machine Termination Tests', () {
    test('Final match selection terminates tournament and sets champion', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      // Play through all matches picking entrant1
      while (!tournament.isComplete) {
        final match = tournament.currentMatch;
        expect(match, isNotNull);
        tournament.recordWinner(match!.entrant1!);
      }

      expect(tournament.isComplete, isTrue);
      expect(tournament.completedMatchCount, 15);
      expect(tournament.currentMatch, isNull);

      final champ = tournament.champion;
      expect(champ, isNotNull);
      expect(champ!.seed, 1);
      expect(champ.saint.name, 'Saint 1');
    });

    test('Underdog victory resolution produces correct underdog champion', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      // Play through all matches picking entrant2 (underdog wins every match)
      while (!tournament.isComplete) {
        final match = tournament.currentMatch;
        expect(match, isNotNull);
        tournament.recordWinner(match!.entrant2!);
      }

      expect(tournament.isComplete, isTrue);
      expect(tournament.completedMatchCount, 15);
      expect(tournament.currentMatch, isNull);

      final champ = tournament.champion;
      expect(champ, isNotNull);
      // Seed 11 comes out as champion when entrant2 wins every match in this bracket structure!
      expect(champ!.seed, 11);
    });

    test('Calling recordWinner after tournament is complete is a no-op', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      while (!tournament.isComplete) {
        tournament.recordWinner(tournament.currentMatch!.entrant1!);
      }

      final originalChampion = tournament.champion;
      final extraWinner = _createSeed(16);

      // Call recordWinner when complete
      tournament.recordWinner(extraWinner);

      expect(tournament.isComplete, isTrue);
      expect(tournament.champion, equals(originalChampion));
      expect(tournament.completedMatchCount, 15);
    });

    test('champion getter returns null before tournament completion', () {
      final seeds = _create16Seeds();
      final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

      for (int i = 0; i < 14; i++) {
        expect(tournament.champion, isNull);
        tournament.recordWinner(tournament.currentMatch!.entrant1!);
      }
      expect(tournament.champion, isNull);
      expect(tournament.isComplete, isFalse);

      // 15th match completes tournament
      tournament.recordWinner(tournament.currentMatch!.entrant1!);
      expect(tournament.champion, isNotNull);
      expect(tournament.isComplete, isTrue);
    });
  });

  group('Edge Cases & Boundary Condition Tests', () {
    test('currentMatch returns null when round or match indices are out of bounds', () {
      final seeds = _create16Seeds();
      final tournament = TournamentState(
        initialSeeds: seeds,
        rounds: [
          [TournamentMatch(round: 0, matchIndex: 0)],
        ],
        currentRoundIndex: 5, // Out of bounds
        currentMatchIndex: 0,
      );

      expect(tournament.currentMatch, isNull);

      // Calling recordWinner when currentMatch is null does nothing
      tournament.recordWinner(seeds[0]);
      expect(tournament.currentRoundIndex, 5);
    });

    test('TournamentState handles custom constructor default values', () {
      final seeds = _create16Seeds();
      final match = TournamentMatch(
        round: 0,
        matchIndex: 0,
        entrant1: seeds[0],
        entrant2: seeds[1],
      );

      final tournament = TournamentState(
        initialSeeds: seeds,
        rounds: [
          [match],
        ],
      );

      expect(tournament.currentRoundIndex, 0);
      expect(tournament.currentMatchIndex, 0);
      expect(tournament.totalMatches, 15);
      expect(tournament.completedMatchCount, 0);
    });
  });
}
