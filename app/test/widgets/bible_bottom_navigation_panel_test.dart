import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

      final tabController = TabController(length: 2, vsync: const TestVSync());

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
        length: 2,
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
              onTogglePanel: () {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Chapters'), findsOneWidget);
      expect(find.text('Favorites'), findsNothing);
      expect(find.text('Comments'), findsNothing);

      // Chapter 1 button
      expect(find.text('1'), findsWidgets);
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(1));

      tabController.dispose();
    });

    testWidgets('selecting a book switches to Chapter tab', (
      WidgetTester tester,
    ) async {
      BibleBook? selectedBook;
      final tabController = TabController(
        length: 2,
        vsync: const TestVSync(),
        initialIndex: 0, // Books tab
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
              onBookSelectedForPicker: (book) {
                selectedBook = book;
              },
              onChapterSelected: (_, _) {},
              onTogglePanel: () {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Exodus'), findsOneWidget);
      await tester.tap(find.text('Exodus'));
      await tester.pumpAndSettle();

      expect(selectedBook?.bookName, equals('Exodus'));
      expect(tabController.index, equals(1));

      tabController.dispose();
    });

    testWidgets(
      'reveals books and chapters during swipe-up before isPanelExpanded becomes true without overflow',
      (WidgetTester tester) async {
        final tabController = TabController(
          length: 2,
          vsync: const TestVSync(),
          initialIndex: 0,
        );
        final heightController = AnimationController(
          vsync: const TestVSync(),
          lowerBound: 72.0,
          upperBound: 500.0,
          value: 72.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: BibleBottomNavigationPanel(
                  panelHeightAnimation: heightController,
                  isPanelExpanded: false,
                  currentBook: catholicBooks.first,
                  currentChapter: 1,
                  numberingSystem: BibleNumberingSystem.vulgate,
                  sheetTabController: tabController,
                  selectedBookForPicker: catholicBooks.first,
                  onBookSelectedForPicker: (_) {},
                  onChapterSelected: (_, _) {},
                  onTogglePanel: () {},
                  onVerticalDragUpdate: (_) {},
                  onVerticalDragEnd: (_) {},
                ),
              ),
            ),
          ),
        );

        // At collapsed height (72.0), tabs are hidden
        expect(find.text('Books'), findsNothing);
        expect(find.text('Chapters'), findsNothing);

        // Mid-swipe at small height (100.0, where remaining height < TabBar height)
        heightController.value = 100.0;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Books'), findsOneWidget);
        expect(find.text('Chapters'), findsOneWidget);

        // Mid-swipe at 250.0 while isPanelExpanded is still false
        heightController.value = 250.0;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Books'), findsOneWidget);
        expect(find.text('Pentateuch'), findsOneWidget);
        expect(find.text('Genesis'), findsOneWidget);

        heightController.dispose();
        tabController.dispose();
      },
    );
  });
}
