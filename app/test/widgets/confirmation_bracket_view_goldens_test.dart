import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/confirmation_bracket_view.dart';
import '../test_helper.dart';

void main() {
  late List<TournamentSeed> testSeeds;

  setUp(() {
    testSeeds = List.generate(
      16,
      (i) => TournamentSeed(
        seed: i + 1,
        saint: Saint(
          id: 'saint_${i + 1}',
          name: 'St. Saint ${i + 1}',
          nationality: 'Italian',
          profession: 'Confessor',
        ),
        matchScore: 0.95 - (i * 0.02),
        primaryHighlight: 'Highlight ${i + 1}',
      ),
    );
  });

  group('ConfirmationBracketView Golden Tests', () {
    testGoldens(
      'renders bracket with all rounds at tournament start (light theme)',
      (tester) async {
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          testSeeds,
        );

        await tester.pumpWidgetBuilder(
          ConfirmationBracketView(tournament: tournament),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(900, 700),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'confirmation_bracket_view_initial_light_golden',
        );
      },
    );

    testGoldens(
      'renders bracket with all rounds at tournament start (dark theme)',
      (tester) async {
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          testSeeds,
        );

        await tester.pumpWidgetBuilder(
          ConfirmationBracketView(tournament: tournament),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(900, 700),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'confirmation_bracket_view_initial_dark_golden',
        );
      },
    );

    testGoldens(
      'renders bracket with partial results after Round of 16 completed',
      (tester) async {
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          testSeeds,
        );

        // Complete all 8 Round-of-16 matches (always pick entrant1 / top seed)
        for (int i = 0; i < 8; i++) {
          final match = tournament.currentMatch!;
          tournament.recordWinner(match.entrant1!);
        }
        expect(tournament.currentRoundIndex, 1); // Now in Quarterfinals

        await tester.pumpWidgetBuilder(
          ConfirmationBracketView(tournament: tournament),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(900, 700),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'confirmation_bracket_view_quarterfinals_golden',
        );
      },
    );

    testGoldens(
      'renders bracket with champion trophy display when tournament is complete',
      (tester) async {
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          testSeeds,
        );

        // Advance through all 15 matches, always choosing entrant1
        while (!tournament.isComplete) {
          final match = tournament.currentMatch!;
          tournament.recordWinner(match.entrant1!);
        }
        expect(tournament.isComplete, isTrue);
        expect(tournament.champion?.seed, 1);

        await tester.pumpWidgetBuilder(
          ConfirmationBracketView(tournament: tournament),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(1100, 700),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'confirmation_bracket_view_champion_golden',
        );
      },
    );
  });
}
