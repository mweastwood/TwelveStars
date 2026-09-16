import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/confirmation_bracket_view.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_champion_view.dart';
import '../../test_helper.dart';

void main() {
  late TournamentState completedTournament;
  final mockChampionSaint = const Saint(
    id: 'therese-of-lisieux',
    name: 'St. Thérèse of Lisieux',
    birthDate: '1873',
    deathDate: '1897',
    nationality: 'French',
    profession: 'Carmelite Nun',
    feastDay: 'October 1',
    patronage: 'Missions, Florists',
    summary:
        'Known as the Little Flower, she taught the "Little Way" of spiritual childhood.',
    isDoctor: true,
    gender: 'female',
    categories: [SaintCategory.doctor, SaintCategory.nun],
  );

  setUp(() {
    final seeds = List.generate(
      16,
      (i) => TournamentSeed(
        seed: i + 1,
        saint: i == 0
            ? mockChampionSaint
            : Saint(
                id: 'saint_${i + 1}',
                name: 'St. Saint ${i + 1}',
                nationality: 'Roman',
                profession: 'Martyr',
              ),
        matchScore: 0.95 - (i * 0.02),
        primaryHighlight: 'Highlight ${i + 1}',
      ),
    );
    completedTournament = ConfirmationDiscernmentEngine.createTournament(seeds);
    // Complete all 15 matches with entrant 1 as winner
    for (int i = 0; i < 15; i++) {
      final match = completedTournament.currentMatch!;
      completedTournament.recordWinner(match.entrant1!);
    }
  });

  group('ConfirmationChampionView Widget Tests', () {
    testWidgets('renders celebratory trophy card, patron details, and prayer', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationChampionView(
            tournament: completedTournament,
            onRestart: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmation Patron Chosen'), findsOneWidget);
      expect(find.text('YOUR CONFIRMATION PATRON SAINT'), findsOneWidget);
      expect(find.text('St. Thérèse of Lisieux'), findsOneWidget);
      expect(find.text('1873 – 1897'), findsOneWidget);
      expect(find.textContaining('Compatibility Match'), findsOneWidget);

      expect(find.text('Patronage & Significance'), findsOneWidget);
      expect(find.text('Vocation: Carmelite Nun'), findsOneWidget);
      expect(find.text('Feast Day: October 1'), findsOneWidget);
      expect(find.text('Patron Saint of: Missions, Florists'), findsOneWidget);
      expect(find.text('Biography Summary'), findsOneWidget);

      expect(find.text('Confirmation Intercessory Prayer'), findsOneWidget);
      expect(
        find.textContaining('St. Thérèse of Lisieux, you lived a life'),
        findsOneWidget,
      );
    });

    testWidgets('copies dossier to clipboard and shows SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationChampionView(
            tournament: completedTournament,
            onRestart: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final copyBtn = find.byKey(const Key('copy_dossier_button'));
      expect(copyBtn, findsOneWidget);
      await tester.ensureVisible(copyBtn);
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Confirmation dossier copied to clipboard!'),
        findsOneWidget,
      );
    });

    testWidgets('opens bracket recap modal on bracket button tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationChampionView(
            tournament: completedTournament,
            onRestart: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bracketBtn = find.text('View Full Tournament Bracket Recap');
      expect(bracketBtn, findsOneWidget);
      await tester.ensureVisible(bracketBtn);
      await tester.tap(bracketBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationBracketView), findsOneWidget);
    });

    testWidgets('calls onRestart on Discern Again tap and AppBar action tap', (
      tester,
    ) async {
      int restartCount = 0;

      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationChampionView(
            tournament: completedTournament,
            onRestart: () {
              restartCount++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap AppBar refresh button
      await tester.tap(find.byTooltip('Start New Discernment'));
      await tester.pumpAndSettle();
      expect(restartCount, equals(1));

      // Tap Discern Again button
      final discernAgainBtn = find.text(
        'Discern Again (New Quiz & Tournament)',
      );
      await tester.ensureVisible(discernAgainBtn);
      await tester.tap(discernAgainBtn);
      await tester.pumpAndSettle();
      expect(restartCount, equals(2));
    });
  });
}
