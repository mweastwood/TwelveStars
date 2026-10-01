import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/widgets/library/library_thematic_shelf.dart';

import '../../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildShelf({ValueChanged<String>? onOpenTheme}) {
    return buildTestableWidget(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LibraryThematicShelf(onOpenTheme: onOpenTheme ?? (_) {}),
          ),
        ),
      ),
    );
  }

  group('LibraryThematicShelf - Initial Rendering & Layout', () {
    testWidgets(
      'renders shelf header elements with icon, title, subtitle, and action button',
      (tester) async {
        await tester.pumpWidget(buildShelf());
        await tester.pumpAndSettle();

        // Header icon and title
        expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
        expect(find.text('EXPLORE BY THEME'), findsOneWidget);

        // Subtitle
        expect(
          find.text(
            'Swipe through curated quotations by sacrament, virtue, & doctrine',
          ),
          findsOneWidget,
        );

        // Action button with theme count
        final expectedButtonText =
            'All Themes (${ThematicHelper.allThemes.length})';
        expect(find.text(expectedButtonText), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
      },
    );

    testWidgets(
      'renders category pillar cards with icons, counts, and names for all groups',
      (tester) async {
        await tester.pumpWidget(buildShelf());
        await tester.pumpAndSettle();

        final categoryListView = find.byType(ListView).first;
        expect(categoryListView, findsOneWidget);

        // Verify the first visible category pillars
        expect(find.text('The Seven Sacraments'), findsOneWidget);
        expect(find.text('🕊️'), findsAtLeastNWidgets(1));
        expect(find.text('8'), findsAtLeastNWidgets(1));

        // Scroll through horizontal ListView to check all category groups
        for (final group in ThematicHelper.categoryGroups) {
          await tester.scrollUntilVisible(
            find.text(group.name),
            100,
            scrollable: find.descendant(
              of: categoryListView,
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(group.name), findsOneWidget);
          expect(find.text(group.icon), findsAtLeastNWidgets(1));
          expect(find.text('${group.themes.length}'), findsAtLeastNWidgets(1));
        }
      },
    );

    testWidgets('renders quick topic chips with label outline icons', (
      tester,
    ) async {
      await tester.pumpWidget(buildShelf());
      await tester.pumpAndSettle();

      // Quick topic ActionChips
      expect(find.widgetWithText(ActionChip, '🕊️ Eucharist'), findsOneWidget);
      expect(
        find.widgetWithText(ActionChip, '🕯️ Mental Prayer'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ActionChip, '⚔️ Spiritual Warfare'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ActionChip, '👑 Our Lady'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, '🌿 Humility'), findsOneWidget);

      // Verify label outline icons in ActionChips
      expect(find.byIcon(Icons.label_outline_rounded), findsWidgets);
    });
  });

  group('LibraryThematicShelf - Quick Topic Selection', () {
    testWidgets(
      'direct tap on visible quick topic chip invokes onOpenTheme callback',
      (tester) async {
        String? selectedTheme;
        await tester.pumpWidget(
          buildShelf(
            onOpenTheme: (themeId) {
              selectedTheme = themeId;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ActionChip, '🕊️ Eucharist'));
        await tester.pumpAndSettle();

        expect(selectedTheme, equals('sacraments.eucharist'));
      },
    );

    testWidgets(
      'horizontal scroll reveals off-screen chip and tap invokes onOpenTheme',
      (tester) async {
        String? selectedTheme;
        await tester.pumpWidget(
          buildShelf(
            onOpenTheme: (themeId) {
              selectedTheme = themeId;
            },
          ),
        );
        await tester.pumpAndSettle();

        final quickChipsScrollable = find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
          matching: find.byType(Scrollable),
        );

        await tester.scrollUntilVisible(
          find.widgetWithText(ActionChip, '👑 Heaven & Eternity'),
          100,
          scrollable: quickChipsScrollable,
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ActionChip, '👑 Heaven & Eternity'),
        );
        await tester.pumpAndSettle();

        expect(selectedTheme, equals('eschatology.heaven_beatific_vision'));
      },
    );

    testWidgets('onOpenTheme is invoked exactly once per chip tap', (
      tester,
    ) async {
      final List<String> selections = [];
      await tester.pumpWidget(
        buildShelf(
          onOpenTheme: (themeId) {
            selections.add(themeId);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, '🕯️ Mental Prayer'));
      await tester.pumpAndSettle();

      expect(selections, equals(['prayer.vocal_mental_meditation']));

      await tester.tap(find.widgetWithText(ActionChip, '🌿 Humility'));
      await tester.pumpAndSettle();

      expect(
        selections,
        equals(['prayer.vocal_mental_meditation', 'virtues.humility_meekness']),
      );
    });
  });

  group('LibraryThematicShelf - Category Pillar Navigation', () {
    testWidgets(
      'direct tap on visible category pillar card triggers onOpenTheme with primary theme',
      (tester) async {
        String? selectedTheme;
        await tester.pumpWidget(
          buildShelf(
            onOpenTheme: (themeId) {
              selectedTheme = themeId;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap first visible pillar card: 'The Seven Sacraments'
        await tester.tap(find.text('The Seven Sacraments'));
        await tester.pumpAndSettle();

        expect(selectedTheme, equals('sacraments.eucharist'));
      },
    );

    testWidgets(
      'scrolling category pillars carousel reveals off-screen group and tap triggers onOpenTheme',
      (tester) async {
        String? selectedTheme;
        await tester.pumpWidget(
          buildShelf(
            onOpenTheme: (themeId) {
              selectedTheme = themeId;
            },
          ),
        );
        await tester.pumpAndSettle();

        final categoryListView = find.byType(ListView).first;
        final categoryScrollable = find.descendant(
          of: categoryListView,
          matching: find.byType(Scrollable),
        );

        await tester.scrollUntilVisible(
          find.text('Prayer & Mystical Life'),
          100,
          scrollable: categoryScrollable,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Prayer & Mystical Life'));
        await tester.pumpAndSettle();

        expect(selectedTheme, equals('prayer.vocal_mental_meditation'));
      },
    );
  });

  group(
    'LibraryThematicShelf - Modal Theme Picker Bottom Sheet Navigation',
    () {
      testWidgets(
        'tapping All Themes button opens DraggableScrollableSheet modal with header',
        (tester) async {
          await tester.pumpWidget(buildShelf());
          await tester.pumpAndSettle();

          final allThemesButton = find.widgetWithText(
            TextButton,
            'All Themes (${ThematicHelper.allThemes.length})',
          );
          await tester.tap(allThemesButton);
          await tester.pumpAndSettle();

          // Verify modal bottom sheet is shown
          expect(find.byType(DraggableScrollableSheet), findsOneWidget);

          // Verify header elements
          expect(find.byIcon(Icons.category_rounded), findsOneWidget);
          expect(find.text('Explore by Spiritual Theme'), findsOneWidget);
          expect(
            find.text('${ThematicHelper.allThemes.length} Themes'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'category group 0 is expanded by default and displays theme items',
        (tester) async {
          await tester.pumpWidget(buildShelf());
          await tester.pumpAndSettle();

          await tester.tap(find.byType(TextButton));
          await tester.pumpAndSettle();

          // Group 0 'The Seven Sacraments' is expanded by default
          expect(
            find.text('The Most Holy Eucharist & The Mass'),
            findsOneWidget,
          );
          expect(find.text('Holy Baptism & Regeneration'), findsOneWidget);
        },
      );

      testWidgets(
        'selecting theme from default group invokes onOpenTheme and dismisses modal',
        (tester) async {
          String? selectedTheme;
          await tester.pumpWidget(
            buildShelf(
              onOpenTheme: (themeId) {
                selectedTheme = themeId;
              },
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byType(TextButton));
          await tester.pumpAndSettle();

          // Tap on 'The Most Holy Eucharist & The Mass'
          await tester.tap(find.text('The Most Holy Eucharist & The Mass'));
          await tester.pumpAndSettle();

          // Verify callback was invoked
          expect(selectedTheme, equals('sacraments.eucharist'));

          // Verify bottom sheet is dismissed
          expect(find.byType(DraggableScrollableSheet), findsNothing);
          expect(find.text('Explore by Spiritual Theme'), findsNothing);
        },
      );

      testWidgets(
        'expanding and selecting theme from another group invokes onOpenTheme and dismisses modal',
        (tester) async {
          String? selectedTheme;
          await tester.pumpWidget(
            buildShelf(
              onOpenTheme: (themeId) {
                selectedTheme = themeId;
              },
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byType(TextButton));
          await tester.pumpAndSettle();

          // Find the modal sheet's scrollable ListView
          final modalListView = find.descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(Scrollable),
          );

          // Scroll to 'Moral Virtues & Christian Living' group
          await tester.scrollUntilVisible(
            find.text('Moral Virtues & Christian Living'),
            100,
            scrollable: modalListView,
          );
          await tester.pumpAndSettle();

          // Tap to expand 'Moral Virtues & Christian Living'
          await tester.tap(find.text('Moral Virtues & Christian Living'));
          await tester.pumpAndSettle();

          // Scroll to 'Humility & Meekness' child theme
          await tester.scrollUntilVisible(
            find.text('Humility & Meekness'),
            100,
            scrollable: modalListView,
          );
          await tester.pumpAndSettle();

          // Tap 'Humility & Meekness'
          await tester.tap(find.text('Humility & Meekness'));
          await tester.pumpAndSettle();

          // Verify callback was invoked
          expect(selectedTheme, equals('virtues.humility_meekness'));

          // Verify bottom sheet is dismissed
          expect(find.byType(DraggableScrollableSheet), findsNothing);
          expect(find.text('Explore by Spiritual Theme'), findsNothing);
        },
      );

      testWidgets(
        'dismissal without selection via scrim tap closes sheet and does not invoke callback',
        (tester) async {
          String? selectedTheme;
          await tester.pumpWidget(
            buildShelf(
              onOpenTheme: (themeId) {
                selectedTheme = themeId;
              },
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byType(TextButton));
          await tester.pumpAndSettle();

          expect(find.byType(DraggableScrollableSheet), findsOneWidget);

          // Tap outside the sheet (scrim/barrier)
          await tester.tapAt(const Offset(20, 20));
          await tester.pumpAndSettle();

          expect(find.byType(DraggableScrollableSheet), findsNothing);
          expect(selectedTheme, isNull);
        },
      );
    },
  );
}
