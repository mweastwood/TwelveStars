import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/screens/confirmation_discernment_screen.dart';
import 'package:twelve_stars/widgets/confirmation_bracket_view.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

Widget buildTestableWidget({required Widget child}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
      useMaterial3: true,
    ),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfirmationDiscernmentScreen Widget Tests', () {
    testWidgets('completes quiz flow, starts tournament, and crowns champion', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await SaintDatabase.loadSaints();
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const ConfirmationDiscernmentScreen()),
      );
      await tester.pumpAndSettle();

      // Verify Quiz stage loaded
      expect(find.text('Confirmation Discernment'), findsOneWidget);
      expect(find.textContaining('QUESTION 1 OF 14'), findsOneWidget);

      // Answer all 14 questions
      for (int q = 0; q < 14; q++) {
        // Select option 0
        final optionFinder = find.byKey(const Key('discernment_option_0'));
        expect(optionFinder, findsOneWidget);
        await tester.tap(optionFinder);
        await tester.pumpAndSettle();

        // Tap Next / Start Tournament
        final nextBtn = find.byKey(const Key('discernment_next_button'));
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // Verify Tournament Arena loaded
      expect(find.text('Saint Showdown'), findsOneWidget);
      expect(find.textContaining('MATCH 1 OF 15'), findsOneWidget);
      expect(find.text('VS'), findsWidgets);

      // Open Bracket View modal
      final bracketBtn = find.byKey(const Key('view_bracket_button'));
      expect(bracketBtn, findsOneWidget);
      await tester.tap(bracketBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationBracketView), findsOneWidget);
      expect(find.text('Tournament Bracket'), findsOneWidget);
      expect(find.text('Round of 16'), findsOneWidget);
      expect(find.text('Quarterfinals'), findsOneWidget);
      expect(find.text('Semifinals'), findsOneWidget);
      expect(find.text('Championship'), findsOneWidget);

      // Close Bracket modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationBracketView), findsNothing);

      // Play through all 15 matches
      for (int m = 0; m < 15; m++) {
        expect(
          find.byKey(const Key('entrant_1_select_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('entrant_2_select_button')),
          findsOneWidget,
        );

        // Tap entrant 1 to advance
        await tester.tap(find.byKey(const Key('entrant_1_select_button')));
        await tester.pumpAndSettle();
      }

      // Verify Champion stage reached
      expect(find.text('Confirmation Patron Chosen'), findsOneWidget);
      expect(find.text('YOUR CONFIRMATION PATRON SAINT'), findsOneWidget);
      expect(find.text('Confirmation Intercessory Prayer'), findsOneWidget);
      // Scroll and tap Copy Dossier
      final copyBtn = find.byKey(const Key('copy_dossier_button'));
      await tester.scrollUntilVisible(copyBtn, 300);
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Confirmation dossier copied to clipboard!'),
        findsOneWidget,
      );
    });

    testWidgets('does not display axis badge in quiz screen', (tester) async {
      await tester.runAsync(() async {
        await SaintDatabase.loadSaints();
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const ConfirmationDiscernmentScreen()),
      );
      await tester.pumpAndSettle();

      for (final axis in DiscernmentAxis.values) {
        expect(find.text(axis.name), findsNothing);
      }
    });

    testWidgets('navigates back and forth between questions in quiz', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await SaintDatabase.loadSaints();
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const ConfirmationDiscernmentScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('QUESTION 1 OF'), findsOneWidget);

      // Select option and advance
      await tester.tap(find.byKey(const Key('discernment_option_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discernment_next_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('QUESTION 2 OF'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.textContaining('QUESTION 1 OF'), findsOneWidget);
    });

    testWidgets('opens read bio details sheet during tournament match', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await SaintDatabase.loadSaints();
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const ConfirmationDiscernmentScreen()),
      );
      await tester.pumpAndSettle();

      // Quick answer 14 questions to enter tournament
      for (int q = 0; q < 14; q++) {
        await tester.tap(find.byKey(const Key('discernment_option_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('discernment_next_button')));
        await tester.pumpAndSettle();
      }

      // Tap Read Bio on first entrant card
      final readBioBtn = find.text('Read Bio').first;
      await tester.tap(readBioBtn);
      await tester.pumpAndSettle();

      // Verify SaintDetailsSheet opened
      expect(find.byType(SaintDetailsSheet), findsOneWidget);
    });

    testWidgets(
      'handles Old Testament saints in intercessory prayer and dossier without improper St. prefix',
      (tester) async {
        final mockOtSaint = const Saint(
          id: 'moses-the-prophet',
          name: 'Moses the Prophet',
          birthDate: 'c. 1527 BC',
          deathDate: 'c. 1407 BC',
          nationality: 'Israelite',
          profession: 'Prophet',
        );

        final List<Saint> testSaints = [
          mockOtSaint,
          for (int i = 2; i <= 16; i++)
            Saint(
              id: 'saint-$i',
              name: 'St. Saint $i',
              nationality: 'Roman',
              profession: 'Martyr',
            ),
        ];

        SaintDatabase.mockSaints = testSaints;
        addTearDown(() {
          SaintDatabase.mockSaints = null;
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const ConfirmationDiscernmentScreen()),
        );
        await tester.pumpAndSettle();

        // Complete 14 questions
        for (int q = 0; q < 14; q++) {
          await tester.tap(find.byKey(const Key('discernment_option_0')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('discernment_next_button')));
          await tester.pumpAndSettle();
        }

        // Play 15 matches, always choosing entrant 1
        for (int m = 0; m < 15; m++) {
          await tester.tap(find.byKey(const Key('entrant_1_select_button')));
          await tester.pumpAndSettle();
        }

        // Verify champion screen for Moses the Prophet
        expect(find.text('Confirmation Patron Chosen'), findsOneWidget);
        expect(find.text('Moses the Prophet'), findsWidgets);
        expect(find.textContaining('St. Moses the Prophet'), findsNothing);

        // Verify Intercessory Prayer start text
        expect(
          find.textContaining('Moses the Prophet, you lived a life'),
          findsOneWidget,
        );

        // Scroll and tap Copy Dossier
        final copyBtn = find.byKey(const Key('copy_dossier_button'));
        await tester.scrollUntilVisible(copyBtn, 300);
        await tester.tap(copyBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Confirmation dossier copied to clipboard!'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders custom initialQuestions when provided', (
      tester,
    ) async {
      final customQuestions = [
        const DiscernmentQuestion(
          id: 'custom_q1',
          title: 'Custom Title for Discernment Test',
          options: [
            DiscernmentOption(
              text: 'Custom Option A',
              weights: {DiscernmentAxis.contemplativeVsActive: 1.0},
            ),
            DiscernmentOption(
              text: 'Custom Option B',
              weights: {DiscernmentAxis.contemplativeVsActive: -1.0},
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationDiscernmentScreen(
            initialQuestions: customQuestions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Title for Discernment Test'), findsOneWidget);
      expect(find.text('Custom Option A'), findsOneWidget);
      expect(find.text('Custom Option B'), findsOneWidget);
    });
  });
}
