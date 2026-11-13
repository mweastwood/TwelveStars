import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/library_toc_drawer.dart';
import 'package:twelve_stars/widgets/library_section_view.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/reader/library_scripture_modal.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

void main() {
  late BibleDatabase testDb;

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    PrayerDatabase.mockSettings = UserSettings();
    UserSettingsController.instance.resetForTesting();
  });

  tearDown(() async {
    UserSettingsController.instance.resetForTesting();
    PrayerDatabase.mockSettings = null;
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
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(LibraryReaderScreen),
        matchesGoldenFile('goldens/library_reader_screen_golden.png'),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'LibraryReaderScreen supports swipe navigation between sections',
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

    testWidgets(
      'LibraryReaderScreen loads The Epistle to Diognetus and TOC traverses all 12 chapters',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final diognetusItem = catalog.firstWhere(
          (b) => b.id == 'diognetus_lightfoot',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/diognetus_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: diognetusItem,
              initialAssetPath:
                  'assets/catechism/json/diognetus_lightfoot.json',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Section 1 of 12'), findsOneWidget);
        expect(find.text('Chapter 1'), findsOneWidget);
        expect(find.text('Occasion of the Epistle'), findsOneWidget);

        // Open Table of Contents drawer
        await tester.tap(find.byTooltip('Table of Contents'));
        await tester.pumpAndSettle();

        expect(find.text('Table of Contents'), findsOneWidget);
        expect(find.text('Occasion of the Epistle'), findsWidgets);

        // Tap Chapter 2 in TOC
        await tester.tap(find.text('The Vanity of Idols'));
        await tester.pumpAndSettle();

        // Check that chapter 2 is loaded
        expect(find.text('Section 2 of 12'), findsOneWidget);
        expect(find.text('Chapter 2'), findsOneWidget);
        expect(find.text('The Vanity of Idols'), findsWidgets);
      },
    );

    testWidgets(
      'LibraryReaderScreen highlights target item with initialItemIndex and navigationSessionId, then clears after timer',
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
              initialItemIndex: 1,
              navigationSessionId: 'session_123',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Question 14 (item index 1 in sec_3) should be rendered and highlighted
        expect(find.text('Lesson 2'), findsOneWidget);
        expect(find.text('Section 3 of 35'), findsOneWidget);

        // Find AnimatedContainer widgets in LibrarySectionView
        final animatedContainers = tester.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(LibrarySectionView),
            matching: find.byType(AnimatedContainer),
          ),
        );
        // At least one container has a non-transparent background color (highlighted)
        expect(
          animatedContainers.any((c) {
            final dec = c.decoration as BoxDecoration?;
            return dec != null &&
                dec.color != null &&
                dec.color != Colors.transparent;
          }),
          isTrue,
        );

        // Fast forward 2.5 seconds to expire highlight timer
        await tester.pump(const Duration(milliseconds: 2500));

        final updatedContainers = tester.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(LibrarySectionView),
            matching: find.byType(AnimatedContainer),
          ),
        );
        // All containers should now be transparent
        expect(
          updatedContainers.every((c) {
            final dec = c.decoration as BoxDecoration?;
            return dec == null ||
                dec.color == null ||
                dec.color == Colors.transparent;
          }),
          isTrue,
        );
      },
    );

    testWidgets(
      'showReverseCitationsModal resolves multi-volume catalog book and opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/augustine_confessions_book1.json',
          );
        });

        final citation = ReverseCitation(
          sourceBookId: 'augustine_confessions_book1',
          sourceAssetPath:
              'assets/catechism/json/augustine_confessions_book1.json',
          sourceBookTitle: 'The Confessions',
          sourceAuthor: 'St. Augustine of Hippo',
          sectionId: 'book1_ch1',
          sectionTitle: 'Book I, Chapter 1',
          itemIndex: 0,
          snippet:
              'Great art thou, O Lord, and greatly to be praised (Ps 144:3).',
          citation: const BibleCitation(
            rawMatch: 'Ps 144:3',
            displayLabel: 'Psalms 144:3',
            bookNumber: 21,
            bookName: 'Psalms',
            abbrev: 'Ps',
            chapter: 144,
            verse: 3,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showReverseCitationsModal(
                    context: ctx,
                    title: 'Psalms 144:3',
                    citations: [citation],
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        );

        // Open modal
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Library References to Psalms 144:3'), findsOneWidget);
        expect(find.text('By St. Augustine of Hippo'), findsOneWidget);
        expect(find.text('Book I, Chapter 1'), findsOneWidget);
        expect(
          find.text(
            'Great art thou, O Lord, and greatly to be praised (Ps 144:3).',
          ),
          findsOneWidget,
        );

        // Tap "Read in Library"
        await tester.tap(find.text('Read in Library'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Should open LibraryReaderScreen for The Confessions
        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Confessions'), findsOneWidget);
      },
    );

    testWidgets(
      'LibraryReaderScreen handles null defaultAssetPath gracefully without crashing',
      (tester) async {
        const bookWithoutAsset = LibraryBookItem(
          id: 'test_web_book',
          title: 'Test Web Title',
          subtitle: 'Web resource',
          category: 'Catechisms',
          author: 'USCCB',
          description: 'A resource hosted online.',
          webUrl: 'https://example.com',
          defaultAssetPath: null,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: LibraryReaderScreen(
              bookItem: bookWithoutAsset,
              initialAssetPath: null,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(
          find.text(
            'Error loading book: No reader content available for this title.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'in-book search indexes QA explanations and tapping a search result highlights the target item',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_4.json',
          );
        });

        final baltimore4Book = LibraryHelper.getCachedBookData(
          'assets/catechism/json/baltimore_4.json',
        )!;
        // Find a question in Baltimore 4 that has a non-empty explanation
        String? explanationTerm;
        for (final sec in baltimore4Book.sections) {
          for (final item in sec.content) {
            if (item.type == 'qa' &&
                item.explanation != null &&
                item.explanation!.length > 20) {
              explanationTerm = item.explanation!
                  .split(RegExp(r'\s+'))
                  .firstWhere((w) => w.length >= 6);
              break;
            }
          }
          if (explanationTerm != null) break;
        }
        expect(explanationTerm, isNotNull);

        final results = LibraryHelper.searchInBook(
          baltimore4Book,
          explanationTerm!,
        );
        expect(results, isNotEmpty);
        expect(results.first.itemIndex, isNotNull);

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

        // Open search in book and search for 'Where is God'
        await tester.tap(find.byTooltip('Search in Book'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Where is God');
        await tester.pumpAndSettle();

        // Tap the first search result
        await tester.tap(find.byType(ListTile).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Should have navigated to Section 3 and highlighted the matched QA item
        expect(find.text('Section 3 of 35'), findsOneWidget);
        final animatedContainers = tester.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(LibrarySectionView),
            matching: find.byType(AnimatedContainer),
          ),
        );
        expect(
          animatedContainers.any((c) {
            final dec = c.decoration as BoxDecoration?;
            return dec != null &&
                dec.color != null &&
                dec.color != Colors.transparent;
          }),
          isTrue,
        );

        // Expire temporary highlight timer
        await tester.pump(const Duration(milliseconds: 2500));
      },
    );

    testWidgets(
      'switching volumes during initial load ignores stale load generation',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_2.json',
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: testBookItem,
              initialVolumeKey: 'baltimore_1',
            ),
          ),
        );

        // Immediately tap 'No. 2' volume chip before initial load settles
        await tester.tap(find.text('No. 2'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        final chipNo2 = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'No. 2'),
        );
        expect(chipNo2.selected, isTrue);
      },
    );

    testWidgets(
      'selecting a high-index item, searching, and tapping a result in a shorter section clears selection without RangeError and highlights target',
      (tester) async {
        late ParsedBookData baltimore1;
        await tester.runAsync(() async {
          baltimore1 = await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
        });

        // Section 0 ('Prayers') has more items than Section 2 ('Lesson 2', where 'Where is God' is located)
        final longSecIdx = 0;
        final shortSecIdx = 2;
        final shortSecLen = baltimore1.sections[shortSecIdx].content.length;
        expect(
          baltimore1.sections[longSecIdx].content.length,
          greaterThan(shortSecLen),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: testBookItem,
              initialAssetPath: 'assets/catechism/json/baltimore_1.json',
              initialSectionIndex: longSecIdx,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Select an item at an index >= shortSecLen (out of bounds for Section 2)
        final sectionView = tester.widget<LibrarySectionView>(
          find.byType(LibrarySectionView),
        );
        final highIndex = sectionView.section.content.length - 1;
        expect(highIndex, greaterThanOrEqualTo(shortSecLen));
        sectionView.onItemLongPress!(highIndex);
        await tester.pump();

        expect(find.byType(ReaderSelectionActionBar), findsOneWidget);

        // Enter search mode and search for a term in Section 2 ("Where is God")
        await tester.tap(find.byTooltip('Search in Book'));
        await tester.pumpAndSettle();

        expect(find.byType(ReaderSelectionActionBar), findsNothing);

        await tester.enterText(find.byType(TextField), 'Where is God');
        await tester.pumpAndSettle();

        // Tap the first result (in Section 2 'Lesson 2', which has fewer items than highIndex)
        await tester.tap(find.byType(ListTile).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.text('Section 3 of 35'), findsOneWidget);
        expect(find.byType(ReaderSelectionActionBar), findsNothing);

        final animatedContainers = tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byType(LibrarySectionView),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .toList();
        expect(
          animatedContainers.any((c) {
            final dec = c.decoration as BoxDecoration?;
            return dec != null &&
                dec.color != null &&
                dec.color != Colors.transparent;
          }),
          isTrue,
        );

        // Expire temporary highlight timer
        await tester.pump(const Duration(milliseconds: 2500));
      },
    );

    testWidgets(
      'same-section cross-reference navigation clears active selection and highlights target question',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_2.json',
          );
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_4.json',
          );
        });

        // Start in Baltimore No. 2, Section 1 (Lesson First: On the End of Man, Q. 1..5)
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: testBookItem,
              initialVolumeKey: 'baltimore_2',
              initialAssetPath: 'assets/catechism/json/baltimore_2.json',
              initialSectionIndex: 1,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final sectionView = tester.widget<LibrarySectionView>(
          find.byType(LibrarySectionView),
        );
        // Select item 0 (Q. 1)
        sectionView.onItemLongPress!(0);
        await tester.pump();
        expect(find.byType(ReaderSelectionActionBar), findsOneWidget);

        // Trigger cross-ref modal for Q. 3 (also in Section 1 of Baltimore No. 2)
        final q3Index = sectionView.section.content.indexWhere(
          (it) => it.type == 'qa' && it.questionNumber == 3,
        );
        expect(q3Index, greaterThan(0));

        sectionView.onShowCrossRefModal(3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Tap 'Open Vol 2' in the cross-reference bottom sheet (same volume, same section)
        await tester.ensureVisible(find.text('Open Vol 2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Vol 2'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Selection bar should be cleared, and Q. 3 (at q3Index) should be highlighted instead of item 0
        expect(find.byType(ReaderSelectionActionBar), findsNothing);

        final containers = tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byType(LibrarySectionView),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .toList();
        final item0Color =
            (containers[0].decoration as BoxDecoration?)?.color ??
            Colors.transparent;
        final q3Color =
            (containers[q3Index].decoration as BoxDecoration?)?.color ??
            Colors.transparent;
        expect(item0Color, equals(Colors.transparent));
        expect(q3Color, isNot(equals(Colors.transparent)));

        // Expire temporary highlight timer
        await tester.pump(const Duration(milliseconds: 2500));
      },
    );

    test(
      'LibraryReaderAdapter.buildItemCitation and buildItemTextPreview safely handle empty and out-of-bounds indices',
      () {
        final adapter = LibraryReaderAdapter(
          bookItem: testBookItem,
          assetPath: 'assets/catechism/json/baltimore_1.json',
          volumeKey: 'baltimore_1',
          dbHelper: testDb,
        );

        final emptySection = BookSection(
          id: 'empty_sec',
          title: 'Empty Lesson',
          subtitle: '',
          content: [],
        );
        expect(
          adapter.buildItemCitation(emptySection, 0, 5),
          equals('Baltimore Catechism (No. 1), Empty Lesson'),
        );
        expect(adapter.buildItemTextPreview(emptySection, 0, 5), isEmpty);

        final shortSection = BookSection(
          id: 'short_sec',
          title: 'Lesson 1',
          subtitle: '',
          content: [
            ContentItem(
              type: 'qa',
              questionNumber: 1,
              question: 'Who made the world?',
              answer: 'God made the world.',
            ),
            ContentItem(
              type: 'qa',
              questionNumber: 2,
              question: 'Who is God?',
              answer: 'God is the Creator of heaven and earth.',
            ),
          ],
        );

        // Out-of-bounds high indices clamp safely without throwing RangeError
        expect(
          adapter.buildItemCitation(shortSection, 10, 15),
          equals('Baltimore Catechism (No. 1), Lesson 1, Q. 2'),
        );
        // Out-of-bounds negative and high indices clamp to full range 1..2
        expect(
          adapter.buildItemCitation(shortSection, -3, 99),
          equals('Baltimore Catechism (No. 1), Lesson 1, Q. 1–2'),
        );
        expect(
          adapter.buildItemTextPreview(shortSection, 10, 15),
          contains('Who is God?'),
        );
      },
    );

    test(
      'calling saveFavorite / saveBookmark twice for the same passage does not create duplicate rows in library_bookmarks',
      () async {
        final adapter = LibraryReaderAdapter(
          bookItem: testBookItem,
          assetPath: 'assets/catechism/json/baltimore_1.json',
          volumeKey: 'baltimore_1',
          dbHelper: testDb,
        );

        final bookmark = ReaderBookmark(
          id: '',
          documentId: testBookItem.id,
          sectionIndex: 1,
          nodeId: 'baltimore_1:sec_2:0',
          textPreview: 'Q. Who made the world?',
          timestamp: DateTime(2026, 1, 1),
        );

        await adapter.saveFavorite(bookmark);
        await adapter.saveFavorite(bookmark);

        final saved = await testDb.getLibraryBookmarks(
          documentId: testBookItem.id,
        );
        expect(saved, hasLength(1));
        expect(saved.first.nodeId, equals('baltimore_1:sec_2:0'));
      },
    );

    testWidgets(
      'questionKeys and itemKeys share mounted contexts in LibraryReaderScreen',
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
              initialSectionIndex: 1,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final sectionView = tester.widget<LibrarySectionView>(
          find.byType(LibrarySectionView),
        );
        expect(sectionView.itemKeys, isNotNull);
        expect(sectionView.questionKeys, isNotNull);

        // Section 1 has QA items starting with Question 1 at item index 0
        final firstQaIndex = sectionView.section.content.indexWhere(
          (it) => it.type == 'qa' && it.questionNumber != null,
        );
        expect(firstQaIndex, greaterThanOrEqualTo(0));
        final qNum = sectionView.section.content[firstQaIndex].questionNumber!;

        final itemKey = sectionView.itemKeys![firstQaIndex];
        final questionKey = sectionView.questionKeys![qNum];
        expect(itemKey, isNotNull);
        expect(questionKey, isNotNull);
        expect(identical(itemKey, questionKey), isTrue);
        expect(itemKey!.currentContext, isNotNull);
        expect(questionKey!.currentContext, isNotNull);
      },
    );

    testWidgets(
      'section with duplicate questionNumber (e.g. Q. 173 and Q. 173a) renders without duplicate GlobalKey error and mounts questionKeys[173] on first item',
      (tester) async {
        late ParsedBookData baltimore1;
        await tester.runAsync(() async {
          baltimore1 = await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
        });

        // Verify direct LibrarySectionView with two QA items sharing questionNumber 173
        final duplicateQSection = BookSection(
          id: 'dup_q_sec',
          title: 'Lesson with Duplicate Question Number',
          subtitle: '',
          content: [
            ContentItem(
              type: 'qa',
              questionNumber: 173,
              question: 'First Q. 173?',
              answer: 'First answer.',
            ),
            ContentItem(
              type: 'qa',
              questionNumber: 173,
              question: 'Second Q. 173a?',
              answer: 'Second answer.',
            ),
          ],
        );

        final itemKeys = <int, GlobalKey>{0: GlobalKey(), 1: GlobalKey()};
        final questionKeys = <int, GlobalKey>{173: GlobalKey()};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LibrarySectionView(
                section: duplicateQSection,
                fontSize: 16.0,
                verseSystem: 'vulgate',
                itemKeys: itemKeys,
                questionKeys: questionKeys,
                onShowCrossRefModal: (_) {},
                onShowScriptureModal: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(itemKeys[0]!.currentContext, isNotNull);
        expect(itemKeys[1]!.currentContext, isNotNull);
        expect(questionKeys[173]!.currentContext, isNotNull);

        // Also test when questionKeys[173] points to itemKeys[1] (simulating a caller that overwrote questionKeys[173])
        final sharedSecondKey = GlobalKey();
        final itemKeys2 = <int, GlobalKey>{0: GlobalKey(), 1: sharedSecondKey};
        final questionKeys2 = <int, GlobalKey>{173: sharedSecondKey};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LibrarySectionView(
                section: duplicateQSection,
                fontSize: 16.0,
                verseSystem: 'vulgate',
                itemKeys: itemKeys2,
                questionKeys: questionKeys2,
                onShowCrossRefModal: (_) {},
                onShowScriptureModal: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Also test LibraryReaderScreen rendering duplicateQSection (Q. 173 and Q. 173a)
        baltimore1.sections.add(duplicateQSection);
        addTearDown(() {
          baltimore1.sections.remove(duplicateQSection);
        });
        final secWithDupIdx = baltimore1.sections.length - 1;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: LibraryReaderScreen(
              bookItem: testBookItem,
              initialAssetPath: 'assets/catechism/json/baltimore_1.json',
              initialSectionIndex: secWithDupIdx,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        final readerSectionView = tester.widget<LibrarySectionView>(
          find.byType(LibrarySectionView),
        );
        expect(
          identical(
            readerSectionView.questionKeys![173],
            readerSectionView.itemKeys![0],
          ),
          isTrue,
        );
        expect(
          identical(
            readerSectionView.questionKeys![173],
            readerSectionView.itemKeys![1],
          ),
          isFalse,
        );
        expect(readerSectionView.questionKeys![173]!.currentContext, isNotNull);
        expect(readerSectionView.itemKeys![0]!.currentContext, isNotNull);
        expect(readerSectionView.itemKeys![1]!.currentContext, isNotNull);
      },
    );

    testWidgets(
      'showLibraryScriptureModal respects user primaryBibleTranslation and bibleNumberingSystem and handles multi-chapter Modern Psalm 116',
      (tester) async {
        await UserSettingsController.instance.mutate((s) {
          s.primaryBibleTranslation = 'DRC';
          s.bibleNumberingSystem = BibleNumberingSystem.modern;
        });

        // Populate Vulgate Psalms 114 and 115 in DRC
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 114,
                verseNumber: 8,
                verseText: 'DRC Psalm 114 verse 8 (Modern 116:8)',
                translationCode: 'DRC',
              ),
            );
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 114,
                verseNumber: 9,
                verseText: 'DRC Psalm 114 verse 9 (Modern 116:9)',
                translationCode: 'DRC',
              ),
            );
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 115,
                verseNumber: 1,
                verseText: 'DRC Psalm 115 verse 1 (Modern 116:10)',
                translationCode: 'DRC',
              ),
            );

        const citation = BibleCitation(
          rawMatch: 'Ps 116:8-10',
          displayLabel: 'Psalms 116:8-10',
          bookNumber: 21,
          bookName: 'Psalms',
          abbrev: 'Ps',
          chapter: 116,
          verse: 8,
          endVerse: 10,
          verseSystem: 'modern',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showLibraryScriptureModal(
                    context: ctx,
                    citation: citation,
                  ),
                  child: const Text('Open Scripture Modal'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Scripture Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Psalms 116'), findsOneWidget);
        expect(
          find.text('Douay-Rheims Bible (Challoner Revision) (DRC)'),
          findsOneWidget,
        );
        expect(
          find.text('DRC Psalm 114 verse 8 (Modern 116:8)'),
          findsOneWidget,
        );
        expect(
          find.text('DRC Psalm 115 verse 1 (Modern 116:10)'),
          findsOneWidget,
        );
        expect(find.text('10'), findsOneWidget);
      },
    );
  });
}
