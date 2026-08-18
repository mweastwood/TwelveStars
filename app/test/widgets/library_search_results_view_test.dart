import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/reader/library_search_results_view.dart';

void main() {
  group('LibrarySearchResultsView Tests', () {
    testWidgets('renders empty query prompt when query is blank', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibrarySearchResultsView(
              searchQuery: '',
              searchResults: const [],
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.text('Type a search term to find in this book.'),
        findsOneWidget,
      );
    });

    testWidgets('renders no matches prompt when searchResults is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibrarySearchResultsView(
              searchQuery: 'NonexistentTerm',
              searchResults: const [],
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.text('No matches found for "NonexistentTerm".'),
        findsOneWidget,
      );
    });

    testWidgets('renders search results and triggers onResultTap', (
      WidgetTester tester,
    ) async {
      BookSearchResult? tappedResult;

      final results = [
        BookSearchResult(
          bookTitle: 'Baltimore Catechism',
          sectionId: 'sec_1',
          sectionTitle: 'Lesson 1: On Faith',
          matchedSnippet: 'Faith is a supernatural gift of God...',
        ),
        BookSearchResult(
          bookTitle: 'Baltimore Catechism',
          sectionId: 'sec_2',
          sectionTitle: 'Lesson 2: On Hope',
          matchedSnippet: 'Hope is the confident expectation...',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibrarySearchResultsView(
              searchQuery: 'faith',
              searchResults: results,
              onResultTap: (res) {
                tappedResult = res;
              },
            ),
          ),
        ),
      );

      expect(find.text('Lesson 1: On Faith'), findsOneWidget);
      expect(
        find.text('Faith is a supernatural gift of God...'),
        findsOneWidget,
      );
      expect(find.text('Lesson 2: On Hope'), findsOneWidget);

      await tester.tap(find.text('Lesson 1: On Faith'));
      await tester.pumpAndSettle();

      expect(tappedResult, isNotNull);
      expect(tappedResult?.sectionId, equals('sec_1'));
    });
  });
}
