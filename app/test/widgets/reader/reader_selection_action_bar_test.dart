import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

import '../../test_helper.dart';

void main() {
  group('ReaderSelectionActionBar Widget Tests', () {
    group('Title & Item Selection Subtitle Pluralization', () {
      testWidgets(
        'renders title in titleMedium with primary color and singular subtitle for default item label with count 1',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Matthew 5:3-12',
                  selectedCount: 1,
                  onSaveFavorite: () {},
                  onCopy: () {},
                ),
              ),
            ),
          );

          expect(find.text('Matthew 5:3-12'), findsOneWidget);
          final titleTextWidget = tester.widget<Text>(
            find.text('Matthew 5:3-12'),
          );
          final theme = Theme.of(
            tester.element(find.byType(ReaderSelectionActionBar)),
          );

          expect(
            titleTextWidget.style?.color,
            equals(theme.colorScheme.primary),
          );
          expect(titleTextWidget.style?.fontWeight, equals(FontWeight.bold));

          expect(find.text('1 item selected'), findsOneWidget);
        },
      );

      testWidgets(
        'renders plural subtitle for default item label with count 0',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Matthew 5:3-12',
                  selectedCount: 0,
                  onSaveFavorite: () {},
                  onCopy: () {},
                ),
              ),
            ),
          );

          expect(find.text('0 items selected'), findsOneWidget);
        },
      );

      testWidgets(
        'renders plural subtitle for default item label with count 3',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'John 1:1-5',
                  selectedCount: 3,
                  onSaveFavorite: () {},
                  onCopy: () {},
                ),
              ),
            ),
          );

          expect(find.text('3 items selected'), findsOneWidget);
        },
      );

      testWidgets(
        'renders singular subtitle for custom item label with count 1',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Luke 2:1',
                  selectedCount: 1,
                  itemLabel: 'verse',
                  onSaveFavorite: () {},
                  onCopy: () {},
                ),
              ),
            ),
          );

          expect(find.text('1 verse selected'), findsOneWidget);
        },
      );

      testWidgets(
        'renders plural subtitle for custom item label with count 0',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Luke 2:1',
                  selectedCount: 0,
                  itemLabel: 'verse',
                  onSaveFavorite: () {},
                  onCopy: () {},
                ),
              ),
            ),
          );

          expect(find.text('0 verses selected'), findsOneWidget);
        },
      );

      testWidgets(
        'renders plural subtitle for custom item label with count 4',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Luke 2:1-4',
                  selectedCount: 4,
                  itemLabel: 'verse',
                  onSaveFavorite: () {},
                  onCopy: () {},
                ),
              ),
            ),
          );

          expect(find.text('4 verses selected'), findsOneWidget);
        },
      );
    });

    group('Action Button Interaction & Callbacks', () {
      testWidgets(
        'triggers onSaveFavorite callback when Save star icon is tapped',
        (WidgetTester tester) async {
          bool saveFavoriteCalled = false;

          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Selection Title',
                  selectedCount: 2,
                  onSaveFavorite: () {
                    saveFavoriteCalled = true;
                  },
                  onCopy: () {},
                ),
              ),
            ),
          );

          final saveButtonFinder = find.widgetWithIcon(IconButton, Icons.star);
          expect(saveButtonFinder, findsOneWidget);
          final saveIconButton = tester.widget<IconButton>(saveButtonFinder);
          expect(saveIconButton.tooltip, equals('Save'));

          await tester.tap(saveButtonFinder);
          await tester.pumpAndSettle();

          expect(saveFavoriteCalled, isTrue);
        },
      );

      testWidgets(
        'triggers onCopy callback when Copy selection icon is tapped',
        (WidgetTester tester) async {
          bool copyCalled = false;

          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Selection Title',
                  selectedCount: 2,
                  onSaveFavorite: () {},
                  onCopy: () {
                    copyCalled = true;
                  },
                ),
              ),
            ),
          );

          final copyButtonFinder = find.widgetWithIcon(IconButton, Icons.copy);
          expect(copyButtonFinder, findsOneWidget);
          final copyIconButton = tester.widget<IconButton>(copyButtonFinder);
          expect(copyIconButton.tooltip, equals('Copy selection'));

          await tester.tap(copyButtonFinder);
          await tester.pumpAndSettle();

          expect(copyCalled, isTrue);
        },
      );

      testWidgets(
        'triggers onAddComment callback when Add Comment icon is tapped',
        (WidgetTester tester) async {
          bool addCommentCalled = false;

          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Selection Title',
                  selectedCount: 2,
                  onSaveFavorite: () {},
                  onCopy: () {},
                  onAddComment: () {
                    addCommentCalled = true;
                  },
                ),
              ),
            ),
          );

          final addCommentFinder = find.widgetWithIcon(
            IconButton,
            Icons.comment_outlined,
          );
          expect(addCommentFinder, findsOneWidget);
          final addCommentIconButton = tester.widget<IconButton>(
            addCommentFinder,
          );
          expect(addCommentIconButton.tooltip, equals('Add Comment'));

          await tester.tap(addCommentFinder);
          await tester.pumpAndSettle();

          expect(addCommentCalled, isTrue);
        },
      );

      testWidgets(
        'triggers onClearSelection callback when Clear Selection icon is tapped',
        (WidgetTester tester) async {
          bool clearSelectionCalled = false;

          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Selection Title',
                  selectedCount: 2,
                  onSaveFavorite: () {},
                  onCopy: () {},
                  onClearSelection: () {
                    clearSelectionCalled = true;
                  },
                ),
              ),
            ),
          );

          final clearFinder = find.widgetWithIcon(IconButton, Icons.close);
          expect(clearFinder, findsOneWidget);
          final clearIconButton = tester.widget<IconButton>(clearFinder);
          expect(clearIconButton.tooltip, equals('Clear Selection'));

          await tester.tap(clearFinder);
          await tester.pumpAndSettle();

          expect(clearSelectionCalled, isTrue);
        },
      );
    });

    group('Conditional Action Button Omission', () {
      testWidgets('omits Add Comment button when onAddComment is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: ReaderSelectionActionBar(
                title: 'Selection Title',
                selectedCount: 1,
                onSaveFavorite: () {},
                onCopy: () {},
                onAddComment: null,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.comment_outlined), findsNothing);
        expect(find.byTooltip('Add Comment'), findsNothing);
      });

      testWidgets(
        'omits Clear Selection button when onClearSelection is null',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Selection Title',
                  selectedCount: 1,
                  onSaveFavorite: () {},
                  onCopy: () {},
                  onClearSelection: null,
                ),
              ),
            ),
          );

          expect(find.byIcon(Icons.close), findsNothing);
          expect(find.byTooltip('Clear Selection'), findsNothing);
        },
      );
    });

    group('Long Title & Constrained Layout', () {
      testWidgets(
        'handles long title string with text truncation under constrained layout width without overflow',
        (WidgetTester tester) async {
          const longTitle =
              'Matthew 5:1-48 - The Sermon on the Mount with Very Long Passage Description That Exceeds Line Width';

          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: ReaderSelectionActionBar(
                  title: longTitle,
                  selectedCount: 5,
                  itemLabel: 'verse',
                  onSaveFavorite: () {},
                  onCopy: () {},
                  onAddComment: () {},
                  onClearSelection: () {},
                ),
              ),
            ),
          );

          final titleFinder = find.text(longTitle);
          expect(titleFinder, findsOneWidget);

          final titleWidget = tester.widget<Text>(titleFinder);
          expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
          expect(titleWidget.maxLines, equals(1));

          expect(tester.takeException(), isNull);
        },
      );
    });

    group('Theme & Accessibility Styling', () {
      testWidgets(
        'renders Card with surfaceContainerHighest in Light Theme without layout overflow',
        (WidgetTester tester) async {
          final lightTheme = ThemeData.light(useMaterial3: true);

          await tester.pumpWidget(
            MaterialApp(
              theme: lightTheme,
              home: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Genesis 1:1-3',
                  selectedCount: 3,
                  itemLabel: 'verse',
                  onSaveFavorite: () {},
                  onCopy: () {},
                  onAddComment: () {},
                  onClearSelection: () {},
                ),
              ),
            ),
          );

          final cardFinder = find.byType(Card);
          expect(cardFinder, findsOneWidget);
          final card = tester.widget<Card>(cardFinder);
          expect(
            card.color,
            equals(lightTheme.colorScheme.surfaceContainerHighest),
          );

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'renders Card with surfaceContainerHighest in Dark Theme without layout overflow',
        (WidgetTester tester) async {
          final darkTheme = ThemeData.dark(useMaterial3: true);

          await tester.pumpWidget(
            MaterialApp(
              theme: darkTheme,
              home: Scaffold(
                body: ReaderSelectionActionBar(
                  title: 'Genesis 1:1-3',
                  selectedCount: 3,
                  itemLabel: 'verse',
                  onSaveFavorite: () {},
                  onCopy: () {},
                  onAddComment: () {},
                  onClearSelection: () {},
                ),
              ),
            ),
          );

          final cardFinder = find.byType(Card);
          expect(cardFinder, findsOneWidget);
          final card = tester.widget<Card>(cardFinder);
          expect(
            card.color,
            equals(darkTheme.colorScheme.surfaceContainerHighest),
          );

          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}
