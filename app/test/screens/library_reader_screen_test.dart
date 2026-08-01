import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/library_toc_drawer.dart';
import 'package:twelve_stars/widgets/library_section_view.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('LibraryReaderScreen Widget & Golden Tests', () {
    final testBookItem = LibraryBookItem(
      id: 'baltimore_catechism',
      title: 'Baltimore Catechism',
      subtitle: 'Official Catechism for Plenary Councils',
      category: 'Catechisms',
      author: 'Third Plenary Council of Baltimore',
      description: 'A classic summary of Catholic doctrine.',
      defaultAssetPath: 'assets/catechism/json/baltimore_1.json',
      volumes: [
        const BaltimoreVolume(
          volumeKey: 'baltimore_1',
          name: 'Baltimore Catechism No. 1',
          shortName: 'No. 1',
          description: 'First edition',
          assetPath: 'assets/catechism/json/baltimore_1.json',
        ),
        const BaltimoreVolume(
          volumeKey: 'baltimore_2',
          name: 'Baltimore Catechism No. 2',
          shortName: 'No. 2',
          description: 'Second edition',
          assetPath: 'assets/catechism/json/baltimore_2.json',
        ),
      ],
    );

    testWidgets('LibraryTocDrawer renders table of contents list correctly', (
      tester,
    ) async {
      final sampleBook = ParsedBookData(
        bookId: 'test_book',
        title: 'Test Catechism',
        subtitle: 'Sub',
        author: 'Author',
        toc: [],
        sections: [
          BookSection(
            id: 'sec_1',
            title: 'Lesson First: On Faith',
            subtitle: 'Basics of Faith',
            content: [],
          ),
          BookSection(
            id: 'sec_2',
            title: 'Lesson Second: On God',
            subtitle: 'Nature of God',
            content: [],
          ),
        ],
      );

      int selectedIdx = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryTocDrawer(
              book: sampleBook,
              currentSectionIndex: 0,
              onSectionSelected: (idx) {
                selectedIdx = idx;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Table of Contents'), findsOneWidget);
      expect(find.text('Lesson First: On Faith'), findsOneWidget);
      expect(find.text('Lesson Second: On God'), findsOneWidget);

      await tester.tap(find.text('Lesson Second: On God'));
      await tester.pumpAndSettle();

      expect(selectedIdx, equals(1));
    });

    testWidgets('LibrarySectionView renders Q&A and headers properly', (
      tester,
    ) async {
      final sampleSection = BookSection(
        id: 'sec_1',
        title: 'Lesson 1: God and Creation',
        subtitle: 'Questions 1 to 5',
        content: [
          ContentItem(
            type: 'qa',
            questionNumber: 1,
            question: 'Who made the world?',
            answer: 'God made the world.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibrarySectionView(
              section: sampleSection,
              fontSize: 16.0,
              verseSystem: 'vulgate',
              onShowCrossRefModal: (_) {},
              onShowScriptureModal: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lesson 1: God and Creation'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Who made the world?'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('God made the world.'),
        ),
        findsOneWidget,
      );
    });

    testGoldens('LibraryReaderScreen renders reader UI correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: LibraryReaderScreen(
            bookItem: testBookItem,
            initialAssetPath: 'assets/catechism/json/baltimore_1.json',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(LibraryReaderScreen),
        matchesGoldenFile('goldens/library_reader_screen_golden.png'),
      );
    });
  });
}
