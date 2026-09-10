import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_favorites_view.dart';
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

  testWidgets('renders loading indicator when isLoading is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryFavoritesView(
            favorites: const [],
            isLoading: true,
            onRefresh: () {},
            onOpenReader:
                (
                  book, {
                  volumeKey,
                  assetPath,
                  sectionIndex,
                  itemIndex,
                  questionNumber,
                }) {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when favorites is empty', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryFavoritesView(
            favorites: const [],
            isLoading: false,
            onRefresh: () {},
            onOpenReader:
                (
                  book, {
                  volumeKey,
                  assetPath,
                  sectionIndex,
                  itemIndex,
                  questionNumber,
                }) {},
          ),
        ),
      ),
    );

    expect(
      find.text('No favorite passages saved in Library yet.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders favorites list, filters by book, deletes, and opens reader',
    (tester) async {
      final fav1 = LibraryBookmark(
        id: 101,
        documentId: 'didache_lightfoot',
        sectionIndex: 0,
        nodeId: 'ch1_0',
        textPreview: 'The Didache, Chapter 1\nThere are two ways...',
        createdAt: DateTime.now(),
      );
      final fav2 = LibraryBookmark(
        id: 102,
        documentId: 'first_clement_lightfoot',
        sectionIndex: 1,
        nodeId: 'ch2_1',
        textPreview: 'First Clement, Chapter 2\nDeep peace was given to all...',
        createdAt: DateTime.now(),
      );

      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          id: const Value(101),
          documentId: fav1.documentId,
          sectionIndex: fav1.sectionIndex,
          nodeId: fav1.nodeId,
          textPreview: fav1.textPreview,
          createdAt: fav1.createdAt,
        ),
      );

      bool refreshCalled = false;
      LibraryBookItem? openedBook;
      int? openedSectionIndex;
      int? openedItemIndex;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryFavoritesView(
              favorites: [fav1, fav2],
              isLoading: false,
              onRefresh: () {
                refreshCalled = true;
              },
              onOpenReader:
                  (
                    book, {
                    volumeKey,
                    assetPath,
                    sectionIndex,
                    itemIndex,
                    questionNumber,
                  }) {
                    openedBook = book;
                    openedSectionIndex = sectionIndex;
                    openedItemIndex = itemIndex;
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check items rendered
      expect(find.text('The Didache, Chapter 1'), findsOneWidget);
      expect(find.text('First Clement, Chapter 2'), findsOneWidget);

      // Filter by book
      expect(find.text('The Didache (1)'), findsOneWidget);
      await tester.tap(find.text('The Didache (1)'));
      await tester.pumpAndSettle();

      expect(find.text('The Didache, Chapter 1'), findsOneWidget);
      expect(find.text('First Clement, Chapter 2'), findsNothing);

      // Tap favorite to open reader
      await tester.tap(find.text('The Didache, Chapter 1'));
      await tester.pumpAndSettle();

      expect(openedBook?.id, 'didache_lightfoot');
      expect(openedSectionIndex, 0);
      expect(openedItemIndex, 0);

      // Delete favorite
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
      final inDb = await testDb.getLibraryBookmarks();
      expect(inDb.any((b) => b.id == 101), isFalse);
    },
  );

  testWidgets(
    'renders custom catalog book info and opens reader with injected catalog',
    (tester) async {
      const customBook = LibraryBookItem(
        id: 'custom_favorite_book',
        title: 'Custom Favorite Book',
        subtitle: 'Subtitle',
        category: 'Custom Category',
        author: 'Author',
        description: 'Description',
      );

      final fav = LibraryBookmark(
        id: 501,
        documentId: 'custom_favorite_book',
        sectionIndex: 0,
        nodeId: 'ch1_0',
        textPreview: 'Custom Favorite Book, Chapter 1\nSome snippet...',
        createdAt: DateTime.now(),
      );

      LibraryBookItem? openedBook;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryFavoritesView(
              catalog: const [customBook],
              favorites: [fav],
              isLoading: false,
              onRefresh: () {},
              onOpenReader:
                  (
                    book, {
                    volumeKey,
                    assetPath,
                    sectionIndex,
                    itemIndex,
                    questionNumber,
                  }) {
                    openedBook = book;
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Favorite Book, Chapter 1'), findsOneWidget);
      await tester.tap(find.text('Custom Favorite Book, Chapter 1'));
      await tester.pumpAndSettle();

      expect(openedBook?.id, 'custom_favorite_book');
      expect(openedBook?.title, 'Custom Favorite Book');
    },
  );
}
