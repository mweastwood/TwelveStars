import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
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
  });
}
