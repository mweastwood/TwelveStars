import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/saint_database.dart';
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
      expect(find.textContaining('QUESTION 1 OF'), findsOneWidget);

      // Answer all 7 questions
      for (int q = 0; q < 7; q++) {
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

      // Quick answer 7 questions to enter tournament
      for (int q = 0; q < 7; q++) {
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
  });
}
