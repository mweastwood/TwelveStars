import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_comments_view.dart';
import 'package:twelve_stars/widgets/library/library_favorites_view.dart';
import 'package:twelve_stars/widgets/library/library_saved_sheet.dart';

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

  testWidgets('renders sheet title, tabs, and default Favorites view', (
    tester,
  ) async {
    final fav = LibraryBookmark(
      id: 101,
      documentId: 'didache_lightfoot',
      sectionIndex: 0,
      nodeId: 'ch1_0',
      textPreview: 'The Didache, Chapter 1\nThere are two ways...',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: [fav],
            loadingFavorites: false,
            comments: const [],
            loadingComments: false,
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
    await tester.pumpAndSettle();

    expect(find.text('Saved in Library'), findsOneWidget);
    expect(find.byIcon(Icons.bookmarks_rounded), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Favorites'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Comments'), findsOneWidget);
    expect(find.byType(LibraryFavoritesView), findsOneWidget);
    expect(find.text('The Didache, Chapter 1'), findsOneWidget);
  });

  testWidgets('switches tabs between Favorites and Comments views', (
    tester,
  ) async {
    final fav = LibraryBookmark(
      id: 101,
      documentId: 'didache_lightfoot',
      sectionIndex: 0,
      nodeId: 'ch1_0',
      textPreview: 'Favorite Preview Text',
      createdAt: DateTime.now(),
    );
    final comment = UserComment(
      id: 201,
      documentId: 'first_clement_lightfoot',
      sectionIndex: 1,
      nodeId: 'ch2_1',
      commentText: 'My Clement comment',
      textPreview: 'Comment Preview Text',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: [fav],
            loadingFavorites: false,
            comments: [comment],
            loadingComments: false,
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
    await tester.pumpAndSettle();

    // Favorites tab initially selected
    expect(find.text('Favorite Preview Text'), findsOneWidget);
    expect(find.text('My Clement comment'), findsNothing);

    // Switch to Comments tab
    await tester.tap(find.widgetWithText(Tab, 'Comments'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryCommentsView), findsOneWidget);
    expect(find.text('My Clement comment'), findsOneWidget);
    expect(find.text('Favorite Preview Text'), findsNothing);

    // Switch back to Favorites tab
    await tester.tap(find.widgetWithText(Tab, 'Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Favorite Preview Text'), findsOneWidget);
  });

  testWidgets('renders loading state for favorites and comments tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: const [],
            loadingFavorites: true,
            comments: const [],
            loadingComments: true,
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
    await tester.pump();

    // Favorites tab loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Switch to Comments tab
    await tester.tap(find.widgetWithText(Tab, 'Comments'));
    await tester.pump();

    // Comments tab loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when favorites and comments are empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: const [],
            loadingFavorites: false,
            comments: const [],
            loadingComments: false,
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
    await tester.pumpAndSettle();

    expect(
      find.text('No favorite passages saved in Library yet.'),
      findsOneWidget,
    );

    // Switch to Comments tab
    await tester.tap(find.widgetWithText(Tab, 'Comments'));
    await tester.pumpAndSettle();

    expect(find.text('No comments on library books yet.'), findsOneWidget);
  });

  testWidgets('filters bookmarks by book chip in Favorites view', (
    tester,
  ) async {
    final fav1 = LibraryBookmark(
      id: 101,
      documentId: 'didache_lightfoot',
      sectionIndex: 0,
      nodeId: 'ch1_0',
      textPreview: 'The Didache, Chapter 1',
      createdAt: DateTime.now(),
    );
    final fav2 = LibraryBookmark(
      id: 102,
      documentId: 'first_clement_lightfoot',
      sectionIndex: 1,
      nodeId: 'ch2_1',
      textPreview: 'First Clement, Chapter 2',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: [fav1, fav2],
            loadingFavorites: false,
            comments: const [],
            loadingComments: false,
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
    await tester.pumpAndSettle();

    expect(find.text('The Didache, Chapter 1'), findsOneWidget);
    expect(find.text('First Clement, Chapter 2'), findsOneWidget);

    // Filter by Didache chip
    await tester.tap(find.text('The Didache (1)'));
    await tester.pumpAndSettle();

    expect(find.text('The Didache, Chapter 1'), findsOneWidget);
    expect(find.text('First Clement, Chapter 2'), findsNothing);
  });

  testWidgets('deletes favorite item and updates database and callbacks', (
    tester,
  ) async {
    final fav = LibraryBookmark(
      id: 301,
      documentId: 'didache_lightfoot',
      sectionIndex: 0,
      nodeId: 'ch1_0',
      textPreview: 'Didache bookmark to remove',
      createdAt: DateTime.now(),
    );

    await testDb.saveLibraryBookmark(
      LibraryBookmarksCompanion.insert(
        id: const Value(301),
        documentId: fav.documentId,
        sectionIndex: fav.sectionIndex,
        nodeId: fav.nodeId,
        textPreview: fav.textPreview,
        createdAt: fav.createdAt,
      ),
    );

    bool favoritesChangedCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: [fav],
            loadingFavorites: false,
            comments: const [],
            loadingComments: false,
            onFavoritesChanged: () {
              favoritesChangedCalled = true;
            },
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
    await tester.pumpAndSettle();

    expect(find.text('Didache bookmark to remove'), findsOneWidget);

    // Tap delete icon on favorite
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(favoritesChangedCalled, isTrue);

    // Verify deleted from db
    final bookmarksInDb = await testDb.getLibraryBookmarks();
    expect(bookmarksInDb.any((b) => b.id == 301), isFalse);
  });

  testWidgets('deletes comment item and updates database and callbacks', (
    tester,
  ) async {
    final comment = UserComment(
      id: 401,
      documentId: 'didache_lightfoot',
      sectionIndex: 0,
      nodeId: 'ch1_0',
      commentText: 'Didache note to delete',
      textPreview: 'Didache preview',
      createdAt: DateTime.now(),
    );

    await testDb.saveComment(
      UserCommentsCompanion.insert(
        id: const Value(401),
        documentId: comment.documentId,
        sectionIndex: comment.sectionIndex,
        nodeId: comment.nodeId,
        commentText: comment.commentText,
        textPreview: Value(comment.textPreview),
        createdAt: comment.createdAt,
      ),
    );

    bool commentsChangedCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: const [],
            loadingFavorites: false,
            comments: [comment],
            loadingComments: false,
            onCommentsChanged: () {
              commentsChangedCalled = true;
            },
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
    await tester.pumpAndSettle();

    // Switch to Comments tab
    await tester.tap(find.widgetWithText(Tab, 'Comments'));
    await tester.pumpAndSettle();

    expect(find.text('Didache note to delete'), findsOneWidget);

    // Tap delete icon on comment -> brings up confirmation dialog
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete Comment'), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(commentsChangedCalled, isTrue);

    // Verify deleted from db
    final commentsInDb = await testDb.getComments();
    expect(commentsInDb.any((c) => c.id == 401), isFalse);
  });

  testWidgets('triggers onOpenReader callback when tapping item', (
    tester,
  ) async {
    final fav = LibraryBookmark(
      id: 501,
      documentId: 'didache_lightfoot',
      sectionIndex: 2,
      nodeId: 'ch3_0',
      textPreview: 'Tap to open Didache',
      createdAt: DateTime.now(),
    );

    LibraryBookItem? openedBook;
    int? openedSectionIndex;

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibrarySavedSheet(
            favorites: [fav],
            loadingFavorites: false,
            comments: const [],
            loadingComments: false,
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
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to open Didache'));
    await tester.pumpAndSettle();

    expect(openedBook?.id, 'didache_lightfoot');
    expect(openedSectionIndex, 2);
  });

  testWidgets('pops navigator when close button is pressed', (tester) async {
    bool popped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => LibrarySavedSheet(
                      favorites: const [],
                      loadingFavorites: false,
                      comments: const [],
                      loadingComments: false,
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
                  ).then((_) => popped = true);
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Saved in Library'), findsOneWidget);

    // Tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Saved in Library'), findsNothing);
    expect(popped, isTrue);
  });
}
