import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/reader/bible_bottom_navigation_panel.dart';

void main() {
  group('BibleBottomNavigationPanel Tests', () {
    testWidgets('renders location title and responds to tap', (
      WidgetTester tester,
    ) async {
      bool panelToggled = false;
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 72.0,
      );

      final tabController = TabController(length: 4, vsync: const TestVSync());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleBottomNavigationPanel(
              panelHeightAnimation: const AlwaysStoppedAnimation(72.0),
              isPanelExpanded: false,
              currentBook: catholicBooks.first,
              currentChapter: 1,
              numberingSystem: BibleNumberingSystem.vulgate,
              sheetTabController: tabController,
              selectedBookForPicker: catholicBooks.first,
              onBookSelectedForPicker: (_) {},
              onChapterSelected: (_, _) {},
              favorites: const [],
              loadingFavorites: false,
              onFavoriteTapped: (_) {},
              onDeleteFavorite: (_) {},
              comments: const [],
              loadingComments: false,
              onCommentTapped: (_) {},
              onEditComment: (_) {},
              onDeleteComment: (_) {},
              onTogglePanel: () {
                panelToggled = true;
              },
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Genesis 1'), findsOneWidget);
      await tester.tap(find.text('Genesis 1'));
      expect(panelToggled, isTrue);

      controller.dispose();
      tabController.dispose();
    });

    testWidgets('renders tabs and chapter buttons when expanded', (
      WidgetTester tester,
    ) async {
      int? selectedChapter;
      final tabController = TabController(
        length: 4,
        vsync: const TestVSync(),
        initialIndex: 1, // Chapter tab
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleBottomNavigationPanel(
              panelHeightAnimation: const AlwaysStoppedAnimation(400.0),
              isPanelExpanded: true,
              currentBook: catholicBooks.first,
              currentChapter: 1,
              numberingSystem: BibleNumberingSystem.vulgate,
              sheetTabController: tabController,
              selectedBookForPicker: catholicBooks.first,
              onBookSelectedForPicker: (_) {},
              onChapterSelected: (_, chap) {
                selectedChapter = chap;
              },
              favorites: const [],
              loadingFavorites: false,
              onFavoriteTapped: (_) {},
              onDeleteFavorite: (_) {},
              comments: const [],
              loadingComments: false,
              onCommentTapped: (_) {},
              onEditComment: (_) {},
              onDeleteComment: (_) {},
              onTogglePanel: () {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Chapters'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);

      // Chapter 1 button
      expect(find.text('1'), findsWidgets);
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(1));

      tabController.dispose();
    });

    testWidgets(
      'Favorites tab: tapping delete displays confirmation; canceling keeps item and confirming invokes onDeleteFavorite',
      (WidgetTester tester) async {
        FavoritePassage? deletedFav;
        const fav = FavoritePassage(
          id: 10,
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          textPreview: 'In the beginning God created heaven and earth.',
        );

        final tabController = TabController(
          length: 4,
          vsync: const TestVSync(),
          initialIndex: 2, // Favorites tab
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleBottomNavigationPanel(
                panelHeightAnimation: const AlwaysStoppedAnimation(400.0),
                isPanelExpanded: true,
                currentBook: catholicBooks.first,
                currentChapter: 1,
                numberingSystem: BibleNumberingSystem.vulgate,
                sheetTabController: tabController,
                selectedBookForPicker: catholicBooks.first,
                onBookSelectedForPicker: (_) {},
                onChapterSelected: (_, _) {},
                favorites: const [fav],
                loadingFavorites: false,
                onFavoriteTapped: (_) {},
                onDeleteFavorite: (f) => deletedFav = f,
                comments: const [],
                loadingComments: false,
                onCommentTapped: (_) {},
                onEditComment: (_) {},
                onDeleteComment: (_) {},
                onTogglePanel: () {},
                onVerticalDragUpdate: (_) {},
                onVerticalDragEnd: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Genesis 1:1'), findsOneWidget);

        // Tap delete icon
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Confirmation dialog is shown
        expect(find.text('Remove Favorite'), findsOneWidget);
        expect(
          find.text('Are you sure you want to remove this favorite passage?'),
          findsOneWidget,
        );

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(deletedFav, isNull);

        // Tap delete again and confirm
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
        await tester.pumpAndSettle();

        expect(deletedFav?.id, equals(10));
        tabController.dispose();
      },
    );

    testWidgets(
      'Comments tab: tapping delete displays confirmation; canceling keeps item and confirming invokes onDeleteComment',
      (WidgetTester tester) async {
        UserComment? deletedComment;
        final comment = UserComment(
          id: 20,
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: 'GEN_1_1',
          commentText: 'My reflection on verse 1',
          createdAt: DateTime(2026, 1, 1),
        );

        final tabController = TabController(
          length: 4,
          vsync: const TestVSync(),
          initialIndex: 3, // Comments tab
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleBottomNavigationPanel(
                panelHeightAnimation: const AlwaysStoppedAnimation(400.0),
                isPanelExpanded: true,
                currentBook: catholicBooks.first,
                currentChapter: 1,
                numberingSystem: BibleNumberingSystem.vulgate,
                sheetTabController: tabController,
                selectedBookForPicker: catholicBooks.first,
                onBookSelectedForPicker: (_) {},
                onChapterSelected: (_, _) {},
                favorites: const [],
                loadingFavorites: false,
                onFavoriteTapped: (_) {},
                onDeleteFavorite: (_) {},
                comments: [comment],
                loadingComments: false,
                onCommentTapped: (_) {},
                onEditComment: (_) {},
                onDeleteComment: (c) => deletedComment = c,
                onTogglePanel: () {},
                onVerticalDragUpdate: (_) {},
                onVerticalDragEnd: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My reflection on verse 1'), findsOneWidget);

        // Tap delete icon
        await tester.tap(find.byTooltip('Delete comment'));
        await tester.pumpAndSettle();

        // Confirmation dialog is shown
        expect(find.text('Delete Comment'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this comment?'),
          findsOneWidget,
        );

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(deletedComment, isNull);

        // Tap delete again and confirm
        await tester.tap(find.byTooltip('Delete comment'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(deletedComment?.id, equals(20));
        tabController.dispose();
      },
    );
  });
}
