import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/confirmation_bracket_view.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_tournament_view.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import '../../test_helper.dart';

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
          summary: 'A short summary for saint ${i + 1}.',
          categories: [SaintCategory.doctor],
        ),
        matchScore: 0.95 - (i * 0.02),
        primaryHighlight: 'Highlight ${i + 1}',
      ),
    );
    tournament = ConfirmationDiscernmentEngine.createTournament(testSeeds);
  });

  group('ConfirmationTournamentView Widget Tests', () {
    testWidgets('renders match progress, entrant cards, and VS pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationTournamentView(
            tournament: tournament,
            onSelectWinner: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saint Showdown'), findsOneWidget);
      expect(find.textContaining('MATCH 1 OF 15'), findsOneWidget);
      expect(find.textContaining('ROUND OF 16'), findsOneWidget);
      expect(find.text('VS'), findsWidgets);
      expect(find.text('SEED #1'), findsOneWidget);
      expect(find.text('SEED #16'), findsOneWidget);
      expect(find.text('St. Saint 1'), findsOneWidget);
      expect(find.text('St. Saint 16'), findsOneWidget);
      expect(find.text('Patron of Students'), findsWidgets);
    });

    testWidgets(
      'calls onSelectWinner when entrant selection button is pressed',
      (tester) async {
        TournamentSeed? selectedWinner;

        await tester.pumpWidget(
          buildTestableWidget(
            child: ConfirmationTournamentView(
              tournament: tournament,
              onSelectWinner: (winner) {
                selectedWinner = winner;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final selectButton = find.byKey(const Key('entrant_1_select_button'));
        expect(selectButton, findsOneWidget);
        await tester.tap(selectButton);
        await tester.pumpAndSettle();

        expect(selectedWinner, isNotNull);
        expect(selectedWinner!.seed, equals(1));
      },
    );

    testWidgets('opens SaintDetailsSheet on Read Bio tap', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationTournamentView(
            tournament: tournament,
            onSelectWinner: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final readBioBtn = find.text('Read Bio').first;
      await tester.tap(readBioBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SaintDetailsSheet), findsOneWidget);
    });

    testWidgets('opens ConfirmationBracketView when bracket button pressed', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationTournamentView(
            tournament: tournament,
            onSelectWinner: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bracketButton = find.byKey(const Key('view_bracket_button'));
      expect(bracketButton, findsOneWidget);
      await tester.tap(bracketButton);
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationBracketView), findsOneWidget);
    });

    testWidgets('renders side-by-side on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
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

      expect(find.text('Saint Showdown'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.byKey(const Key('entrant_1_select_button')), findsOneWidget);
      expect(find.byKey(const Key('entrant_2_select_button')), findsOneWidget);
    });
  });
}
