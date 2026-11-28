import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/reader_annotation_chip.dart';
import '../test_helper.dart';

void main() {
  group('BibleVerseRow Widget Tests', () {
    testWidgets('renders verse number and verse text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: BibleVerseRow(
              verseNumber: 1,
              verseText: 'In the beginning God created heaven, and earth.',
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(
        find.text('In the beginning God created heaven, and earth.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.auto_stories_rounded), findsNothing);
      expect(find.byIcon(Icons.comment_rounded), findsNothing);
    });

    testWidgets(
      'renders favorite star badge when isFavorite is true and triggers onTapFavorite',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
                isFavorite: true,
                onTapFavorite: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.star_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.star_rounded));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'renders all badges (favorite, citations, comments) together in harmony',
      (tester) async {
        bool tappedFav = false;
        bool tappedCit = false;
        bool tappedCom = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
                isFavorite: true,
                citationsCount: 3,
                commentsCount: 2,
                onTapFavorite: () => tappedFav = true,
                onTapCitations: () => tappedCit = true,
                onTapComments: () => tappedCom = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.star_rounded), findsOneWidget);
        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.comment_rounded), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.star_rounded));
        await tester.pump();
        expect(tappedFav, isTrue);

        await tester.tap(find.byIcon(Icons.auto_stories_rounded));
        await tester.pump();
        expect(tappedCit, isTrue);

        await tester.tap(find.byIcon(Icons.comment_rounded));
        await tester.pump();
        expect(tappedCom, isTrue);
      },
    );

    testWidgets(
      'renders badges vertically in a Column on narrow screens (< 600 width)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
                isFavorite: true,
                citationsCount: 3,
                commentsCount: 2,
              ),
            ),
          ),
        );

        // Find the Column containing the badges
        final columnFinder = find.byType(Column);
        expect(columnFinder, findsOneWidget);

        final starFinder = find.byIcon(Icons.star_rounded);
        final citationsFinder = find.byIcon(Icons.auto_stories_rounded);
        final commentsFinder = find.byIcon(Icons.comment_rounded);

        // Check vertical order: star is above citations, citations is above comments
        final starTop = tester.getTopLeft(starFinder).dy;
        final citationsTop = tester.getTopLeft(citationsFinder).dy;
        final commentsTop = tester.getTopLeft(commentsFinder).dy;

        expect(starTop, lessThan(citationsTop));
        expect(citationsTop, lessThan(commentsTop));
      },
    );

    testWidgets(
      'renders badges horizontally in a Row on wide screens (>= 600 width)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
                isFavorite: true,
                citationsCount: 3,
                commentsCount: 2,
              ),
            ),
          ),
        );

        final starFinder = find.byIcon(Icons.star_rounded);
        final citationsFinder = find.byIcon(Icons.auto_stories_rounded);
        final commentsFinder = find.byIcon(Icons.comment_rounded);

        // Check horizontal order: star is to the left of citations, citations to the left of comments
        final starLeft = tester.getTopLeft(starFinder).dx;
        final citationsLeft = tester.getTopLeft(citationsFinder).dx;
        final commentsLeft = tester.getTopLeft(commentsFinder).dx;

        expect(starLeft, lessThan(citationsLeft));
        expect(citationsLeft, lessThan(commentsLeft));

        // And they are vertically aligned on approximately the same Y coordinate
        final starTop = tester.getTopLeft(starFinder).dy;
        final citationsTop = tester.getTopLeft(citationsFinder).dy;
        final commentsTop = tester.getTopLeft(commentsFinder).dy;

        expect(starTop, equals(citationsTop));
        expect(citationsTop, equals(commentsTop));
      },
    );

    testWidgets(
      'aligns verse number and verse text along alphabetic baseline',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
              ),
            ),
          ),
        );

        final numFinder = find.text('1');
        final textFinder = find.text(
          'In the beginning God created heaven, and earth.',
        );

        final numRender = tester.renderObject<RenderParagraph>(numFinder);
        final textRender = tester.renderObject<RenderParagraph>(textFinder);

        final numBaselineY =
            tester.getTopLeft(numFinder).dy +
            numRender.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        final textBaselineY =
            tester.getTopLeft(textFinder).dy +
            textRender.computeDistanceToActualBaseline(TextBaseline.alphabetic);

        expect(numBaselineY, closeTo(textBaselineY, 0.001));
      },
    );

    testWidgets(
      'aligns verse number and verse text along alphabetic baseline across different font sizes',
      (tester) async {
        for (final size in [12.0, 16.0, 20.0, 28.0]) {
          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: BibleVerseRow(
                  verseNumber: 12,
                  verseText:
                      'And God said: Let there be light. And light was made.',
                  fontSize: size,
                ),
              ),
            ),
          );

          final numFinder = find.text('12');
          final textFinder = find.text(
            'And God said: Let there be light. And light was made.',
          );

          final numRender = tester.renderObject<RenderParagraph>(numFinder);
          final textRender = tester.renderObject<RenderParagraph>(textFinder);

          final numBaselineY =
              tester.getTopLeft(numFinder).dy +
              numRender.computeDistanceToActualBaseline(
                TextBaseline.alphabetic,
              );
          final textBaselineY =
              tester.getTopLeft(textFinder).dy +
              textRender.computeDistanceToActualBaseline(
                TextBaseline.alphabetic,
              );

          expect(numBaselineY, closeTo(textBaselineY, 0.001));
        }
      },
    );

    testWidgets(
      'aligns verse number, primary verse text, and compare verse text along alphabetic baseline in compare translation mode',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
                compareVerseText:
                    'In the beginning God created the heavens and the earth.',
              ),
            ),
          ),
        );

        final numFinder = find.text('1');
        final primaryFinder = find.text(
          'In the beginning God created heaven, and earth.',
        );
        final compareFinder = find.text(
          'In the beginning God created the heavens and the earth.',
        );

        final numRender = tester.renderObject<RenderParagraph>(numFinder);
        final primaryRender = tester.renderObject<RenderParagraph>(
          primaryFinder,
        );
        final compareRender = tester.renderObject<RenderParagraph>(
          compareFinder,
        );

        final numBaselineY =
            tester.getTopLeft(numFinder).dy +
            numRender.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        final primaryBaselineY =
            tester.getTopLeft(primaryFinder).dy +
            primaryRender.computeDistanceToActualBaseline(
              TextBaseline.alphabetic,
            );
        final compareBaselineY =
            tester.getTopLeft(compareFinder).dy +
            compareRender.computeDistanceToActualBaseline(
              TextBaseline.alphabetic,
            );

        expect(numBaselineY, closeTo(primaryBaselineY, 0.001));
        expect(primaryBaselineY, closeTo(compareBaselineY, 0.001));
      },
    );

    testWidgets(
      'aligns verse number and verse text along alphabetic baseline with alternate verse numbers and chips',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                alternateVerseNumber: '2',
                verseText: 'Unto the end, a psalm for David.',
                isFavorite: true,
                citationsCount: 5,
                commentsCount: 3,
              ),
            ),
          ),
        );

        final numFinder = find.text('1 (2)');
        final textFinder = find.text('Unto the end, a psalm for David.');

        final numRender = tester.renderObject<RenderParagraph>(numFinder);
        final textRender = tester.renderObject<RenderParagraph>(textFinder);

        final numBaselineY =
            tester.getTopLeft(numFinder).dy +
            numRender.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        final textBaselineY =
            tester.getTopLeft(textFinder).dy +
            textRender.computeDistanceToActualBaseline(TextBaseline.alphabetic);

        expect(numBaselineY, closeTo(textBaselineY, 0.001));
      },
    );

    testWidgets(
      'applies default padding of EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0) when not provided',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
              ),
            ),
          ),
        );

        final animatedContainerFinder = find.descendant(
          of: find.byType(BibleVerseRow),
          matching: find.byType(AnimatedContainer),
        );
        expect(animatedContainerFinder, findsOneWidget);

        final animatedContainer = tester.widget<AnimatedContainer>(
          animatedContainerFinder,
        );
        expect(
          animatedContainer.padding,
          equals(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0)),
        );
      },
    );

    testWidgets('applies custom padding when provided', (tester) async {
      const customPadding = EdgeInsets.only(
        left: 0.0,
        right: 8.0,
        top: 6.0,
        bottom: 6.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: BibleVerseRow(
              verseNumber: 1,
              verseText: 'In the beginning God created heaven, and earth.',
              padding: customPadding,
            ),
          ),
        ),
      );

      final animatedContainerFinder = find.descendant(
        of: find.byType(BibleVerseRow),
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainerFinder, findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        animatedContainerFinder,
      );
      expect(animatedContainer.padding, equals(customPadding));
    });

    testWidgets('uses default margin when margin parameter is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: BibleVerseRow(
              verseNumber: 1,
              verseText: 'In the beginning God created heaven, and earth.',
            ),
          ),
        ),
      );

      final animatedContainerFinder = find.descendant(
        of: find.byType(BibleVerseRow),
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainerFinder, findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        animatedContainerFinder,
      );
      expect(
        animatedContainer.margin,
        equals(const EdgeInsets.symmetric(vertical: 2.0)),
      );
    });

    testWidgets('applies custom margin when provided', (tester) async {
      const customMargin = EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: BibleVerseRow(
              verseNumber: 1,
              verseText: 'In the beginning God created heaven, and earth.',
              margin: customMargin,
            ),
          ),
        ),
      );

      final animatedContainerFinder = find.descendant(
        of: find.byType(BibleVerseRow),
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainerFinder, findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        animatedContainerFinder,
      );
      expect(animatedContainer.margin, equals(customMargin));
    });

    testWidgets(
      'custom margin shifts highlight box without shifting verse text and number',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
              ),
            ),
          ),
        );

        final defaultTextRect = tester.getRect(
          find.text('In the beginning God created heaven, and earth.'),
        );
        final defaultNumRect = tester.getRect(find.text('1'));

        const customMargin = EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0);
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
                margin: customMargin,
              ),
            ),
          ),
        );

        final customTextRect = tester.getRect(
          find.text('In the beginning God created heaven, and earth.'),
        );
        final customNumRect = tester.getRect(find.text('1'));

        // Verse text and number must remain in the exact same horizontal position
        expect(customTextRect.left, equals(defaultTextRect.left));
        expect(customNumRect.left, equals(defaultNumRect.left));
      },
    );

    testWidgets(
      'custom margin of 16px shifts highlight box while anchoring verse text and number',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
              ),
            ),
          ),
        );

        final defaultTextRect = tester.getRect(
          find.text('In the beginning God created heaven, and earth.'),
        );
        final defaultNumRect = tester.getRect(find.text('1'));

        const customMargin = EdgeInsets.only(left: 16.0, top: 2.0, bottom: 2.0);
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText: 'In the beginning God created heaven, and earth.',
                margin: customMargin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final customTextRect = tester.getRect(
          find.text('In the beginning God created heaven, and earth.'),
        );
        final customNumRect = tester.getRect(find.text('1'));

        // Verse text remains at the exact same horizontal position
        expect(customTextRect.left, equals(defaultTextRect.left));
        // Verse number right edge remains anchored to the same position
        expect(customNumRect.right, equals(defaultNumRect.right));
      },
    );

    group('Parallel Translation Alignment with Annotation Chips', () {
      testWidgets(
        'keeps primary and secondary translation columns aligned across verses with and without notes on narrow screens',
        (tester) async {
          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildTestableWidget(
              child: const Scaffold(
                body: Column(
                  children: [
                    BibleVerseRow(
                      verseNumber: 1,
                      verseText:
                          'Then the people, seeing that Moses made a delay in descending from the mountain.',
                      compareVerseText:
                          'And the people seeing that Moses delayed to come down from the mount.',
                      commentsCount: 1,
                    ),
                    BibleVerseRow(
                      verseNumber: 2,
                      verseText:
                          'And Aaron said to them, Take the golden earrings from the ears of your wives.',
                      compareVerseText:
                          'And Aaron said to them: Take the golden earrings from the ears of your wives.',
                    ),
                    BibleVerseRow(
                      verseNumber: 3,
                      verseText:
                          'And the people did what he had commanded, bringing the earrings to Aaron.',
                      compareVerseText:
                          'And the people did what he had commanded, bringing the earrings to Aaron.',
                      isFavorite: true,
                      citationsCount: 2,
                      commentsCount: 3,
                    ),
                  ],
                ),
              ),
            ),
          );

          final v1Primary = tester.getRect(
            find.textContaining('Then the people, seeing'),
          );
          final v1Compare = tester.getRect(
            find.textContaining('And the people seeing'),
          );
          final v2Primary = tester.getRect(
            find.textContaining('And Aaron said to them, Take'),
          );
          final v2Compare = tester.getRect(
            find.textContaining('And Aaron said to them: Take'),
          );
          final v3Primary = tester.getRect(
            find
                .textContaining('And the people did what he had commanded')
                .first,
          );
          final v3Compare = tester.getRect(
            find
                .textContaining('And the people did what he had commanded')
                .last,
          );

          // Primary column left edge and width must match identically across all rows
          expect(v1Primary.left, closeTo(v2Primary.left, 0.01));
          expect(v1Primary.width, closeTo(v2Primary.width, 0.01));
          expect(v3Primary.left, closeTo(v2Primary.left, 0.01));
          expect(v3Primary.width, closeTo(v2Primary.width, 0.01));

          // Secondary column left edge and width must match identically across all rows
          expect(v1Compare.left, closeTo(v2Compare.left, 0.01));
          expect(v1Compare.width, closeTo(v2Compare.width, 0.01));
          expect(v3Compare.left, closeTo(v2Compare.left, 0.01));
          expect(v3Compare.width, closeTo(v2Compare.width, 0.01));

          // Verse 1 comment chip should sit below the parallel text, aligned with primary text start
          final v1Chip = tester.getRect(
            find.byType(ReaderAnnotationChip).first,
          );
          expect(v1Chip.top, greaterThanOrEqualTo(v1Primary.bottom));
          expect(v1Chip.top, greaterThanOrEqualTo(v1Compare.bottom));
          expect(v1Chip.left, closeTo(v1Primary.left, 0.01));
        },
      );

      testWidgets(
        'keeps primary and secondary translation columns aligned on wide screens and preserves chip taps',
        (tester) async {
          tester.view.physicalSize = const Size(900, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          bool tappedFav = false;
          bool tappedCit = false;
          bool tappedCom = false;

          await tester.pumpWidget(
            buildTestableWidget(
              child: Scaffold(
                body: Column(
                  children: [
                    BibleVerseRow(
                      verseNumber: 1,
                      verseText:
                          'In the beginning God created heaven, and earth.',
                      compareVerseText:
                          'In principio creavit Deus caelum et terram.',
                      isFavorite: true,
                      citationsCount: 4,
                      commentsCount: 2,
                      onTapFavorite: () => tappedFav = true,
                      onTapCitations: () => tappedCit = true,
                      onTapComments: () => tappedCom = true,
                    ),
                    const BibleVerseRow(
                      verseNumber: 2,
                      verseText: 'And the earth was void and empty.',
                      compareVerseText: 'Terra autem erat inanis et vacua.',
                    ),
                  ],
                ),
              ),
            ),
          );

          final v1Primary = tester.getRect(
            find.text('In the beginning God created heaven, and earth.'),
          );
          final v1Compare = tester.getRect(
            find.text('In principio creavit Deus caelum et terram.'),
          );
          final v2Primary = tester.getRect(
            find.text('And the earth was void and empty.'),
          );
          final v2Compare = tester.getRect(
            find.text('Terra autem erat inanis et vacua.'),
          );

          expect(v1Primary.left, closeTo(v2Primary.left, 0.01));
          expect(v1Primary.width, closeTo(v2Primary.width, 0.01));
          expect(v1Compare.left, closeTo(v2Compare.left, 0.01));
          expect(v1Compare.width, closeTo(v2Compare.width, 0.01));

          await tester.tap(find.byIcon(Icons.star_rounded));
          await tester.tap(find.byIcon(Icons.auto_stories_rounded));
          await tester.tap(find.byIcon(Icons.comment_rounded));
          await tester.pump();

          expect(tappedFav, isTrue);
          expect(tappedCit, isTrue);
          expect(tappedCom, isTrue);
        },
      );

      testGoldens('renders aligned parallel verses with and without notes/badges', (
        tester,
      ) async {
        await tester.pumpWidgetBuilder(
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BibleVerseRow(
                    verseNumber: 1,
                    verseText:
                        'Then the people, seeing that Moses made a delay in descending from the mountain, gathered together against Aaron.',
                    compareVerseText:
                        'And the people seeing that Moses delayed to come down from the mount, gathering together against Aaron.',
                    commentsCount: 1,
                  ),
                  BibleVerseRow(
                    verseNumber: 2,
                    verseText:
                        'And Aaron said to them, “Take the golden earrings from the ears of your wives, and your sons and daughters, and bring them to me.”',
                    compareVerseText:
                        'And Aaron said to them: Take the golden earrings from the ears of your wives, and your sons and daughters, and bring them to me.',
                  ),
                  BibleVerseRow(
                    verseNumber: 3,
                    verseText:
                        'And the people did what he had commanded, bringing the earrings to Aaron.',
                    compareVerseText:
                        'And the people did what he had commanded, bringing the earrings to Aaron.',
                    isFavorite: true,
                    citationsCount: 2,
                    commentsCount: 1,
                  ),
                ],
              ),
            ),
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E5A27),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(412, 640),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'bible_verse_row_parallel_alignment_golden',
        );
      });
    });
  });
}
