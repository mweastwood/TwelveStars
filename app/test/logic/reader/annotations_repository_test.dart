import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/reader/annotations_repository.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';

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

  Widget buildTestScaffold({required WidgetBuilder builder}) {
    return MaterialApp(
      home: Scaffold(body: Builder(builder: builder)),
    );
  }

  group('AnnotationsRepository CRUD Tests', () {
    test(
      'addComment, updateComment, and deleteComment work end-to-end',
      () async {
        final id = await AnnotationsRepository.addComment(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: 'gen_1_1',
          commentText: 'Initial creation note.',
          textPreview: 'In the beginning God created heaven, and earth.',
          translationId: 'CPDV',
        );
        expect(id, greaterThan(0));

        var comments = await testDb.getComments(
          documentId: 'GEN',
          nodeId: 'gen_1_1',
        );
        expect(comments, hasLength(1));
        expect(comments.first.commentText, equals('Initial creation note.'));
        expect(
          comments.first.textPreview,
          equals('In the beginning God created heaven, and earth.'),
        );

        await AnnotationsRepository.updateComment(id, 'Updated creation note.');
        comments = await testDb.getComments(
          documentId: 'GEN',
          nodeId: 'gen_1_1',
        );
        expect(comments, hasLength(1));
        expect(comments.first.commentText, equals('Updated creation note.'));

        await AnnotationsRepository.deleteComment(id);
        comments = await testDb.getComments(
          documentId: 'GEN',
          nodeId: 'gen_1_1',
        );
        expect(comments, isEmpty);
      },
    );

    test(
      'addComment falls back to targetSubtext when textPreview is null',
      () async {
        await AnnotationsRepository.addComment(
          documentId: 'aquinas_summa',
          sectionIndex: 0,
          nodeId: 'q1_a1',
          commentText: 'Sacred doctrine note.',
          targetSubtext:
              'Whether, besides philosophy, any further doctrine is required?',
        );

        final comments = await testDb.getComments(
          documentId: 'aquinas_summa',
          nodeId: 'q1_a1',
        );
        expect(comments, hasLength(1));
        expect(
          comments.first.textPreview,
          equals(
            'Whether, besides philosophy, any further doctrine is required?',
          ),
        );
      },
    );

    test(
      'saveFavoritePassage and deleteFavoritePassage resolve bookName and persist',
      () async {
        final favId = await AnnotationsRepository.saveFavoritePassage(
          bookNumber: 52,
          chapter: 1,
          startVerse: 1,
          endVerse: 5,
          textPreview: 'In the beginning was the Word...',
          translationId: 'CPDV',
        );
        expect(favId, greaterThan(0));

        var favorites = await testDb.getFavoritesForChapter(52, 1);
        expect(favorites, hasLength(1));
        expect(favorites.first.bookName, equals('John'));
        expect(favorites.first.startVerse, equals(1));
        expect(favorites.first.endVerse, equals(5));
        expect(
          favorites.first.textPreview,
          equals('In the beginning was the Word...'),
        );

        await AnnotationsRepository.deleteFavoritePassage(favId);
        favorites = await testDb.getFavoritesForChapter(52, 1);
        expect(favorites, isEmpty);
      },
    );

    test('deleteLibraryBookmark removes library bookmark by id', () async {
      final bookmarkId = await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'council_of_trent',
          sectionIndex: 2,
          nodeId: 'sec_2_p1',
          textPreview: 'On the Creed.',
          createdAt: DateTime(2026, 9, 1),
        ),
      );

      var bookmarks = await testDb.getLibraryBookmarks(
        documentId: 'council_of_trent',
      );
      expect(bookmarks, hasLength(1));

      await AnnotationsRepository.deleteLibraryBookmark(bookmarkId);
      bookmarks = await testDb.getLibraryBookmarks(
        documentId: 'council_of_trent',
      );
      expect(bookmarks, isEmpty);
    });
  });

  group('Modal Integration with AnnotationsRepository', () {
    testWidgets(
      'showAddCommentDialog and showEditCommentDialog persist via AnnotationsRepository',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddCommentDialog(
                context: context,
                citation: 'Genesis 1:1',
                textPreview: 'In the beginning God created heaven, and earth.',
                documentId: 'GEN',
                sectionIndex: 1,
                nodeId: 'gen_1_1',
              ),
              child: const Text('Add Comment'),
            ),
          ),
        );

        await tester.tap(find.text('Add Comment'));
        await tester.pumpAndSettle();

        expect(find.text('Add Comment for Genesis 1:1'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'First comment');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        var comments = await testDb.getComments(nodeId: 'gen_1_1');
        expect(comments, hasLength(1));
        expect(comments.first.commentText, equals('First comment'));

        final commentId = comments.first.id;
        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showEditCommentDialog(
                context: context,
                citation: 'Genesis 1:1',
                textPreview: 'In the beginning God created heaven, and earth.',
                commentId: commentId,
                initialText: 'First comment',
              ),
              child: const Text('Edit Comment'),
            ),
          ),
        );

        await tester.tap(find.text('Edit Comment'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Comment for Genesis 1:1'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Edited comment');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        comments = await testDb.getComments(nodeId: 'gen_1_1');
        expect(comments.first.commentText, equals('Edited comment'));
      },
    );

    testWidgets(
      'showVerseCommentsModal and showVerseFavoritesModal delete via AnnotationsRepository',
      (WidgetTester tester) async {
        await AnnotationsRepository.addComment(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: 'gen_1_1',
          commentText: 'Modal comment to delete',
          textPreview: 'In the beginning...',
        );
        final comments = await testDb.getComments(nodeId: 'gen_1_1');

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseCommentsModal(
                context: context,
                title: 'Genesis 1:1',
                nodeId: 'gen_1_1',
                textPreview: 'In the beginning...',
                comments: List.of(comments),
                onCommentsChanged: () {},
                onAddComment: () {},
              ),
              child: const Text('Open Comments'),
            ),
          ),
        );

        await tester.tap(find.text('Open Comments'));
        await tester.pumpAndSettle();

        expect(find.text('Comments for Genesis 1:1'), findsOneWidget);
        await tester.tap(find.byTooltip('Delete comment'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(await testDb.getComments(nodeId: 'gen_1_1'), isEmpty);

        // Close comments modal
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        await AnnotationsRepository.saveFavoritePassage(
          bookNumber: 1,
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          textPreview: 'In the beginning...',
          translationId: 'CPDV',
        );
        final favorites = await testDb.getFavoritesForChapter(1, 1);

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseFavoritesModal(
                context: context,
                title: 'Genesis 1:1',
                favorites: List.of(favorites),
                onFavoritesChanged: () {},
              ),
              child: const Text('Open Favorites'),
            ),
          ),
        );

        await tester.tap(find.text('Open Favorites'));
        await tester.pumpAndSettle();

        expect(find.text('Favorite Passage for Genesis 1:1'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
        await tester.pumpAndSettle();

        expect(await testDb.getFavoritesForChapter(1, 1), isEmpty);
      },
    );
  });
}
