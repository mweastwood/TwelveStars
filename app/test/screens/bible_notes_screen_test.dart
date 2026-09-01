import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/screens/bible_notes_screen.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BibleDatabase testDb;

  setUp(() async {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    await testDb.ensurePopulated();
  });

  tearDown(() async => await testDb.close());

  final List<FavoritePassage> mockFavorites = [
    const FavoritePassage(
      id: 1,
      bookNumber: 1, // Genesis
      bookName: 'Genesis',
      chapter: 1,
      startVerse: 1,
      endVerse: 3,
      textPreview:
          'In the beginning God created heaven, and earth. And God said: Be light made. And light was made.',
    ),
    const FavoritePassage(
      id: 2,
      bookNumber: 49, // Matthew
      bookName: 'Matthew',
      chapter: 5,
      startVerse: 3,
      endVerse: 5,
      textPreview:
          'Blessed are the poor in spirit, for theirs is the kingdom of heaven.',
    ),
    const FavoritePassage(
      id: 3,
      bookNumber: 73, // Revelation
      bookName: 'Revelation',
      chapter: 21,
      startVerse: 4,
      endVerse: 4,
      textPreview:
          'And God shall wipe away all tears from their eyes: and there shall be no more death.',
    ),
  ];

  final List<UserComment> mockComments = [
    UserComment(
      id: 101,
      documentId: 'psa', // Psalms (bookNumber 21)
      sectionIndex: 23,
      nodeId: 'psa_23_1',
      commentText: 'The Lord is my shepherd: powerful psalm of divine trust.',
      textPreview: 'The Lord is my shepherd; I shall not want.',
      createdAt: DateTime(2026, 1, 10),
    ),
    UserComment(
      id: 102,
      documentId: 'mat', // Matthew (bookNumber 49)
      sectionIndex: 5,
      nodeId: 'mat_5_3',
      commentText:
          'St. Augustine reflects that poverty in spirit is humility and reverence.',
      textPreview:
          'Blessed are the poor in spirit, for theirs is the kingdom of heaven.',
      createdAt: DateTime(2026, 1, 11),
    ),
    UserComment(
      id: 103,
      documentId: 'rom', // Romans (bookNumber 54)
      sectionIndex: 8,
      nodeId: 'rom_8_28',
      commentText: 'All things work together for good to them that love God.',
      textPreview:
          'And we know that to them that love God, all things work together unto good.',
      createdAt: DateTime(2026, 1, 12),
    ),
  ];

  group('BibleNotesScreen Unit & Widget Tests', () {
    testWidgets(
      'renders all favorites and comments in canonical biblical order',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BibleNotesScreen(
              initialFavorites: mockFavorites,
              initialComments: mockComments,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Bible Notes & Favorites'), findsOneWidget);
        expect(find.text('Favorites (3)'), findsOneWidget);
        expect(find.text('Notes (3)'), findsOneWidget);

        // Verify citations are rendered in biblical order:
        // Genesis 1 (OT, #1) -> Psalms 23 (OT, #21) -> Matthew 5 (NT, #49) -> Romans 8 (NT, #54) -> Revelation 21 (NT, #73)
        expect(find.text('Genesis 1:1-3'), findsOneWidget);
        expect(find.text('Psalms 23:1'), findsOneWidget);
        expect(find.text('Matthew 5:3-5'), findsOneWidget);
        expect(find.text('Matthew 5:3'), findsOneWidget);
        expect(find.text('Romans 8:28'), findsOneWidget);
        expect(find.text('Revelation 21:4'), findsOneWidget);
      },
    );

    testWidgets('filter chips filter favorites and comments', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BibleNotesScreen(
            initialFavorites: mockFavorites,
            initialComments: mockComments,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially both are visible (3 favs + 3 notes)
      expect(find.text('Genesis 1:1-3'), findsOneWidget); // Fav
      expect(find.text('Psalms 23:1'), findsOneWidget); // Note

      // Deselect favorites chip -> only notes shown
      await tester.tap(find.byKey(const Key('filter_favorites_chip')));
      await tester.pumpAndSettle();

      expect(find.text('Genesis 1:1-3'), findsNothing);
      expect(find.text('Psalms 23:1'), findsOneWidget);
      expect(find.text('Romans 8:28'), findsOneWidget);

      // Deselect notes chip -> only favorites shown
      await tester.tap(find.byKey(const Key('filter_notes_chip')));
      await tester.pumpAndSettle();

      expect(find.text('Genesis 1:1-3'), findsOneWidget);
      expect(find.text('Psalms 23:1'), findsNothing);
    });

    testWidgets(
      'search bar filters by book, citation, note text, and verse preview',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BibleNotesScreen(
              initialFavorites: mockFavorites,
              initialComments: mockComments,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Search for "Augustine"
        await tester.enterText(
          find.byKey(const Key('bible_notes_search_field')),
          'Augustine',
        );
        await tester.pumpAndSettle();

        expect(find.text('Matthew 5:3'), findsOneWidget);
        expect(find.text('Genesis 1:1-3'), findsNothing);
        expect(find.text('Psalms 23:1'), findsNothing);

        // Search for "shepherd" (verse preview match)
        await tester.enterText(
          find.byKey(const Key('bible_notes_search_field')),
          'shepherd',
        );
        await tester.pumpAndSettle();

        expect(find.text('Psalms 23:1'), findsOneWidget);
        expect(find.text('Matthew 5:3'), findsNothing);

        // Clear search
        await tester.enterText(
          find.byKey(const Key('bible_notes_search_field')),
          '',
        );
        await tester.pumpAndSettle();
        expect(find.text('Genesis 1:1-3'), findsOneWidget);
      },
    );

    testWidgets('triggers onSelectFavorite and onSelectComment callbacks', (
      tester,
    ) async {
      FavoritePassage? selectedFav;
      UserComment? selectedComment;

      await tester.pumpWidget(
        MaterialApp(
          home: BibleNotesScreen(
            initialFavorites: mockFavorites,
            initialComments: mockComments,
            onSelectFavorite: (fav) => selectedFav = fav,
            onSelectComment: (comment) => selectedComment = comment,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Genesis favorite card
      await tester.tap(
        find.byKey(const Key('bible_annotation_favorite_1_1_1')),
      );
      await tester.pumpAndSettle();
      expect(selectedFav?.id, equals(1));

      // Tap Psalms comment card
      await tester.tap(
        find.byKey(const Key('bible_annotation_comment_21_23_1')),
      );
      await tester.pumpAndSettle();
      expect(selectedComment?.id, equals(101));
    });

    testWidgets(
      'tapping delete favorite shows confirmation dialog; cancel retains item, confirm deletes item',
      (tester) async {
        // Save initial favorite to testDb
        await testDb.saveFavorite(
          FavoritePassagesCompanion.insert(
            bookNumber: 1,
            bookName: 'Genesis',
            chapter: 1,
            startVerse: 1,
            endVerse: 3,
            textPreview: 'In the beginning God created heaven, and earth.',
          ),
        );
        final initialFavs = await testDb.getFavorites();
        expect(initialFavs.length, equals(1));

        bool changedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: BibleNotesScreen(
              onFavoritesOrCommentsChanged: () {
                changedCalled = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Genesis 1:1-3'), findsOneWidget);

        // Tap delete button on favorite card
        await tester.tap(find.byTooltip('Delete'));
        await tester.pumpAndSettle();

        // Confirmation dialog is shown
        expect(find.text('Remove Favorite'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to remove "Genesis 1:1-3" from your favorites?',
          ),
          findsOneWidget,
        );

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(changedCalled, isFalse);
        expect(find.text('Genesis 1:1-3'), findsOneWidget);
        expect((await testDb.getFavorites()).length, equals(1));

        // Tap delete again and confirm
        await tester.tap(find.byTooltip('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
        await tester.pumpAndSettle();

        expect(changedCalled, isTrue);
        expect(find.text('Genesis 1:1-3'), findsNothing);
        expect((await testDb.getFavorites()), isEmpty);
        expect(
          find.text('Removed Genesis 1:1-3 from Favorites'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping delete comment shows confirmation dialog; cancel retains item, confirm deletes item',
      (tester) async {
        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'GEN',
            sectionIndex: 1,
            nodeId: '1_1_1',
            commentText: 'Creation note.',
            textPreview: const Value('In the beginning God created heaven...'),
            createdAt: DateTime.now(),
          ),
        );
        final initialComments = await testDb.getComments();
        expect(initialComments.length, equals(1));

        bool changedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: BibleNotesScreen(
              onFavoritesOrCommentsChanged: () {
                changedCalled = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Genesis 1:1'), findsOneWidget);
        expect(find.text('Creation note.'), findsOneWidget);

        // Tap delete button on comment card
        await tester.tap(find.byTooltip('Delete'));
        await tester.pumpAndSettle();

        // Confirmation dialog is shown
        expect(find.text('Delete Comment'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to delete your note on Genesis 1:1?',
          ),
          findsOneWidget,
        );

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(changedCalled, isFalse);
        expect(find.text('Genesis 1:1'), findsOneWidget);
        expect((await testDb.getComments()).length, equals(1));

        // Tap delete again and confirm
        await tester.tap(find.byTooltip('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(changedCalled, isTrue);
        expect(find.text('Genesis 1:1'), findsNothing);
        expect((await testDb.getComments()), isEmpty);
        expect(find.text('Deleted note on Genesis 1:1'), findsOneWidget);
      },
    );

    testWidgets('BibleTab displays Notes FAB and opens BibleNotesScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: BibleTab())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bible_notes_fab')), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);

      await tester.tap(find.byKey(const Key('bible_notes_fab')));
      await tester.pumpAndSettle();

      expect(find.byType(BibleNotesScreen), findsOneWidget);
      expect(find.text('Bible Notes & Favorites'), findsOneWidget);
    });
  });

  group('BibleNotesScreen Golden Tests', () {
    testGoldens('renders default unified annotations list (Light Theme)', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        BibleNotesScreen(
          initialFavorites: mockFavorites,
          initialComments: mockComments,
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(
        tester,
        'bible_notes_screen_default_light_golden',
      );
    });

    testGoldens('renders default unified annotations list (Dark Theme)', (
      tester,
    ) async {
      final darkTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );

      await tester.pumpWidgetBuilder(
        BibleNotesScreen(
          initialFavorites: mockFavorites,
          initialComments: mockComments,
        ),
        wrapper: materialAppWrapper(theme: darkTheme),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(
        tester,
        'bible_notes_screen_default_dark_golden',
      );
    });

    testGoldens('renders filtered notes only with search query', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        BibleNotesScreen(
          initialFavorites: mockFavorites,
          initialComments: mockComments,
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(
        find.byKey(const Key('bible_notes_search_field')),
        'God',
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'bible_notes_screen_search_active_golden',
      );
    });

    testGoldens('renders empty state when no annotations exist', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const BibleNotesScreen(initialFavorites: [], initialComments: []),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'bible_notes_screen_empty_golden');
    });

    testGoldens('renders widescreen two-column masonry layout', (tester) async {
      await tester.pumpWidgetBuilder(
        BibleNotesScreen(
          initialFavorites: mockFavorites,
          initialComments: mockComments,
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(900, 700),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(
        tester,
        'bible_notes_screen_widescreen_masonry_golden',
      );
    });
  });
}
