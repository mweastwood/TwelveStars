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
  });
}
