import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_book_filter_bar.dart';
import 'package:twelve_stars/widgets/reader/reader_annotation_chip.dart';
import 'package:twelve_stars/widgets/scripture_footer_quote.dart';
import 'package:twelve_stars/widgets/two_column_sliver_list.dart';

void main() {
  group('ReaderAnnotationChip Widget Tests', () {
    testWidgets(
      'renders favorite, comments, and citations variants and handles tap',
      (tester) async {
        int tappedFavorite = 0;
        int tappedComments = 0;
        int tappedCitations = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  ReaderAnnotationChip.favorite(
                    key: const Key('fav_chip'),
                    label: 'Favorite',
                    onTap: () => tappedFavorite++,
                  ),
                  ReaderAnnotationChip.comments(
                    key: const Key('comment_chip'),
                    count: 3,
                    onTap: () => tappedComments++,
                  ),
                  ReaderAnnotationChip.citations(
                    key: const Key('citation_chip'),
                    count: 7,
                    onTap: () => tappedCitations++,
                  ),
                  const ReaderAnnotationChip.favorite(
                    key: Key('static_fav_chip'),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Favorite'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
        expect(find.byIcon(Icons.comment_rounded), findsOneWidget);
        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);

        await tester.tap(find.byKey(const Key('fav_chip')));
        await tester.tap(find.byKey(const Key('comment_chip')));
        await tester.tap(find.byKey(const Key('citation_chip')));
        await tester.pump();

        expect(tappedFavorite, 1);
        expect(tappedComments, 1);
        expect(tappedCitations, 1);
      },
    );
  });

  group('ScriptureFooterQuote & TwoColumnSliverList Widget Tests', () {
    testWidgets(
      'renders ScriptureFooterQuote and distributes TwoColumnSliverList items',
      (tester) async {
        final items = ['Item 0', 'Item 1', 'Item 2', 'Item 3', 'Item 4'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  TwoColumnSliverList(
                    itemCount: items.length,
                    itemBuilder: (context, index) => Text(items[index]),
                  ),
                  const SliverToBoxAdapter(
                    child: ScriptureFooterQuote(
                      quote: '“Test quote.”',
                      attribution: '— John 1:1',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        for (final item in items) {
          expect(find.text(item), findsOneWidget);
        }
        expect(find.text('“Test quote.”'), findsOneWidget);
        expect(find.text('— John 1:1'), findsOneWidget);
      },
    );
  });

  group('LibraryBookFilterBar & Resolution Helper Tests', () {
    testWidgets(
      'resolves canonical book IDs and filters by selected book chip',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        // 'baltimore_1' is a volume key of 'baltimore_catechism'
        expect(
          canonicalLibraryBookId('baltimore_1', catalog),
          'baltimore_catechism',
        );
        expect(
          canonicalLibraryBookId('baltimore_catechism', catalog),
          'baltimore_catechism',
        );

        final resolved = resolveLibraryAnnotation(
          documentId: 'baltimore_2',
          nodeId: 'baltimore_2:lesson_1_q5',
          catalog: catalog,
        );
        expect(resolved.book?.id, 'baltimore_catechism');
        expect(resolved.volumeKey, 'no2');
        expect(resolved.sectionId, 'lesson_1');
        expect(resolved.questionNumber, 5);

        String selected = 'all';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return LibraryBookFilterBar(
                    catalog: catalog,
                    distinctBookIds: const ['baltimore_catechism', 'trent'],
                    totalCount: 5,
                    selectedBookId: selected,
                    countForBook: (id) => id == 'baltimore_catechism' ? 3 : 2,
                    onBookSelected: (id) => setState(() => selected = id),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('All (5)'), findsOneWidget);
        expect(find.textContaining('(3)'), findsOneWidget);
        expect(find.textContaining('(2)'), findsOneWidget);

        await tester.tap(find.textContaining('(3)'));
        await tester.pump();
        expect(selected, 'baltimore_catechism');

        // Tapping selected chip again resets to 'all'
        await tester.tap(find.textContaining('(3)'));
        await tester.pump();
        expect(selected, 'all');
      },
    );
  });
}
