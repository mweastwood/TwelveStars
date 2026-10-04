import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/widgets/thematic_quote_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPassage = ThematicPassage(
    bookId: 'aquinas_catechetical_sacraments',
    bookTitle: 'The Catechetical Instructions: Part II',
    author: 'St. Thomas Aquinas',
    authorSaintId: 'thomas-aquinas',
    sectionId: 'sec_aquinas_catechetical_sacraments_1',
    sectionTitle: 'Chapter 1: The Sacraments of the Church',
    itemIndex: 0,
    primaryTheme: 'sacraments.eucharist',
    secondaryThemes: const ['theology.holy_spirit_grace'],
    keyExcerpt:
        'A sacrament is a visible sign of invisible grace, instituted by Jesus Christ.',
    oneSentenceSummary:
        'St. Thomas defines a sacrament as an efficacious outward sign.',
    fullText: 'Full text of the sacrament definition.',
  );

  group('ThematicQuoteCard Widget Tests', () {
    testWidgets('renders all passage metadata, quote, and summary correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThematicQuoteCard(
              passage: testPassage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenReaderContext: () {},
              onShowSaintDetails: (_) {},
            ),
          ),
        ),
      );

      // Book title should be uppercase
      expect(
        find.text('THE CATECHETICAL INSTRUCTIONS: PART II'),
        findsOneWidget,
      );
      // Section title
      expect(
        find.text('Chapter 1: The Sacraments of the Church'),
        findsOneWidget,
      );
      // Quote excerpt
      expect(
        find.text(
          'A sacrament is a visible sign of invisible grace, instituted by Jesus Christ.',
        ),
        findsOneWidget,
      );
      // Summary
      expect(
        find.text(
          'St. Thomas defines a sacrament as an efficacious outward sign.',
        ),
        findsOneWidget,
      );
      // Author
      expect(find.text('St. Thomas Aquinas'), findsOneWidget);
      // Read in Context button
      expect(find.text('Read in Context'), findsOneWidget);
      // Unfavorited icon
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets(
      'falls back to fullText when keyExcerpt is empty',
      (tester) async {
        final passageWithNoExcerpt = ThematicPassage(
          bookId: 'test_book',
          bookTitle: 'Test Book Title',
          author: 'Test Author',
          sectionId: 'sec_1',
          sectionTitle: 'Section 1',
          itemIndex: 0,
          primaryTheme: 'theology.trinity',
          keyExcerpt: '',
          oneSentenceSummary: 'Summary of the full text passage.',
          fullText: 'This is the complete full text being displayed.',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ThematicQuoteCard(
                passage: passageWithNoExcerpt,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenReaderContext: () {},
              ),
            ),
          ),
        );

        expect(
          find.text('This is the complete full text being displayed.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('toggles bookmark callback on heart icon tap', (tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThematicQuoteCard(
              passage: testPassage,
              isBookmarked: true,
              onToggleBookmark: () => toggleCalled = true,
              onOpenReaderContext: () {},
            ),
          ),
        ),
      );

      // Bookmarked state should show filled favorite icon
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pump();

      expect(toggleCalled, isTrue);
    });

    testWidgets('triggers onShowSaintDetails callback when saint is tapped', (
      tester,
    ) async {
      String? tappedSaintId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThematicQuoteCard(
              passage: testPassage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenReaderContext: () {},
              onShowSaintDetails: (saintId) => tappedSaintId = saintId,
            ),
          ),
        ),
      );

      await tester.tap(find.text('St. Thomas Aquinas'));
      await tester.pump();

      expect(tappedSaintId, 'thomas-aquinas');
    });

    testWidgets(
      'does not trigger onShowSaintDetails when author has no authorSaintId',
      (tester) async {
        final nonSaintPassage = ThematicPassage(
          bookId: 'didache_lightfoot',
          bookTitle: 'The Didache',
          author: 'Apostolic Fathers',
          authorSaintId: null,
          sectionId: 'ch7',
          sectionTitle: 'Chapter 7: Concerning Baptism',
          itemIndex: 0,
          primaryTheme: 'sacraments.baptism',
          keyExcerpt: 'Baptize into the name of the Father.',
          oneSentenceSummary: 'The Didache prescribes baptism.',
          fullText: 'Baptize into the name of the Father.',
        );

        String? tappedSaintId;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ThematicQuoteCard(
                passage: nonSaintPassage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenReaderContext: () {},
                onShowSaintDetails: (saintId) => tappedSaintId = saintId,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Apostolic Fathers'));
        await tester.pump();

        expect(tappedSaintId, isNull);
      },
    );

    testWidgets('triggers onOpenReaderContext callback when button is tapped', (
      tester,
    ) async {
      bool readerContextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThematicQuoteCard(
              passage: testPassage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenReaderContext: () => readerContextCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Read in Context'));
      await tester.pump();

      expect(readerContextCalled, isTrue);
    });
  });
}
