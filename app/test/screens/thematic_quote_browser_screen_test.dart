import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';

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

  group('ThematicHelper Taxonomy & Querying Logic', () {
    test('defines all 35 themes and 7 category groups', () {
      expect(ThematicHelper.categoryGroups.length, 7);
      expect(ThematicHelper.allThemes.length, 35);
      expect(
        ThematicHelper.getThemeTitle('sacraments.eucharist'),
        'The Most Holy Eucharist & The Mass',
      );
      expect(
        ThematicHelper.getThemeTitle('sacraments.baptism'),
        'Holy Baptism & Regeneration',
      );
      expect(
        ThematicHelper.getThemeTitle('sacraments.confirmation'),
        'Confirmation & Holy Chrism',
      );
      expect(
        ThematicHelper.getThemeTitle('theology.trinity'),
        'The Holy Trinity & Divine Nature',
      );
      expect(
        ThematicHelper.getThemeTitle('prayer.vocal_mental_meditation'),
        'Vocal & Mental Prayer, Our Father',
      );
      expect(
        ThematicHelper.getThemeTitle('combat.spiritual_warfare'),
        'Spiritual Warfare & Discernment',
      );
      expect(
        ThematicHelper.getThemeTitle('virtues.faith_hope_charity'),
        'Theological Virtues: Faith, Hope & Charity',
      );
      expect(
        ThematicHelper.getThemeTitle('ecclesiology.church_unity_papacy'),
        'Unity of the Church & Papacy',
      );
      expect(
        ThematicHelper.getThemeTitle('devotion.our_lady'),
        'The Blessed Virgin Mary & Consecration',
      );
      expect(
        ThematicHelper.getThemeTitle('unknown.theme.fallback'),
        'unknown.theme.fallback',
      );
    });

    test('loadAllPassages and getThemeCounts return valid datasets', () async {
      final passages = await ThematicHelper.loadAllPassages();
      expect(passages, isNotEmpty);

      final counts = await ThematicHelper.getThemeCounts();
      expect(counts, isNotEmpty);
      expect(counts.containsKey('sacraments.eucharist'), isTrue);
      expect(counts['sacraments.eucharist']! > 0, isTrue);
    });

    test('getPassagesForTheme filters matching passages', () async {
      final eucharistPassages = await ThematicHelper.getPassagesForTheme(
        'sacraments.eucharist',
        shuffle: false,
      );
      expect(eucharistPassages, isNotEmpty);
      for (final p in eucharistPassages) {
        final matches =
            p.primaryTheme == 'sacraments.eucharist' ||
            p.secondaryThemes.contains('sacraments.eucharist');
        expect(matches, isTrue);
      }

      final unshuffled = await ThematicHelper.getPassagesForTheme(
        'sacraments.eucharist',
        shuffle: false,
      );
      final unshuffledSecond = await ThematicHelper.getPassagesForTheme(
        'sacraments.eucharist',
        shuffle: false,
      );
      expect(unshuffled.length, unshuffledSecond.length);
      for (var i = 0; i < unshuffled.length; i++) {
        expect(unshuffled[i].bookId, unshuffledSecond[i].bookId);
        expect(unshuffled[i].sectionId, unshuffledSecond[i].sectionId);
      }
    });
  });

  group('ThematicQuoteBrowserScreen Widget Tests', () {
    testWidgets('renders standalone mode with AppBar and theme selector', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
            embedded: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('The Most Holy Eucharist & The Mass'), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsWidgets);
    });

    testWidgets('renders embedded mode without outer AppBar/Scaffold', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThematicQuoteBrowserScreen(
              initialThemeId: 'sacraments.eucharist',
              embedded: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Only the outer parent Scaffold, no nested AppBar
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('The Most Holy Eucharist & The Mass'), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    });

    testWidgets('theme switching sheet opens and switches theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap theme selector button
      await tester.tap(find.text('The Most Holy Eucharist & The Mass'));
      await tester.pumpAndSettle();

      expect(find.text('Select Theme'), findsOneWidget);
      expect(find.text('The Seven Sacraments'), findsOneWidget);

      // Tap Baptism theme item in the sheet
      final baptismFinder = find.text('Holy Baptism & Regeneration');
      expect(baptismFinder, findsOneWidget);
      await tester.tap(baptismFinder);
      await tester.pumpAndSettle();

      // Sheet should be dismissed and theme title updated
      expect(find.text('Select Theme'), findsNothing);
      expect(find.text('Holy Baptism & Regeneration'), findsOneWidget);
    });

    testWidgets('vertical scrolling updates page index pill', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial pill should show 1 / N
      expect(find.textContaining('1 / '), findsOneWidget);

      // Drag PageView upwards from outer margin to go to page 2 without scrollview interception
      await tester.dragFrom(const Offset(5, 300), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Should now show 2 / N
      expect(find.textContaining('2 / '), findsOneWidget);
    });

    testWidgets('bookmark toggling saves and deletes bookmark in database', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no bookmarks initially
      var bookmarks = await testDb.getLibraryBookmarks();
      expect(bookmarks, isEmpty);

      // Tap favorite icon to bookmark
      final favoriteBtn = find.byIcon(Icons.favorite_border_rounded).first;
      await tester.tap(favoriteBtn);
      await tester.pumpAndSettle();

      // Verify bookmark saved
      bookmarks = await testDb.getLibraryBookmarks();
      expect(bookmarks.length, 1);
      expect(find.text('Saved to favorites! ❤️'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      // Tap favorite icon again to remove bookmark
      await tester.tap(find.byIcon(Icons.favorite_rounded).first);
      await tester.pumpAndSettle();

      // Verify bookmark deleted
      bookmarks = await testDb.getLibraryBookmarks();
      expect(bookmarks, isEmpty);
      expect(find.text('Removed from favorites'), findsOneWidget);
    });

    testWidgets('tapping Read in Context navigates to LibraryReaderScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
          ),
        ),
      );

      await tester.pumpAndSettle();

      final readContextBtn = find.text('Read in Context').first;
      await tester.tap(readContextBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
    });

    testWidgets('empty state renders when theme has no quotes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'theology.unindexed_sample_theme',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Unindexed theme should show empty state
      expect(find.text('No Quotes Available for this Theme'), findsOneWidget);
      expect(find.text('Change Theme'), findsOneWidget);

      // Tapping Change Theme button opens theme picker sheet
      await tester.tap(find.text('Change Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Select Theme'), findsOneWidget);
    });

    testWidgets('reshuffle button reloads theme quotes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
          ),
        ),
      );

      await tester.pumpAndSettle();

      final shuffleBtn = find.byIcon(Icons.shuffle_rounded);
      expect(shuffleBtn, findsOneWidget);
      await tester.tap(shuffleBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('1 / '), findsOneWidget);
    });
  });
}
