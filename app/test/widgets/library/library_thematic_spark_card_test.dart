import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/widgets/library/library_thematic_spark_card.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

import '../../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSaint = Saint(
    id: 'augustine',
    name: 'St. Augustine of Hippo',
    birthDate: '354',
    deathDate: '430',
    nationality: 'Roman / North African',
    profession: 'Bishop & Doctor of the Church',
    categories: [SaintCategory.doctor, SaintCategory.bishop],
    isDoctor: true,
    isBlessed: false,
    feastDay: 'August 28',
    patronage: 'Theologians, Printers',
    summary: 'Bishop of Hippo, philosopher, and Doctor of the Church.',
    gender: 'male',
  );

  ThematicPassage createPassage({
    String bookId = 'confessions',
    String bookTitle = 'Confessions of St. Augustine',
    String author = 'St. Augustine',
    String sectionId = 'book_1',
    String sectionTitle = 'Book I',
    int itemIndex = 1,
    int? questionNumber,
    String primaryTheme = 'theology.trinity',
    List<String> secondaryThemes = const [],
    String keyExcerpt =
        'You have made us for Yourself, O Lord, and our hearts are restless until they rest in You.',
    String oneSentenceSummary = 'True peace is found only in God.',
    String fullText =
        'Great art Thou, O Lord, and greatly to be praised; great is Thy power, and Thy wisdom is infinite.',
    String? authorSaintId = 'augustine',
  }) {
    return ThematicPassage(
      bookId: bookId,
      bookTitle: bookTitle,
      author: author,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      itemIndex: itemIndex,
      questionNumber: questionNumber,
      primaryTheme: primaryTheme,
      secondaryThemes: secondaryThemes,
      keyExcerpt: keyExcerpt,
      oneSentenceSummary: oneSentenceSummary,
      fullText: fullText,
      authorSaintId: authorSaintId,
    );
  }

  tearDown(() {
    SaintDatabase.resetCache();
    SaintDatabase.mockSaints = null;
  });

  group('Group 1: Layout & Presentation', () {
    testWidgets(
      'displays spark header, spark icon, and formatted theme title',
      (WidgetTester tester) async {
        final passage = createPassage(primaryTheme: 'theology.trinity');
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenTheme: (_) {},
                onOpenReader: () {},
              ),
            ),
          ),
        );

        // Verify spark icon and header text
        expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
        expect(find.text("TODAY'S SPARK"), findsOneWidget);

        // Verify primary theme chip label
        final expectedThemeTitle = ThematicHelper.getThemeTitle(
          'theology.trinity',
        );
        expect(find.text(expectedThemeTitle), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      },
    );

    testWidgets('displays keyExcerpt when non-empty', (
      WidgetTester tester,
    ) async {
      final passage = createPassage(
        keyExcerpt: 'Key excerpt passage text.',
        fullText: 'Full text backup passage.',
      );
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenTheme: (_) {},
              onOpenReader: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
      expect(find.text('Key excerpt passage text.'), findsOneWidget);
      expect(find.text('Full text backup passage.'), findsNothing);
    });

    testWidgets('falls back to fullText when keyExcerpt is empty', (
      WidgetTester tester,
    ) async {
      final passage = createPassage(
        keyExcerpt: '',
        fullText: 'Full text fallback quote.',
      );
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenTheme: (_) {},
              onOpenReader: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
      expect(find.text('Full text fallback quote.'), findsOneWidget);
    });

    testWidgets('displays summary box when oneSentenceSummary is present', (
      WidgetTester tester,
    ) async {
      final passage = createPassage(
        oneSentenceSummary: 'Insight into divine love.',
      );
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenTheme: (_) {},
              onOpenReader: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(find.text('Insight into divine love.'), findsOneWidget);
    });

    testWidgets('omits summary box when oneSentenceSummary is empty', (
      WidgetTester tester,
    ) async {
      final passage = createPassage(oneSentenceSummary: '');
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenTheme: (_) {},
              onOpenReader: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsNothing);
    });

    testWidgets('displays author citation and source book title', (
      WidgetTester tester,
    ) async {
      final passage = createPassage(
        author: 'St. Augustine',
        bookTitle: 'Confessions of St. Augustine',
      );
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenTheme: (_) {},
              onOpenReader: () {},
            ),
          ),
        ),
      );

      expect(find.text('— St. Augustine'), findsOneWidget);
      expect(find.text('Confessions of St. Augustine'), findsOneWidget);
    });

    testWidgets('verifies Card elevation, background color, and border shape', (
      WidgetTester tester,
    ) async {
      final passage = createPassage();
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenTheme: (_) {},
              onOpenReader: () {},
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final context = tester.element(find.byType(LibraryThematicSparkCard));
      final theme = Theme.of(context);

      expect(card.elevation, 2);
      expect(card.color, theme.colorScheme.surfaceContainerLow);

      expect(card.shape, isA<RoundedRectangleBorder>());
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
      expect(shape.side.width, 1.5);
      expect(
        shape.side.color,
        theme.colorScheme.primary.withValues(alpha: 0.35),
      );
    });
  });

  group('Group 2: Bookmark Interactions & States', () {
    testWidgets(
      'renders outline bookmark icon with Bookmark reflection tooltip when isBookmarked is false',
      (WidgetTester tester) async {
        final passage = createPassage();
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenTheme: (_) {},
                onOpenReader: () {},
              ),
            ),
          ),
        );

        final iconButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.favorite_border_rounded),
        );
        expect(iconButton.tooltip, 'Bookmark reflection');

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.favorite_border_rounded),
        );
        final context = tester.element(find.byType(LibraryThematicSparkCard));
        final theme = Theme.of(context);
        expect(icon.color, theme.colorScheme.onSurfaceVariant);
        expect(icon.size, 20);
      },
    );

    testWidgets(
      'renders filled bookmark icon with red tint and Remove bookmark tooltip when isBookmarked is true',
      (WidgetTester tester) async {
        final passage = createPassage();
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: true,
                onToggleBookmark: () {},
                onOpenTheme: (_) {},
                onOpenReader: () {},
              ),
            ),
          ),
        );

        final iconButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.favorite_rounded),
        );
        expect(iconButton.tooltip, 'Remove bookmark');

        final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
        expect(icon.color, Colors.redAccent);
        expect(icon.size, 20);
      },
    );

    testWidgets('tapping bookmark button triggers onToggleBookmark', (
      WidgetTester tester,
    ) async {
      bool bookmarkToggled = false;
      final passage = createPassage();
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {
                bookmarkToggled = true;
              },
              onOpenTheme: (_) {},
              onOpenReader: () {},
            ),
          ),
        ),
      );

      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.favorite_border_rounded),
      );
      await tester.pump();

      expect(bookmarkToggled, isTrue);
    });
  });

  group('Group 3: Navigation Callbacks', () {
    testWidgets(
      'tapping header theme chip invokes onOpenTheme with primary theme',
      (WidgetTester tester) async {
        String? openedTheme;
        final passage = createPassage(primaryTheme: 'sacraments.eucharist');
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenTheme: (themeId) {
                  openedTheme = themeId;
                },
                onOpenReader: () {},
              ),
            ),
          ),
        );

        final themeTitle = ThematicHelper.getThemeTitle('sacraments.eucharist');
        await tester.tap(find.text(themeTitle));
        await tester.pump();

        expect(openedTheme, 'sacraments.eucharist');
      },
    );

    testWidgets(
      'tapping more from this theme icon button invokes onOpenTheme with primary theme',
      (WidgetTester tester) async {
        String? openedTheme;
        final passage = createPassage(
          primaryTheme: 'prayer.contemplation_union',
        );
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenTheme: (themeId) {
                  openedTheme = themeId;
                },
                onOpenReader: () {},
              ),
            ),
          ),
        );

        await tester.tap(
          find.widgetWithIcon(IconButton, Icons.more_horiz_rounded),
        );
        await tester.pump();

        expect(openedTheme, 'prayer.contemplation_union');
      },
    );

    testWidgets('tapping read in context button invokes onOpenReader', (
      WidgetTester tester,
    ) async {
      bool readerOpened = false;
      final passage = createPassage();
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryThematicSparkCard(
              passage: passage,
              isBookmarked: false,
              onToggleBookmark: () {},
              onOpenTheme: (_) {},
              onOpenReader: () {
                readerOpened = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.auto_stories_rounded),
      );
      await tester.pump();

      expect(readerOpened, isTrue);
    });
  });

  group('Group 4: Saint Details Bottom Sheet Integration', () {
    testWidgets(
      'tapping author attribution for known saint launches SaintDetailsSheet',
      (WidgetTester tester) async {
        SaintDatabase.mockSaints = [testSaint];

        final passage = createPassage(
          author: 'St. Augustine',
          authorSaintId: 'augustine',
        );
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenTheme: (_) {},
                onOpenReader: () {},
              ),
            ),
          ),
        );

        // Tap the author attribution link
        await tester.tap(find.text('— St. Augustine'));
        await tester.pumpAndSettle();

        // Verify SaintDetailsSheet appears with the saint's information
        expect(find.byType(SaintDetailsSheet), findsOneWidget);
        expect(find.text('St. Augustine of Hippo'), findsOneWidget);
        expect(find.text('Doctor of the Church'), findsWidgets);
      },
    );

    testWidgets(
      'tapping author attribution when authorSaintId is null does not launch sheet',
      (WidgetTester tester) async {
        final passage = createPassage(
          author: 'Anonymous Author',
          authorSaintId: null,
        );
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenTheme: (_) {},
                onOpenReader: () {},
              ),
            ),
          ),
        );

        // Verify author text is rendered without an InkWell ancestor
        // and uses onSurfaceVariant styling
        final authorFinder = find.text('— Anonymous Author');
        expect(
          find.ancestor(of: authorFinder, matching: find.byType(InkWell)),
          findsNothing,
        );
        final authorTextWidget = tester.widget<Text>(authorFinder);
        final theme = Theme.of(tester.element(authorFinder));
        expect(
          authorTextWidget.style?.color,
          equals(theme.colorScheme.onSurfaceVariant),
        );

        // Tap author text
        await tester.tap(authorFinder);
        await tester.pumpAndSettle();

        // Verify no bottom sheet opened
        expect(find.byType(SaintDetailsSheet), findsNothing);
      },
    );

    testWidgets(
      'tapping author attribution when saint is not found in database does not launch sheet',
      (WidgetTester tester) async {
        SaintDatabase.mockSaints = [];

        final passage = createPassage(
          author: 'Unknown Saint',
          authorSaintId: 'unknown-saint-id',
        );
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryThematicSparkCard(
                passage: passage,
                isBookmarked: false,
                onToggleBookmark: () {},
                onOpenTheme: (_) {},
                onOpenReader: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('— Unknown Saint'));
        await tester.pumpAndSettle();

        expect(find.byType(SaintDetailsSheet), findsNothing);
      },
    );
  });
}
