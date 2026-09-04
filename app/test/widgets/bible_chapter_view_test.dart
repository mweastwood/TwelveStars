import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/widgets/bible_chapter_view.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/bible_ribbons_widget.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleDatabase testDb;
  final List<String> clipboardLog = [];

  final genesisBook = catholicBooks.firstWhere((b) => b.bookNumber == 1);

  const mockCpdvVersesCh1 = [
    'In the beginning God created heaven, and earth.',
    'And the earth was void and empty, and darkness was upon the face of the deep.',
    'And God said: Be light made. And light was made.',
    'And God saw the light that it was good; and he divided the light from the darkness.',
  ];

  const mockDrcVersesCh1 = [
    'In the beginning God created heaven, and earth (DRC).',
    'And the earth was void and empty (DRC).',
    'And God said: Be light made. And light was made (DRC).',
    'And God saw the light that it was good (DRC).',
  ];

  const mockCpdvVersesCh2 = [
    'So the heavens and the earth were finished, and all their array.',
    'And on the seventh day God ended his work which he had made.',
  ];

  Future<void> seedVerses(
    BibleDatabase db, {
    required int bookNumber,
    required String bookName,
    required int chapter,
    required String translationCode,
    required List<String> verseTexts,
  }) async {
    for (int i = 0; i < verseTexts.length; i++) {
      await db
          .into(db.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              bookNumber: bookNumber,
              bookName: bookName,
              chapter: chapter,
              verseNumber: i + 1,
              verseText: verseTexts[i],
              translationCode: translationCode,
            ),
          );
    }
  }

  setUp(() async {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    clipboardLog.clear();
    ReverseCitationService.clear();
    LibraryHelper.clearCache();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            final text = args?['text'] as String?;
            if (text != null) clipboardLog.add(text);
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': clipboardLog.isNotEmpty ? clipboardLog.last : ''};
          }
          if (methodCall.method == 'SystemSound.play') {
            return null;
          }
          return null;
        });

    await seedVerses(
      testDb,
      bookNumber: 1,
      bookName: 'Genesis',
      chapter: 1,
      translationCode: 'CPDV',
      verseTexts: mockCpdvVersesCh1,
    );
    await seedVerses(
      testDb,
      bookNumber: 1,
      bookName: 'Genesis',
      chapter: 1,
      translationCode: 'DRC',
      verseTexts: mockDrcVersesCh1,
    );
    await seedVerses(
      testDb,
      bookNumber: 1,
      bookName: 'Genesis',
      chapter: 2,
      translationCode: 'CPDV',
      verseTexts: mockCpdvVersesCh2,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    ReverseCitationService.clear();
    LibraryHelper.clearCache();
    await testDb.close();
  });

  group('Group 1: Rendering, Typography, & Header Layout', () {
    testWidgets('Single Translation Header & Verses renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify chapter title formatted according to numbering system
      expect(find.text('Genesis 1'), findsOneWidget);

      // Verify subtitle displays single translation name
      expect(
        find.text('Catholic Public Domain Version (CPDV)'),
        findsOneWidget,
      );

      // Verify each verse row renders the verse number and verse text
      for (int i = 0; i < mockCpdvVersesCh1.length; i++) {
        expect(find.text('${i + 1}'), findsOneWidget);
        expect(find.text(mockCpdvVersesCh1[i]), findsOneWidget);
      }
    });

    testWidgets('Dual-Column Compare Translation View renders side-by-side', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'DRC',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify subtitle displays dual translation names separated by delimiter
      expect(
        find.text(
          'Catholic Public Domain Version (CPDV)  |  Douay-Rheims Bible (DRC)',
        ),
        findsOneWidget,
      );

      // Verify each verse row receives both primary verse text and compareVerseText
      final verseRows = tester
          .widgetList<BibleVerseRow>(find.byType(BibleVerseRow))
          .toList();
      expect(verseRows.length, equals(mockCpdvVersesCh1.length));

      for (int i = 0; i < mockCpdvVersesCh1.length; i++) {
        expect(verseRows[i].verseText, equals(mockCpdvVersesCh1[i]));
        expect(verseRows[i].compareVerseText, equals(mockDrcVersesCh1[i]));
      }
    });

    testWidgets(
      'Translation Selector Animation mounts SizeTransition with top spacing',
      (WidgetTester tester) async {
        final animationController = AnimationController(
          vsync: const TestVSync(),
          value: 0.5,
        );
        addTearDown(animationController.dispose);

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                translationSelectorAnimation: animationController,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SizeTransition), findsOneWidget);
        final sizeTransition = tester.widget<SizeTransition>(
          find.byType(SizeTransition),
        );
        expect(sizeTransition.sizeFactor, equals(animationController));
        expect(sizeTransition.alignment, equals(Alignment.topCenter));
      },
    );

    testWidgets(
      'Reverse Citations Integration displays chip and opens citations modal',
      (WidgetTester tester) async {
        final testBookData = ParsedBookData(
          bookId: 'test_commentary',
          title: 'Catechism Commentary',
          subtitle: '',
          author: 'Church Father',
          toc: [],
          sections: [
            BookSection(
              id: 'sec1',
              title: 'Section 1',
              subtitle: '',
              content: [
                ContentItem(type: 'text', text: 'See Genesis 1 for creation.'),
              ],
            ),
          ],
        );
        ReverseCitationService.indexBookData('test_source_key', testBookData);

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify that the ActionChip with the library references count is visible
        expect(find.byType(ActionChip), findsOneWidget);
        expect(find.text('1 Library Reference to Genesis 1'), findsOneWidget);

        // Verify tapping the chip invokes showReverseCitationsModal
        await tester.tap(find.byType(ActionChip));
        await tester.pumpAndSettle();

        expect(find.text('Library References to Genesis 1'), findsOneWidget);
        expect(find.text('Catechism Commentary'), findsOneWidget);
      },
    );
  });

  group('Group 2: Multi-Verse Long-Press & Selection Range', () {
    testWidgets('Long-Press Selection marks verse and mounts action bar', (
      WidgetTester tester,
    ) async {
      bool? selectionState;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              onSelectionChanged: (selected) => selectionState = selected,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long-press on verse 2
      final verse2Finder = find.widgetWithText(
        BibleVerseRow,
        mockCpdvVersesCh1[1],
      );
      await tester.longPress(verse2Finder);
      await tester.pump();

      // Verify verse 2 is marked selected
      final verse2Row = tester.widget<BibleVerseRow>(verse2Finder);
      expect(verse2Row.isSelected, isTrue);

      // Verify other verses are not selected
      final verse1Row = tester.widget<BibleVerseRow>(
        find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[0]),
      );
      expect(verse1Row.isSelected, isFalse);

      // Verify onSelectionChanged callback is triggered with true
      expect(selectionState, isTrue);

      // Verify ReaderSelectionActionBar is mounted at the bottom of the stack
      expect(find.byType(ReaderSelectionActionBar), findsOneWidget);
      expect(find.text('Genesis 1:2'), findsOneWidget);
      expect(find.text('1 verse selected'), findsOneWidget);
    });

    testWidgets('Range Expansion & Contraction via Tap updates selection range', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long-press on verse 2
      await tester.longPress(
        find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[1]),
      );
      await tester.pump();

      // With verse 2 selected, tap on verse 4
      await tester.tap(
        find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[3]),
      );
      await tester.pump();

      // Verify verses 2, 3, and 4 are highlighted as selected
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[0]),
            )
            .isSelected,
        isFalse,
      );
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[1]),
            )
            .isSelected,
        isTrue,
      );
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[2]),
            )
            .isSelected,
        isTrue,
      );
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[3]),
            )
            .isSelected,
        isTrue,
      );

      // Verify citation title in ReaderSelectionActionBar displays "Genesis 1:2-4" with item count "3 verses"
      expect(find.text('Genesis 1:2-4'), findsOneWidget);
      expect(find.text('3 verses selected'), findsOneWidget);

      // Tap on verse 1
      await tester.tap(
        find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[0]),
      );
      await tester.pump();

      // Verify range updates to verses 1 through 2
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[0]),
            )
            .isSelected,
        isTrue,
      );
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[1]),
            )
            .isSelected,
        isTrue,
      );
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[2]),
            )
            .isSelected,
        isFalse,
      );
      expect(
        tester
            .widget<BibleVerseRow>(
              find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[3]),
            )
            .isSelected,
        isFalse,
      );
      expect(find.text('Genesis 1:1-2'), findsOneWidget);
      expect(find.text('2 verses selected'), findsOneWidget);
    });

    testWidgets(
      'Clear Selection clears verses, invokes callback, removes action bar',
      (WidgetTester tester) async {
        bool? selectionState;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                onSelectionChanged: (selected) => selectionState = selected,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select verse 2
        await tester.longPress(
          find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[1]),
        );
        await tester.pump();
        expect(selectionState, isTrue);
        expect(find.byType(ReaderSelectionActionBar), findsOneWidget);

        // Tap clear button on ReaderSelectionActionBar
        await tester.tap(find.byTooltip('Clear Selection'));
        await tester.pump();

        // Verify all verses are deselected
        for (final text in mockCpdvVersesCh1) {
          expect(
            tester
                .widget<BibleVerseRow>(find.widgetWithText(BibleVerseRow, text))
                .isSelected,
            isFalse,
          );
        }

        // Verify onSelectionChanged callback is triggered with false
        expect(selectionState, isFalse);

        // Verify ReaderSelectionActionBar is removed from widget tree
        expect(find.byType(ReaderSelectionActionBar), findsNothing);
      },
    );

    testWidgets('Selection Reset on Book/Chapter Change', (
      WidgetTester tester,
    ) async {
      bool? selectionState;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              onSelectionChanged: (selected) => selectionState = selected,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select verse 2 in Chapter 1
      await tester.longPress(
        find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[1]),
      );
      await tester.pump();
      expect(selectionState, isTrue);

      selectionState = null;

      // Trigger widget update via tester.pumpWidget with chapter: 2
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 2,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              onSelectionChanged: (selected) => selectionState = selected,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify selection is cleared and onSelectionChanged(false) is invoked
      expect(selectionState, isFalse);
      expect(find.byType(ReaderSelectionActionBar), findsNothing);

      // Verify Chapter 2 verses are rendered and not selected
      for (final text in mockCpdvVersesCh2) {
        expect(
          tester
              .widget<BibleVerseRow>(find.widgetWithText(BibleVerseRow, text))
              .isSelected,
          isFalse,
        );
      }
    });
  });

  group('Group 3: Selection Action Bar Actions', () {
    testWidgets(
      'Save to Favorites inserts row, shows SnackBar, clears selection',
      (WidgetTester tester) async {
        bool favoriteSavedCalled = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                onFavoriteSaved: () => favoriteSavedCalled = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select verses 1 to 2
        await tester.longPress(
          find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[0]),
        );
        await tester.pump();
        await tester.tap(
          find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[1]),
        );
        await tester.pump();

        // Tap "Save Favorite" icon in ReaderSelectionActionBar
        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        // Verify favorite row is inserted into testDb.favoritePassages
        final favorites = await testDb.select(testDb.favoritePassages).get();
        expect(favorites.length, equals(1));
        expect(favorites.first.bookNumber, equals(1));
        expect(favorites.first.chapter, equals(1));
        expect(favorites.first.startVerse, equals(1));
        expect(favorites.first.endVerse, equals(2));

        // Verify onFavoriteSaved callback is called
        expect(favoriteSavedCalled, isTrue);

        // Verify floating SnackBar displaying "Saved Genesis 1:1-2 to Favorites" is shown
        expect(find.text('Saved Genesis 1:1-2 to Favorites'), findsOneWidget);

        // Verify selection is automatically cleared
        expect(find.byType(ReaderSelectionActionBar), findsNothing);
      },
    );

    testWidgets('Add Comment Dialog displays modal with citation context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select verse 3
      await tester.longPress(
        find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[2]),
      );
      await tester.pump();

      // Tap "Add Comment" icon in ReaderSelectionActionBar
      await tester.tap(find.byTooltip('Add Comment'));
      await tester.pumpAndSettle();

      // Verify comment dialog modal is displayed with the appropriate citation context
      expect(find.text('Add Comment for Genesis 1:3'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Add Comment for Genesis 1:3'), findsNothing);
    });

    testWidgets(
      'Copy to Clipboard copies formatted text, shows SnackBar, clears selection',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select verses 1 to 2
        await tester.longPress(
          find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[0]),
        );
        await tester.pump();
        await tester.tap(
          find.widgetWithText(BibleVerseRow, mockCpdvVersesCh1[1]),
        );
        await tester.pump();

        // Tap "Copy" icon in ReaderSelectionActionBar
        await tester.tap(find.byTooltip('Copy selection'));
        await tester.pumpAndSettle();

        // Verify clipboard receives formatted text ("Genesis 1:1-2\n1 ...\n2 ...")
        final expectedClipboardText =
            'Genesis 1:1-2\n1 ${mockCpdvVersesCh1[0]}\n2 ${mockCpdvVersesCh1[1]}';
        expect(clipboardLog, contains(expectedClipboardText));

        // Verify SnackBar displaying "Copied Genesis 1:1-2 to clipboard" is shown
        expect(find.text('Copied Genesis 1:1-2 to clipboard'), findsOneWidget);

        // Verify selection is cleared
        expect(find.byType(ReaderSelectionActionBar), findsNothing);
      },
    );
  });

  group('Group 4: Navigation Session, Programmatic Scrolling & Highlight', () {
    testWidgets('Target Verse Scroll & Highlight Timer activates and expires', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              scrollToVerse: 3,
              highlightStartVerse: 3,
              highlightEndVerse: 3,
              navigationSessionId: 'session_1',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Verify verse 3 is temporarily highlighted
      final verse3Finder = find.widgetWithText(
        BibleVerseRow,
        mockCpdvVersesCh1[2],
      );
      expect(tester.widget<BibleVerseRow>(verse3Finder).isSelected, isTrue);

      // Advance clock by 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Verify temporary highlight is dismissed
      expect(tester.widget<BibleVerseRow>(verse3Finder).isSelected, isFalse);
    });

    testWidgets('Session ID Idempotence & Re-Triggering', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              scrollToVerse: 3,
              highlightStartVerse: 3,
              highlightEndVerse: 3,
              navigationSessionId: 'session_1',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final verse3Finder = find.widgetWithText(
        BibleVerseRow,
        mockCpdvVersesCh1[2],
      );
      expect(tester.widget<BibleVerseRow>(verse3Finder).isSelected, isTrue);

      // Advance past the 2-second highlight timer
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<BibleVerseRow>(verse3Finder).isSelected, isFalse);

      // Re-pump widget with identical navigationSessionId: 'session_1'
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              scrollToVerse: 3,
              highlightStartVerse: 3,
              highlightEndVerse: 3,
              navigationSessionId: 'session_1',
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify scroll/highlight logic does not re-trigger
      expect(tester.widget<BibleVerseRow>(verse3Finder).isSelected, isFalse);

      // Update widget with new navigationSessionId: 'session_2'
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              scrollToVerse: 3,
              highlightStartVerse: 3,
              highlightEndVerse: 3,
              navigationSessionId: 'session_2',
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify highlight re-engages and sets a new timer
      expect(tester.widget<BibleVerseRow>(verse3Finder).isSelected, isTrue);

      // Advance 2 seconds and verify dismissal
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<BibleVerseRow>(verse3Finder).isSelected, isFalse);
    });
  });

  group('Group 5: Ribbon Bookmarks & State Persistence', () {
    testWidgets('Ribbon Bookmark Display renders ribbon for matching chapter', (
      WidgetTester tester,
    ) async {
      const matchingBookmark = BibleRibbonBookmark(
        ribbonIndex: 1,
        bookNumber: 1,
        chapter: 1,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleChapterView(
              book: genesisBook,
              chapter: 1,
              primaryTranslation: 'CPDV',
              compareTranslation: 'none',
              bookmarks: const [matchingBookmark],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify BiblePageRibbonsWidget is rendered
      expect(find.byType(BiblePageRibbonsWidget), findsOneWidget);

      // Verify BiblePageRibbon is rendered for the matching ribbon
      expect(find.byType(BiblePageRibbon), findsOneWidget);
      expect(find.byKey(const Key('bible_page_ribbon_1')), findsOneWidget);
    });

    testWidgets(
      'Ribbon Bookmark does not render ribbon when chapter does not match',
      (WidgetTester tester) async {
        const differentBookmark = BibleRibbonBookmark(
          ribbonIndex: 2,
          bookNumber: 1,
          chapter: 2,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
                bookmarks: const [differentBookmark],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BiblePageRibbonsWidget), findsOneWidget);
        expect(find.byType(BiblePageRibbon), findsNothing);
      },
    );

    testWidgets(
      'Keep-Alive Client State mixes in AutomaticKeepAliveClientMixin and wantKeepAlive is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state(find.byType(BibleChapterView));
        expect(state, isA<AutomaticKeepAliveClientMixin>());
        expect((state as dynamic).wantKeepAlive, isTrue);
      },
    );
  });

  group('Group 6: Error and Loading States', () {
    testWidgets(
      'Loading Spinner displays while data loading futures are pending',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
              ),
            ),
          ),
        );

        // Verify CircularProgressIndicator is displayed while data loading is pending
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        // Verify CircularProgressIndicator is dismissed and verses are loaded
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Genesis 1'), findsOneWidget);
      },
    );

    testWidgets(
      'Database Query Failure displays error message without crashing',
      (WidgetTester tester) async {
        // Close database to force an asynchronous exception during query
        await testDb.close();

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleChapterView(
                book: genesisBook,
                chapter: 1,
                primaryTranslation: 'CPDV',
                compareTranslation: 'none',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify that an error message ("Error loading Bible: ...") is displayed in the center of the screen
        expect(find.textContaining('Error loading Bible:'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
