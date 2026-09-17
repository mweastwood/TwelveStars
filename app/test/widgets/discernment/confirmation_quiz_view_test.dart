import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_quiz_view.dart';
import '../../test_helper.dart';

void main() {
  final testQuestions = [
    const DiscernmentQuestion(
      id: 'q1',
      title: 'Question 1 Title',
      options: [
        DiscernmentOption(
          text: 'Option 1A',
          subtitle: 'Subtitle 1A',
          weights: {DiscernmentAxis.contemplativeVsActive: 1.0},
        ),
        DiscernmentOption(
          text: 'Option 1B',
          subtitle: 'Subtitle 1B',
          weights: {DiscernmentAxis.contemplativeVsActive: -1.0},
        ),
      ],
    ),
    const DiscernmentQuestion(
      id: 'q2',
      title: 'Question 2 Title',
      options: [
        DiscernmentOption(
          text: 'Option 2A',
          weights: {DiscernmentAxis.intellectualVsDevotional: 1.0},
        ),
        DiscernmentOption(
          text: 'Option 2B',
          weights: {DiscernmentAxis.intellectualVsDevotional: -1.0},
        ),
      ],
    ),
  ];

  group('ConfirmationQuizView Widget Tests', () {
    testWidgets('renders question title, options, and progress bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationQuizView(
            questions: testQuestions,
            onRestart: () {},
            onComplete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmation Discernment'), findsOneWidget);
      expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
      expect(find.text('Question 1 Title'), findsOneWidget);
      expect(find.text('Option 1A'), findsOneWidget);
      expect(find.text('Subtitle 1A'), findsOneWidget);
      expect(find.text('Option 1B'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('next button is disabled until option selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationQuizView(
            questions: testQuestions,
            onRestart: () {},
            onComplete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextFinder = find.byKey(const Key('discernment_next_button'));
      expect(tester.widget<FilledButton>(nextFinder).enabled, isFalse);

      // Select option 0
      await tester.tap(find.byKey(const Key('discernment_option_0')));
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(nextFinder).enabled, isTrue);
    });

    testWidgets('navigates through questions and invokes onComplete', (
      tester,
    ) async {
      Map<String, int>? completedAnswers;

      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationQuizView(
            questions: testQuestions,
            onRestart: () {},
            onComplete: (answers) {
              completedAnswers = answers;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Q1: Select option 1
      await tester.tap(find.byKey(const Key('discernment_option_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discernment_next_button')));
      await tester.pumpAndSettle();

      // Q2: Verify back button and title
      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
      expect(find.text('Question 2 Title'), findsOneWidget);
      expect(find.text('Start Tournament'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('QUESTION 1 OF 2'), findsOneWidget);

      // Tap Next again
      await tester.tap(find.byKey(const Key('discernment_next_button')));
      await tester.pumpAndSettle();

      // Q2: Select option 0
      await tester.tap(find.byKey(const Key('discernment_option_0')));
      await tester.pumpAndSettle();

      // Tap Start Tournament
      await tester.tap(find.byKey(const Key('discernment_next_button')));
      await tester.pumpAndSettle();

      expect(completedAnswers, isNotNull);
      expect(completedAnswers!['q1'], equals(1));
      expect(completedAnswers!['q2'], equals(0));
    });

    testWidgets('invokes onRestart and resets state when restart tapped', (
      tester,
    ) async {
      bool restarted = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: ConfirmationQuizView(
            questions: testQuestions,
            onRestart: () {
              restarted = true;
            },
            onComplete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select option
      await tester.tap(find.byKey(const Key('discernment_option_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discernment_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);

      // Tap Restart
      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();

      expect(restarted, isTrue);
      expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
    });
  });
}
