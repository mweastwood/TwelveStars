import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_catalog_view.dart';
import 'package:twelve_stars/widgets/library/library_continue_reading_hero.dart';
import '../../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('renders search bar, category chips, and catalog books', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryCatalogView(
            onOpenReader:
                (
                  book, {
                  volumeKey,
                  assetPath,
                  sectionId,
                  sectionIndex,
                  questionNumber,
                  itemIndex,
                }) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search catechisms & library...'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Catechisms'), findsOneWidget);
    expect(find.text('CATECHISMS & DOCTRINE'), findsOneWidget);
  });

  testWidgets('tapping category chip filters catalog list', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryCatalogView(
            onOpenReader:
                (
                  book, {
                  volumeKey,
                  assetPath,
                  sectionId,
                  sectionIndex,
                  questionNumber,
                  itemIndex,
                }) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Apostolic Fathers'));
    await tester.pumpAndSettle();

    expect(find.text('APOSTOLIC FATHERS'), findsOneWidget);
  });

  testWidgets('tapping Read Book on single book calls onOpenReader', (
    tester,
  ) async {
    LibraryBookItem? openedBook;

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryCatalogView(
            onOpenReader:
                (
                  book, {
                  volumeKey,
                  assetPath,
                  sectionId,
                  sectionIndex,
                  questionNumber,
                  itemIndex,
                }) {
                  openedBook = book;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final readButtons = find.widgetWithText(FilledButton, 'Read Book');
    expect(readButtons, findsWidgets);

    await tester.ensureVisible(readButtons.first);
    await tester.tap(readButtons.first);
    await tester.pumpAndSettle();

    expect(openedBook, isNotNull);
  });

  testWidgets('tapping volume picker modal sheet selects a volume', (
    tester,
  ) async {
    LibraryBookItem? openedBook;
    String? openedVolKey;
    String? openedAsset;

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryCatalogView(
            onOpenReader:
                (
                  book, {
                  volumeKey,
                  assetPath,
                  sectionId,
                  sectionIndex,
                  questionNumber,
                  itemIndex,
                }) {
                  openedBook = book;
                  openedVolKey = volumeKey;
                  openedAsset = assetPath;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final browseBtn = find.widgetWithText(TextButton, 'Browse All ▾').first;
    await tester.tap(browseBtn);
    await tester.pumpAndSettle();

    // Bottom sheet is displayed
    expect(find.textContaining('Select from'), findsOneWidget);

    final listTile = find.byType(ListTile).first;
    await tester.tap(listTile);
    await tester.pumpAndSettle();

    expect(openedBook, isNotNull);
    expect(openedVolKey, isNotNull);
    expect(openedAsset, isNotNull);
  });

  testWidgets(
    'renders continue reading hero when latestReadingPosition is provided',
    (tester) async {
      final pos = BookReadingPosition(
        bookId: 'didache_lightfoot',
        sectionIndex: 2,
        sectionId: 'ch3',
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryCatalogView(
              latestReadingPosition: pos,
              onOpenReader:
                  (
                    book, {
                    volumeKey,
                    assetPath,
                    sectionId,
                    sectionIndex,
                    questionNumber,
                    itemIndex,
                  }) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE READING'), findsOneWidget);
      expect(
        find.widgetWithText(LibraryContinueReadingHero, 'The Didache'),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders injected custom catalog books when provided', (
    tester,
  ) async {
    const customBook = LibraryBookItem(
      id: 'custom_book_1',
      title: 'Custom Injected Book',
      subtitle: 'A custom book subtitle',
      category: 'Custom Category',
      author: 'Author Name',
      description: 'Custom description for book',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryCatalogView(
            catalog: const [customBook],
            onOpenReader:
                (
                  book, {
                  volumeKey,
                  assetPath,
                  sectionId,
                  sectionIndex,
                  questionNumber,
                  itemIndex,
                }) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Custom Injected Book'), findsOneWidget);
    expect(find.text('Custom description for book'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Custom Category'), findsOneWidget);
    expect(find.text('1 WORK'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Custom Category'));
    await tester.pumpAndSettle();

    expect(find.text('CUSTOM CATEGORY'), findsOneWidget);
  });
}
