import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_quiz_view.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_tournament_view.dart';
import '../test_helper.dart';

void main() {
  late List<TournamentSeed> testSeeds;
  late TournamentState tournament;

  setUp(() {
    testSeeds = List.generate(
      16,
      (i) => TournamentSeed(
        seed: i + 1,
        saint: Saint(
          id: 'saint_${i + 1}',
          name: 'St. Saint ${i + 1}',
          nationality: 'Italian',
          profession: 'Doctor of the Church',
          patronage: 'Students',
          summary: 'A detailed biographical summary for saint ${i + 1}. ' * 10,
          categories: [SaintCategory.doctor],
        ),
        matchScore: 0.95 - (i * 0.02),
        primaryHighlight: 'Highlight ${i + 1}',
      ),
    );
    tournament = ConfirmationDiscernmentEngine.createTournament(testSeeds);
  });

  group('ConfirmationTournamentView Layout & Scroll Regression Tests', () {
    testWidgets(
      'renders at viewport width 650.0 (600 <= width < 700) without unbounded Expanded FlutterError',
      (tester) async {
        tester.view.physicalSize = const Size(650, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: ConfirmationTournamentView(
              tournament: tournament,
              onSelectWinner: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Saint Showdown'), findsOneWidget);
        expect(find.text('St. Saint 1'), findsOneWidget);
        expect(find.text('St. Saint 16'), findsOneWidget);
      },
    );

    testWidgets(
      'renders at narrow viewport width 320.0 on Championship round without horizontal overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Advance through first 14 matches to reach Match 15 (Championship Match)
        for (int i = 0; i < 14; i++) {
          tournament.recordWinner(tournament.currentMatch!.entrant1!);
        }
        expect(tournament.completedMatchCount, equals(14));
        expect(
          tournament.currentMatch!.roundName,
          equals('Championship Match'),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: ConfirmationTournamentView(
              tournament: tournament,
              onSelectWinner: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.text('MATCH 15 OF 15 • CHAMPIONSHIP MATCH'),
          findsOneWidget,
        );
        expect(find.text('Bracket'), findsOneWidget);
      },
    );

    testWidgets(
      'scrolling down on narrow viewport and selecting a saint resets scroll position for next match',
      (tester) async {
        tester.view.physicalSize = const Size(375, 500);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: StatefulBuilder(
              builder: (context, setState) {
                return ConfirmationTournamentView(
                  tournament: tournament,
                  onSelectWinner: (winner) {
                    setState(() {
                      tournament.recordWinner(winner);
                    });
                  },
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrollableFinder = find.byType(Scrollable).first;
        final entrant2Button = find.byKey(const Key('entrant_2_select_button'));

        await tester.scrollUntilVisible(
          entrant2Button,
          150.0,
          scrollable: scrollableFinder,
        );
        await tester.pumpAndSettle();

        final scrolledState = tester.state<ScrollableState>(scrollableFinder);
        expect(scrolledState.position.pixels, greaterThan(0.0));

        await tester.tap(entrant2Button);
        await tester.pumpAndSettle();

        expect(find.textContaining('MATCH 2 OF 15'), findsOneWidget);
        final nextScrollableState = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(nextScrollableState.position.pixels, equals(0.0));
      },
    );
  });

  group('ConfirmationQuizView Edge Case & Scroll Regression Tests', () {
    testWidgets(
      'renders with empty questions list without throwing RangeError',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: ConfirmationQuizView(
              questions: const [],
              onRestart: () {},
              onComplete: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Confirmation Discernment'), findsOneWidget);
      },
    );

    testWidgets(
      'passes defensive copy to onComplete and resets scroll position between questions',
      (tester) async {
        tester.view.physicalSize = const Size(375, 450);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final questions = [
          DiscernmentQuestion(
            id: 'q1',
            title: 'Question 1 with many options',
            options: List.generate(
              6,
              (i) => DiscernmentOption(
                text: 'Option 1.$i',
                subtitle: 'Detailed description for option 1.$i ' * 3,
                weights: const {DiscernmentAxis.contemplativeVsActive: 1.0},
              ),
            ),
          ),
          const DiscernmentQuestion(
            id: 'q2',
            title: 'Question 2',
            options: [
              DiscernmentOption(
                text: 'Option 2.0',
                weights: {DiscernmentAxis.intellectualVsDevotional: 1.0},
              ),
            ],
          ),
        ];

        Map<String, int>? capturedAnswers;

        await tester.pumpWidget(
          buildTestableWidget(
            child: ConfirmationQuizView(
              questions: questions,
              onRestart: () {},
              onComplete: (answers) {
                capturedAnswers = answers;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrollableFinder = find.byType(Scrollable).first;
        final lastOption = find.byKey(const Key('discernment_option_5'));

        await tester.scrollUntilVisible(
          lastOption,
          120.0,
          scrollable: scrollableFinder,
        );
        await tester.pumpAndSettle();
        expect(
          tester.state<ScrollableState>(scrollableFinder).position.pixels,
          greaterThan(0.0),
        );

        await tester.tap(lastOption);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('discernment_next_button')));
        await tester.pumpAndSettle();

        expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .pixels,
          equals(0.0),
        );

        await tester.tap(find.byKey(const Key('discernment_option_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('discernment_next_button')));
        await tester.pumpAndSettle();

        expect(capturedAnswers, equals({'q1': 5, 'q2': 0}));

        // Restarting should not mutate capturedAnswers
        await tester.tap(find.text('Restart'));
        await tester.pumpAndSettle();
        expect(capturedAnswers, equals({'q1': 5, 'q2': 0}));
      },
    );
  });
}
