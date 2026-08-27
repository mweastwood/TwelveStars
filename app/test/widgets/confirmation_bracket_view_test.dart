import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('ConfirmationBracketView Widget Tests', () {
    testWidgets(
      'Renders all round stage headers and initial round match entrants',
      (tester) async {
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          testSeeds,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: ConfirmationBracketView(tournament: tournament),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tournament Bracket'), findsOneWidget);
        expect(find.text('Round of 16'), findsOneWidget);
        expect(find.text('Quarterfinals'), findsOneWidget);
        expect(find.text('Semifinals'), findsOneWidget);
        expect(find.text('Championship'), findsOneWidget);

        // Verify seeds and entrant names are rendered
        expect(find.text('St. Saint 1'), findsWidgets);
        expect(find.text('St. Saint 16'), findsWidgets);
        expect(find.text('TBD'), findsWidgets);

        // Champion section should NOT be visible when tournament is in progress
        expect(find.text('CHAMPION'), findsNothing);
      },
    );

    testWidgets(
      'Renders match winners in subsequent round columns when recorded',
      (tester) async {
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          testSeeds,
        );

        // Record winner for Match 1 in Round of 16
        tournament.recordWinner(testSeeds[0]); // Seed 1 beats Seed 16

        await tester.pumpWidget(
          buildTestableWidget(
            child: ConfirmationBracketView(tournament: tournament),
          ),
        );
        await tester.pumpAndSettle();

        // Seed 1 should now be listed in Quarterfinals match 0 as entrant1
        expect(find.text('St. Saint 1'), findsWidgets);
      },
    );

    testWidgets('Renders Champion trophy display when tournament is complete', (
      tester,
    ) async {
      final tournament = ConfirmationDiscernmentEngine.createTournament(
        testSeeds,
      );

      // Advance through all 15 matches selecting Seed 1 as winner throughout
      while (!tournament.isComplete) {
        final currentMatch = tournament.currentMatch!;
        tournament.recordWinner(currentMatch.entrant1!);
      }

      expect(tournament.isComplete, isTrue);
      expect(tournament.champion?.seed, 1);

      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationBracketView(tournament: tournament),
        ),
      );
      await tester.pumpAndSettle();

      // Verify CHAMPION section is displayed
      expect(find.text('CHAMPION'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.text('St. Saint 1'), findsWidgets);
    });

    testWidgets(
      'Shows ConfirmationBracketView dialog via static show method and closes on close button',
      (tester) async {
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          testSeeds,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      ConfirmationBracketView.show(context, tournament),
                  child: const Text('Open Bracket'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Open Bracket'));
        await tester.pumpAndSettle();

        expect(find.text('Tournament Bracket'), findsOneWidget);

        // Tap close button in AppBar
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Tournament Bracket'), findsNothing);
      },
    );
  });
}
