import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/saint_card.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

import '../test_helper.dart';

void main() {
  const baseSaint = Saint(
    id: 'thomas-aquinas',
    name: 'St. Thomas Aquinas',
    birthDate: '1225',
    deathDate: '1274',
    nationality: 'Italian',
    profession: 'Dominican Friar & Theologian',
    categories: [SaintCategory.doctor, SaintCategory.priest],
    isDoctor: true,
    isBlessed: false,
    feastDay: 'January 28',
    patronage: 'Students, Academics, Theologians',
    summary: 'Angelic Doctor of the Church and patron of Catholic schools.',
    gender: 'male',
  );

  group('SaintCard Widget Tests', () {
    testWidgets('renders Card with proper key, title, and chevron icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: SaintCard(saint: baseSaint)),
        ),
      );

      expect(
        find.byKey(const Key('saint_tile_thomas-aquinas')),
        findsOneWidget,
      );
      expect(find.text('St. Thomas Aquinas'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('Dominican Friar & Theologian'), findsOneWidget);
    });

    group('Doctor of the Church Badge', () {
      testWidgets(
        'renders Doctor badge with amber star, label, tooltip, and styling when isDoctor is true',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: baseSaint)),
            ),
          );

          // Tooltip check
          final tooltipFinder = find.byType(Tooltip);
          expect(tooltipFinder, findsOneWidget);
          final tooltip = tester.widget<Tooltip>(tooltipFinder);
          expect(tooltip.message, 'Doctor of the Church');

          // Star icon & Doctor text
          expect(find.byIcon(Icons.star), findsOneWidget);
          final icon = tester.widget<Icon>(find.byIcon(Icons.star));
          expect(icon.color, Colors.amber);
          expect(icon.size, 12);

          final doctorTextFinder = find.descendant(
            of: tooltipFinder,
            matching: find.text('Doctor'),
          );
          expect(doctorTextFinder, findsOneWidget);
          final doctorText = tester.widget<Text>(doctorTextFinder);
          expect(doctorText.style?.color, Colors.amber.shade900);
          expect(doctorText.style?.fontWeight, FontWeight.bold);

          // Container decoration check
          final containerFinder = find.descendant(
            of: tooltipFinder,
            matching: find.byType(Container),
          );
          expect(containerFinder, findsOneWidget);
          final container = tester.widget<Container>(containerFinder);
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, Colors.amber.withValues(alpha: 0.2));
          expect(decoration.border?.top.color, Colors.amber.shade700);
        },
      );
    });

    group('Blessed Badge', () {
      testWidgets(
        'renders Blessed badge with secondaryContainer styling when isBlessed is true and isDoctor is false',
        (WidgetTester tester) async {
          const blessedSaint = Saint(
            id: 'carlo-acutis',
            name: 'Blessed Carlo Acutis',
            birthDate: '1991',
            deathDate: '2006',
            nationality: 'Italian',
            profession: 'Student & Web Developer',
            categories: [SaintCategory.laity],
            isDoctor: false,
            isBlessed: true,
            feastDay: 'October 12',
            patronage: 'Internet, Youth, Programmers',
            summary: 'Computer enthusiast who documented Eucharistic miracles.',
            gender: 'male',
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: blessedSaint)),
            ),
          );

          expect(find.text('Blessed'), findsOneWidget);
          expect(find.text('Doctor'), findsNothing);
          expect(find.byIcon(Icons.star), findsNothing);

          // Check styling
          final blessedTextWidget = tester.widget<Text>(find.text('Blessed'));
          final theme = Theme.of(tester.element(find.byType(SaintCard)));
          expect(
            blessedTextWidget.style?.color,
            theme.colorScheme.onSecondaryContainer,
          );

          // Check container decoration
          final blessedContainerFinder = find
              .ancestor(
                of: find.text('Blessed'),
                matching: find.byType(Container),
              )
              .first;
          final container = tester.widget<Container>(blessedContainerFinder);
          final decoration = container.decoration as BoxDecoration;
          expect(
            decoration.color,
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
          );
        },
      );

      testWidgets(
        'renders neither Doctor nor Blessed badge when both flags are false',
        (WidgetTester tester) async {
          const regularSaint = Saint(
            id: 'francis-assisi',
            name: 'St. Francis of Assisi',
            nationality: 'Italian',
            profession: 'Friar Minor & Founder',
            isDoctor: false,
            isBlessed: false,
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: regularSaint)),
            ),
          );

          expect(find.text('Doctor'), findsNothing);
          expect(find.text('Blessed'), findsNothing);
          expect(find.byIcon(Icons.star), findsNothing);
          expect(find.byType(Tooltip), findsNothing);
        },
      );

      testWidgets(
        'prefers Doctor badge if both isDoctor and isBlessed are set to true',
        (WidgetTester tester) async {
          const edgeCaseSaint = Saint(
            id: 'edge-doctor-blessed',
            name: 'Doctor Blessed Test',
            nationality: 'Roman',
            profession: 'Theologian',
            isDoctor: true,
            isBlessed: true,
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: edgeCaseSaint)),
            ),
          );

          expect(find.text('Doctor'), findsOneWidget);
          expect(find.text('Blessed'), findsNothing);
        },
      );
    });

    group('Feast Day and Nationality Pills', () {
      testWidgets('renders feast day and nationality pills when present', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: SaintCard(saint: baseSaint)),
          ),
        );

        expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
        expect(find.text('January 28'), findsOneWidget);

        // Verify feast day pill colors
        final theme = Theme.of(tester.element(find.byType(SaintCard)));
        final feastContainerFinder = find
            .ancestor(
              of: find.text('January 28'),
              matching: find.byType(Container),
            )
            .first;
        final feastContainer = tester.widget<Container>(feastContainerFinder);
        final feastDec = feastContainer.decoration as BoxDecoration;
        expect(
          feastDec.color,
          theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        );

        expect(find.byIcon(Icons.public_outlined), findsOneWidget);
        expect(find.text('Italian'), findsOneWidget);

        // Verify nationality pill colors
        final natContainerFinder = find
            .ancestor(
              of: find.text('Italian'),
              matching: find.byType(Container),
            )
            .first;
        final natContainer = tester.widget<Container>(natContainerFinder);
        final natDec = natContainer.decoration as BoxDecoration;
        expect(
          natDec.color,
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        );
      });

      testWidgets(
        'omits feast day pill when feastDay is null or empty string',
        (WidgetTester tester) async {
          const saintNoFeast = Saint(
            id: 'no-feast',
            name: 'St. Unknown',
            nationality: 'French',
            profession: 'Hermit',
            feastDay: null,
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: saintNoFeast)),
            ),
          );

          expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);

          const saintEmptyFeast = Saint(
            id: 'empty-feast',
            name: 'St. Unknown 2',
            nationality: 'French',
            profession: 'Hermit',
            feastDay: '',
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: saintEmptyFeast)),
            ),
          );

          expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);
        },
      );

      testWidgets('omits nationality pill when nationality is empty string', (
        WidgetTester tester,
      ) async {
        const saintNoNat = Saint(
          id: 'no-nat',
          name: 'St. Global',
          nationality: '',
          profession: 'Missionary',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: SaintCard(saint: saintNoNat)),
          ),
        );

        expect(find.byIcon(Icons.public_outlined), findsNothing);
      });
    });

    group('Category Pills and Leading Avatar', () {
      testWidgets('renders leading avatar with categoryIcon and theme tint', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: SaintCard(saint: baseSaint)),
          ),
        );

        final theme = Theme.of(tester.element(find.byType(SaintCard)));
        final expectedColor = baseSaint.categoryColor(theme);

        // Find avatar container (width 44, height 44)
        final avatarContainers = tester.widgetList<Container>(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.minWidth == 44 &&
                w.constraints?.minHeight == 44,
          ),
        );
        expect(avatarContainers, isNotEmpty);
        final avatar = avatarContainers.first;
        final decoration = avatar.decoration as BoxDecoration;
        expect(decoration.color, expectedColor.withValues(alpha: 0.15));
        expect(
          decoration.border?.top.color,
          expectedColor.withValues(alpha: 0.3),
        );

        // The leading avatar icon should match saint.categoryIcon
        final iconFinder = find.descendant(
          of: find.byWidget(avatar),
          matching: find.byIcon(baseSaint.categoryIcon),
        );
        expect(iconFinder, findsOneWidget);
        final iconWidget = tester.widget<Icon>(iconFinder);
        expect(iconWidget.color, expectedColor);
        expect(iconWidget.size, 22);
      });

      testWidgets(
        'renders category pills for all categories in canonical order',
        (WidgetTester tester) async {
          const multiCatSaint = Saint(
            id: 'multi-cat',
            name: 'St. Multi',
            nationality: 'Spanish',
            profession: 'Priest, Mystic & Martyr',
            categories: [
              SaintCategory.priest,
              SaintCategory.martyr,
              SaintCategory.mystic,
            ],
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: multiCatSaint)),
            ),
          );

          final theme = Theme.of(tester.element(find.byType(SaintCard)));

          for (final cat in multiCatSaint.categories) {
            expect(find.text(cat.label), findsOneWidget);
            final pillContainerFinder = find
                .ancestor(
                  of: find.text(cat.label),
                  matching: find.byType(Container),
                )
                .first;
            final container = tester.widget<Container>(pillContainerFinder);
            final decoration = container.decoration as BoxDecoration;
            expect(decoration.color, cat.color(theme).withValues(alpha: 0.12));

            final iconFinder = find.descendant(
              of: pillContainerFinder,
              matching: find.byIcon(cat.icon),
            );
            expect(iconFinder, findsOneWidget);
            final iconWidget = tester.widget<Icon>(iconFinder);
            expect(iconWidget.color, cat.color(theme));
            expect(iconWidget.size, 12);
          }
        },
      );
    });

    group('Date Range Formatting', () {
      testWidgets('formats both birthDate and deathDate as "birth – death"', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: SaintCard(saint: baseSaint)),
          ),
        );

        expect(find.text('1225 – 1274'), findsOneWidget);
      });

      testWidgets('formats birthDate only as "b. birth"', (
        WidgetTester tester,
      ) async {
        const birthOnlySaint = Saint(
          id: 'birth-only',
          name: 'Living Figure',
          birthDate: '1980',
          deathDate: null,
          nationality: 'American',
          profession: 'Contemporary Servant of God',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: SaintCard(saint: birthOnlySaint)),
          ),
        );

        expect(find.text('b. 1980'), findsOneWidget);
      });

      testWidgets('formats deathDate only as "d. death"', (
        WidgetTester tester,
      ) async {
        const deathOnlySaint = Saint(
          id: 'death-only',
          name: 'St. Early Martyr',
          birthDate: null,
          deathDate: 'c. 304',
          nationality: 'Roman',
          profession: 'Martyr',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: SaintCard(saint: deathOnlySaint)),
          ),
        );

        expect(find.text('d. c. 304'), findsOneWidget);
      });

      testWidgets(
        'omits date range text when both birthDate and deathDate are null',
        (WidgetTester tester) async {
          const noDatesSaint = Saint(
            id: 'no-dates',
            name: 'St. Archangel Michael',
            birthDate: null,
            deathDate: null,
            nationality: 'Angelic',
            profession: 'Archangel & Protector',
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: noDatesSaint)),
            ),
          );

          expect(find.textContaining(' – '), findsNothing);
          expect(find.textContaining('b. '), findsNothing);
          expect(find.textContaining('d. '), findsNothing);
        },
      );
    });

    group('Patronage and Summary Snippet', () {
      testWidgets('renders patronage row and summary snippet when present', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: SaintCard(saint: baseSaint)),
          ),
        );

        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        expect(find.text('Students, Academics, Theologians'), findsOneWidget);
        expect(
          find.text(
            'Angelic Doctor of the Church and patron of Catholic schools.',
          ),
          findsOneWidget,
        );

        // Check summary maxLines is 2 and ellipsis
        final summaryWidget = tester.widget<Text>(
          find.text(
            'Angelic Doctor of the Church and patron of Catholic schools.',
          ),
        );
        expect(summaryWidget.maxLines, 2);
        expect(summaryWidget.overflow, TextOverflow.ellipsis);
      });

      testWidgets(
        'omits patronage row when patronage is null or empty string',
        (WidgetTester tester) async {
          const nullPatronage = Saint(
            id: 'null-patronage',
            name: 'St. Test',
            nationality: 'Irish',
            profession: 'Monk',
            patronage: null,
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: nullPatronage)),
            ),
          );

          expect(find.byIcon(Icons.shield_outlined), findsNothing);

          const emptyPatronage = Saint(
            id: 'empty-patronage',
            name: 'St. Test 2',
            nationality: 'Irish',
            profession: 'Monk',
            patronage: '',
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: emptyPatronage)),
            ),
          );

          expect(find.byIcon(Icons.shield_outlined), findsNothing);
        },
      );

      testWidgets(
        'omits summary snippet when summary is null or empty string',
        (WidgetTester tester) async {
          const nullSummary = Saint(
            id: 'null-summary',
            name: 'St. Test',
            nationality: 'Irish',
            profession: 'Monk',
            summary: null,
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: nullSummary)),
            ),
          );

          expect(
            find.text(
              'Angelic Doctor of the Church and patron of Catholic schools.',
            ),
            findsNothing,
          );

          const emptySummary = Saint(
            id: 'empty-summary',
            name: 'St. Test 2',
            nationality: 'Irish',
            profession: 'Monk',
            summary: '',
          );

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: emptySummary)),
            ),
          );

          expect(
            find.text(
              'Angelic Doctor of the Church and patron of Catholic schools.',
            ),
            findsNothing,
          );
        },
      );
    });

    group('Tap Interaction', () {
      testWidgets('triggers onTap callback when provided and card is tapped', (
        WidgetTester tester,
      ) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SaintCard(
                saint: baseSaint,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('saint_tile_thomas-aquinas')));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
        expect(find.byType(SaintDetailsSheet), findsNothing);
      });

      testWidgets(
        'falls back to opening SaintDetailsSheet modal when onTap is null and card is tapped',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(body: SaintCard(saint: baseSaint)),
            ),
          );

          expect(find.byType(SaintDetailsSheet), findsNothing);

          await tester.tap(find.byKey(const Key('saint_tile_thomas-aquinas')));
          await tester.pumpAndSettle();

          expect(find.byType(SaintDetailsSheet), findsOneWidget);
        },
      );
    });
  });
}
