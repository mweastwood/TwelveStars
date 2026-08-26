import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfirmationDiscernmentEngine Tests', () {
    test('Question bank has exactly 32 well-formed questions', () {
      expect(ConfirmationDiscernmentEngine.questionBank.length, 32);

      final ids = <String>{};
      for (final q in ConfirmationDiscernmentEngine.questionBank) {
        expect(ids.add(q.id), isTrue, reason: 'Duplicate question ID ${q.id}');
        expect(q.title.isNotEmpty, isTrue);
        expect(q.options.length, greaterThanOrEqualTo(2));
        for (final opt in q.options) {
          expect(opt.text.isNotEmpty, isTrue);
          expect(opt.weights.isNotEmpty, isTrue);
          for (final w in opt.weights.values) {
            expect(w, inInclusiveRange(-1.0, 1.0));
          }
        }
      }
    });

    test('Stratified question down-selection covers all 6 dimensions', () {
      final selected = ConfirmationDiscernmentEngine.selectQuestions(
        count: 7,
        random: Random(42),
      );
      expect(selected.length, 7);

      final axesCovered = selected
          .where((q) => q.primaryAxis != null)
          .map((q) => q.primaryAxis!)
          .toSet();

      // All 6 core dimensions must be represented
      for (final axis in DiscernmentAxis.values) {
        expect(
          axesCovered.contains(axis),
          isTrue,
          reason: 'Axis $axis must be covered',
        );
      }
    });

    test(
      'selectQuestions backfills from unselected questions when count > 8',
      () {
        final selected = ConfirmationDiscernmentEngine.selectQuestions(
          count: 12,
          random: Random(42),
        );
        expect(selected.length, 12);
        expect(selected.toSet().length, 12); // All unique questions
      },
    );

    test('calculateUserVector returns normalized 6D preference vector', () {
      final questions = ConfirmationDiscernmentEngine.selectQuestions(
        count: 7,
        random: Random(100),
      );

      // Select first option for every question
      final answers = {for (final q in questions) q.id: 0};

      final vector = ConfirmationDiscernmentEngine.calculateUserVector(
        answers,
        questions,
      );

      expect(vector.length, 6);
      for (final val in vector) {
        expect(val, inInclusiveRange(-1.0, 1.0));
      }
    });

    test(
      'selectQuestions respects count < 6 without returning extra questions',
      () {
        final selected = ConfirmationDiscernmentEngine.selectQuestions(
          count: 5,
          random: Random(42),
        );
        expect(selected.length, 5);
      },
    );

    test(
      'generateTournamentSeeds handles fewer than 16 candidates by cycling',
      () async {
        SaintDatabase.mockSaints = null;
        final allSaints = (await SaintDatabase.loadSaints()).take(5).toList();
        expect(allSaints.length, 5);

        final userVector = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

        final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: allSaints,
          userVector: userVector,
          count: 16,
        );

        expect(seeds.length, 16);
        final tournament = ConfirmationDiscernmentEngine.createTournament(
          seeds,
        );
        expect(tournament.initialSeeds.length, 16);
      },
    );

    test(
      'generateTournamentSeeds generates 16 seeds with match scores and highlights',
      () async {
        SaintDatabase.mockSaints = null;
        final allSaints = await SaintDatabase.loadSaints();
        expect(allSaints.length, greaterThanOrEqualTo(16));

        // User vector leaning intellectual, contemplative, and ancient
        final userVector = [-0.8, -0.9, -0.2, -0.9, 0.2, 0.6];

        final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: allSaints,
          userVector: userVector,
          noiseMagnitude: 0.05,
          random: Random(123),
          count: 16,
        );

        expect(seeds.length, 16);
        for (int i = 0; i < seeds.length; i++) {
          expect(seeds[i].seed, i + 1);
          expect(seeds[i].saint, isNotNull);
          expect(seeds[i].matchPercentage, inInclusiveRange(50, 99));
          expect(seeds[i].primaryHighlight.isNotEmpty, isTrue);
        }
      },
    );

    test(
      'TournamentState handles complete 15-match single-elimination progression',
      () async {
        SaintDatabase.mockSaints = null;
        final allSaints = await SaintDatabase.loadSaints();
        final userVector = [0.5, 0.5, -0.5, 0.5, -0.5, -0.5];

        final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: allSaints,
          userVector: userVector,
          random: Random(42),
        );

        final tournament = ConfirmationDiscernmentEngine.createTournament(
          seeds,
        );
        expect(tournament.isComplete, isFalse);
        expect(tournament.champion, isNull);
        expect(tournament.totalMatches, 15);
        expect(tournament.completedMatchCount, 0);

        // Play through all 15 matches (Round of 16 -> Quarters -> Semis -> Final)
        while (!tournament.isComplete) {
          final match = tournament.currentMatch;
          expect(match, isNotNull);
          expect(match!.isReady, isTrue);

          // Deterministically pick entrant1 as winner
          final chosenWinner = match.entrant1!;
          tournament.recordWinner(chosenWinner);
        }

        expect(tournament.isComplete, isTrue);
        expect(tournament.completedMatchCount, 15);
        expect(tournament.champion, isNotNull);
        // Winner of Match 1 (Seed 1 vs 16) was Seed 1, and won all successive rounds
        expect(tournament.champion!.seed, 1);
      },
    );
  });
}
