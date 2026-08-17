import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/library_tab.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
import '../test_helper.dart';

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

  group('LibraryTab Golden & Widget Tests', () {
    testGoldens('LibraryTab renders catalog correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Library Tab Landing Catalog',
          const SizedBox(height: 600, child: Scaffold(body: LibraryTab())),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'library_tab_catalog_golden');
    });

    testWidgets('renders catalog header and book cards', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      expect(find.text('CATECHISMS & DOCTRINE'), findsOneWidget);
      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.text('Catechism of the Council of Trent'), findsOneWidget);
      expect(find.text('The Didache'), findsOneWidget);
      expect(find.text('First Epistle of Clement'), findsOneWidget);
      expect(find.text('Second Epistle of Clement'), findsOneWidget);

      // Verify Baltimore Catechism volume chips exist
      expect(find.text('No. 1 (First Communion)'), findsOneWidget);
      expect(find.text('No. 2 (Confirmation & Grammar)'), findsOneWidget);
      expect(find.text('No. 3 (Post-Confirmation Course)'), findsOneWidget);
      expect(find.text('No. 4 (Explanation by Fr. Kinkead)'), findsOneWidget);
    });

    testWidgets('tapping volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_1.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final vol1Chip = find.text('No. 1 (First Communion)');
      await tester.tap(vol1Chip);
      await tester.pumpAndSettle();

      // Reader screen should be visible
      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Baltimore Catechism'), findsWidgets);
    });

    testWidgets(
      'tapping Read Book on First Clement opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/first_clement_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final clementCard = find.ancestor(
          of: find.text('First Epistle of Clement'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: clementCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('First Epistle of Clement'), findsWidgets);
      },
    );

    testWidgets('tapping Read Book on Didache opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/didache_lightfoot.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final didacheCard = find.ancestor(
        of: find.text('The Didache'),
        matching: find.byType(Card),
      );
      final readBtn = find.descendant(
        of: didacheCard,
        matching: find.widgetWithText(FilledButton, 'Read Book'),
      );

      await tester.scrollUntilVisible(
        readBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(readBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The Didache'), findsWidgets);
    });

    testWidgets('Favorites tab displays saved bookmarks and can delete them', (
      tester,
    ) async {
      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'didache',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          textPreview: 'The Didache, Chapter 1, Q. 1\nThere are two ways...',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      // Tap Favorites tab
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('The Didache, Chapter 1, Q. 1'), findsOneWidget);
      expect(find.text('There are two ways...'), findsOneWidget);

      // Delete the favorite
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(
        find.text('No favorite passages saved in Library yet.'),
        findsOneWidget,
      );
    });

    testWidgets('Comments tab displays saved comments and can delete them', (
      tester,
    ) async {
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'baltimore_catechism',
          sectionIndex: 0,
          nodeId: 'no1:lesson_01_1',
          commentText: 'Important lesson on God.',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      // Tap Comments tab
      await tester.tap(find.text('Comments'));
      await tester.pumpAndSettle();

      expect(find.text('Important lesson on God.'), findsOneWidget);

      // Delete the comment
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('No comments on library books yet.'), findsOneWidget);
    });
  });

  group('LibraryReaderScreen Widget Tests', () {
    testWidgets('loads and renders book section and volume switching', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final baltimore = catalog.firstWhere(
        (b) => b.id == 'baltimore_catechism',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_1.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify reader toolbar and content loaded
      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Open Table of Contents sheet
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.text('Table of Contents'), findsOneWidget);
    });

    testWidgets(
      'long-press enters selection mode, saves favorite and adds comment',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final didache = catalog.firstWhere((b) => b.id == 'didache_lightfoot');

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/didache_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(body: LibraryReaderScreen(bookItem: didache)),
          ),
        );
        await tester.pumpAndSettle();

        // Long press first content item
        final firstItem = find.textContaining('There are two ways').first;
        await tester.longPress(firstItem);
        await tester.pumpAndSettle();

        // Selection action bar should appear
        expect(find.byType(ReaderSelectionActionBar), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.comment_outlined), findsOneWidget);

        // Tap Save Favorite
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Check database for bookmark
        final bookmarks = await testDb.getLibraryBookmarks(
          documentId: 'didache_lightfoot',
        );
        expect(bookmarks.length, 1);

        // Selection cleared after save
        expect(find.byType(ReaderSelectionActionBar), findsNothing);

        // Long press again to add comment
        await tester.longPress(firstItem);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.comment_outlined));
        await tester.pumpAndSettle();

        // Add Comment dialog appears
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);

        await tester.enterText(
          find.byType(TextField).last,
          'My note on the two ways',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final comments = await testDb.getComments(
          documentId: 'didache_lightfoot',
        );
        expect(comments.length, 1);
        expect(comments.first.commentText, 'My note on the two ways');

        // Verify comment badge is displayed
        expect(find.byIcon(Icons.comment_rounded), findsWidgets);
      },
    );

    testWidgets(
      'displays comment badge on series books with volume-prefixed nodeId',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final baltimore = catalog.firstWhere(
          (b) => b.id == 'baltimore_catechism',
        );

        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'baltimore_catechism',
            sectionIndex: 0,
            nodeId: 'no1:sec_1_0',
            commentText: 'Note on First Communion Q1',
            createdAt: DateTime.now(),
          ),
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryReaderScreen(
                bookItem: baltimore,
                initialVolumeKey: 'no1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify comment badge is visible on the Baltimore Catechism item
        expect(find.byIcon(Icons.comment_rounded), findsWidgets);
        expect(find.text('1'), findsWidgets);
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Baltimore No. 3 with Cross-References',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final baltimore = catalog.firstWhere(
          (b) => b.id == 'baltimore_catechism',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_3.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no3',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'catechism_baltimore_3_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Baltimore No. 4 with Explanations',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final baltimore = catalog.firstWhere(
          (b) => b.id == 'baltimore_catechism',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_4.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no4',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'catechism_baltimore_4_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Catechism of the Council of Trent',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final trent = catalog.firstWhere((b) => b.id == 'council_of_trent');

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/council_of_trent.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: trent)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'catechism_trent_reader_golden');
      },
    );

    testWidgets('renders interactive Scripture citation chip', (tester) async {
      final catalog = LibraryHelper.getCatalog();
      final baltimore = catalog.firstWhere(
        (b) => b.id == 'baltimore_catechism',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_4.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no4',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
    });
  });
}
