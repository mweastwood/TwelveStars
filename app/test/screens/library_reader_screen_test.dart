import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/library_toc_drawer.dart';
import 'package:twelve_stars/widgets/library_section_view.dart';

void main() {
  late BibleDatabase testDb;

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
  });

  tearDown(() async {
    await testDb.close();
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

    testWidgets(
      'LibraryReaderScreen supports swipe navigation between sections',
      (tester) async {
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

        expect(find.text('Section 1 of 35'), findsOneWidget);

        // Swipe left (drag left) to go to next section
        await tester.drag(
          find.text('Prayers').first,
          const Offset(-600.0, 0.0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Section 2 of 35'), findsOneWidget);

        // Swipe right (drag right) to go back to previous section
        await tester.drag(
          find.text('Lesson 1').first,
          const Offset(600.0, 0.0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Section 1 of 35'), findsOneWidget);
      },
    );

    testWidgets(
      'LibraryReaderScreen footer buttons navigate between sections',
      (tester) async {
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

        expect(find.text('Section 1 of 35'), findsOneWidget);

        // Tap Next Section
        await tester.tap(find.byTooltip('Next Section'));
        await tester.pumpAndSettle();

        expect(find.text('Section 2 of 35'), findsOneWidget);

        // Tap Previous Section
        await tester.tap(find.byTooltip('Previous Section'));
        await tester.pumpAndSettle();

        expect(find.text('Section 1 of 35'), findsOneWidget);
      },
    );

    testWidgets(
      'LibraryReaderScreen Table of Contents drawer jumps to selected section',
      (tester) async {
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

        expect(find.text('Section 1 of 35'), findsOneWidget);

        // Open Table of Contents
        await tester.tap(find.byTooltip('Table of Contents'));
        await tester.pumpAndSettle();

        // Tap a section in the TOC
        expect(find.text('Lesson 2'), findsOneWidget);
        await tester.tap(find.text('Lesson 2'));
        await tester.pumpAndSettle();

        expect(find.text('Section 3 of 35'), findsOneWidget);
      },
    );

    testWidgets(
      'LibraryReaderScreen navigates directly to initialSectionId and scrolls to question',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: testBookItem,
              initialAssetPath: 'assets/catechism/json/baltimore_1.json',
              initialSectionId: 'sec_3',
              initialQuestionNumber: 15,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Check that lesson 2 content is displayed (section 3 in Baltimore 1: Lesson 2 / On God And His Perfections)
        expect(find.text('Lesson 2'), findsOneWidget);
        expect(find.text('On God And His Perfections'), findsOneWidget);
        expect(find.text('Section 3 of 35'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText && w.text.toPlainText().contains('Where is God?'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'LibraryReaderScreen falls back gracefully to section 0 if initialSectionId not found',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: testBookItem,
              initialAssetPath: 'assets/catechism/json/baltimore_1.json',
              initialSectionId: 'non_existent_section',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Prayers'), findsOneWidget);
        expect(find.text("The Lord's Prayer"), findsOneWidget);
        expect(find.text('Section 1 of 35'), findsOneWidget);
      },
    );

    testWidgets(
      'LibraryReaderScreen loads St. Justin Martyr (Dialogue with Trypho) and TOC traverses chapters',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final tryphoItem = catalog.firstWhere(
          (b) => b.id == 'justin_dialogue_trypho',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/justin_dialogue_trypho_dods.json',
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: tryphoItem,
              initialAssetPath:
                  'assets/catechism/json/justin_dialogue_trypho_dods.json',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Section 1 of 142'), findsOneWidget);
        expect(find.text('Chapter 1'), findsOneWidget);
        expect(find.text('Introduction'), findsOneWidget);

        // Open Table of Contents drawer
        await tester.tap(find.byTooltip('Table of Contents'));
        await tester.pumpAndSettle();

        expect(find.text('Table of Contents'), findsOneWidget);
        expect(find.text('Introduction'), findsWidgets);

        // Tap Chapter 2 in TOC
        await tester.tap(
          find.text('Justin describes his studies in philosophy'),
        );
        await tester.pumpAndSettle();

        // Check that chapter 2 is loaded
        expect(find.text('Section 2 of 142'), findsOneWidget);
        expect(find.text('Chapter 2'), findsOneWidget);
        expect(
          find.text('Justin describes his studies in philosophy'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'LibraryReaderScreen loads St. Polycarp (Philippians) and TOC traverses all 14 chapters',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final polycarpItem = catalog.firstWhere(
          (b) => b.id == 'polycarp_writings',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/polycarp_philippians_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: polycarpItem,
              initialAssetPath:
                  'assets/catechism/json/polycarp_philippians_lightfoot.json',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Section 1 of 14'), findsOneWidget);
        expect(find.text('Chapter 1'), findsOneWidget);
        expect(
          find.text('Praise of the Philippians for Their Faith and Charity'),
          findsOneWidget,
        );

        // Open Table of Contents drawer
        await tester.tap(find.byTooltip('Table of Contents'));
        await tester.pumpAndSettle();

        expect(find.text('Table of Contents'), findsOneWidget);
        expect(
          find.text('Praise of the Philippians for Their Faith and Charity'),
          findsWidgets,
        );

        // Tap Chapter 2 in TOC
        await tester.tap(
          find.text('An Exhortation to Virtue and Righteousness'),
        );
        await tester.pumpAndSettle();

        // Check that chapter 2 is loaded
        expect(find.text('Section 2 of 14'), findsOneWidget);
        expect(find.text('Chapter 2'), findsOneWidget);
        expect(
          find.text('An Exhortation to Virtue and Righteousness'),
          findsWidgets,
        );
      },
    );
  });
}
