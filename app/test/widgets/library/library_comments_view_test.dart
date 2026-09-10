import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_comments_view.dart';
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
          body: LibraryCommentsView(
            comments: const [],
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

  testWidgets('renders empty state when comments is empty', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryCommentsView(
            comments: const [],
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

    expect(find.text('No comments on library books yet.'), findsOneWidget);
  });

  testWidgets(
    'renders comments, filters by book, confirms deletion, and opens reader',
    (tester) async {
      final comment1 = UserComment(
        id: 201,
        documentId: 'didache_lightfoot',
        sectionIndex: 0,
        nodeId: 'ch1_0',
        commentText: 'My note on Didache',
        textPreview: 'There are two ways',
        createdAt: DateTime.now(),
      );
      final comment2 = UserComment(
        id: 202,
        documentId: 'baltimore_catechism',
        sectionIndex: 0,
        nodeId: 'no1:lesson_01_1',
        commentText: 'My catechism note',
        textPreview: 'Who made the world?',
        createdAt: DateTime.now(),
      );

      await testDb.saveComment(
        UserCommentsCompanion.insert(
          id: const Value(201),
          documentId: comment1.documentId,
          sectionIndex: comment1.sectionIndex,
          nodeId: comment1.nodeId,
          commentText: comment1.commentText,
          textPreview: Value(comment1.textPreview),
          createdAt: comment1.createdAt,
        ),
      );

      bool refreshCalled = false;
      LibraryBookItem? openedBook;
      int? openedSectionIndex;
      int? openedItemIndex;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryCommentsView(
              comments: [comment1, comment2],
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
      expect(find.text('The Didache'), findsOneWidget);
      expect(find.text('My note on Didache'), findsOneWidget);
      expect(find.text('"There are two ways"'), findsOneWidget);
      expect(find.text('Baltimore Catechism (No. 1)'), findsOneWidget);

      // Filter by book
      expect(find.text('The Didache (1)'), findsOneWidget);
      await tester.tap(find.text('The Didache (1)'));
      await tester.pumpAndSettle();

      expect(find.text('The Didache'), findsOneWidget);
      expect(find.text('Baltimore Catechism (No. 1)'), findsNothing);

      // Tap comment to open reader
      await tester.tap(find.text('The Didache'));
      await tester.pumpAndSettle();

      expect(openedBook?.id, 'didache_lightfoot');
      expect(openedSectionIndex, 0);
      expect(openedItemIndex, 0);

      // Tap delete button -> dialog appears
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Comment'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this comment?'),
        findsOneWidget,
      );

      // Confirm delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
      final inDb = await testDb.getComments();
      expect(inDb.any((c) => c.id == 201), isFalse);
    },
  );
}
