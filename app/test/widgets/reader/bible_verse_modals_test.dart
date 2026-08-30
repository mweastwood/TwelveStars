import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    LibraryHelper.clearCache();
  });

  tearDown(() async {
    LibraryHelper.clearCache();
    await testDb.close();
  });

  Widget buildTestScaffold({required WidgetBuilder builder}) {
    return MaterialApp(
      home: Scaffold(body: Builder(builder: builder)),
    );
  }

  group('showReverseCitationsModal Tests', () {
    testWidgets(
      'renders modal header, citation badge, author, question number, and snippet',
      (WidgetTester tester) async {
        const citation = ReverseCitation(
          sourceBookId: 'baltimore_catechism',
          sourceAssetPath: 'assets/catechism/json/baltimore_1.json',
          sourceBookTitle: 'Baltimore Catechism No. 1',
          sourceAuthor: 'Third Plenary Council',
          sectionId: 'lesson_01',
          sectionTitle: 'On the End of Man',
          questionNumber: 42,
          itemIndex: 1,
          snippet: 'God made us to show His goodness and to make us happy.',
          citation: BibleCitation(
            rawMatch: 'John 17:3',
            displayLabel: 'John 17:3',
            bookNumber: 43,
            bookName: 'John',
            chapter: 17,
            verse: 3,
            abbrev: 'JHN',
          ),
        );

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showReverseCitationsModal(
                context: context,
                title: 'John 17:3',
                citations: [citation],
              ),
              child: const Text('Open Citations Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Citations Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Library References to John 17:3'), findsOneWidget);
        expect(find.text('Baltimore Catechism No. 1'), findsOneWidget);
        expect(find.text('By Third Plenary Council'), findsOneWidget);
        expect(find.text('Q. 42. On the End of Man'), findsOneWidget);
        expect(find.text('John 17:3'), findsOneWidget); // Citation chip
        expect(
          find.text('God made us to show His goodness and to make us happy.'),
          findsOneWidget,
        );
        expect(find.text('Read in Library'), findsOneWidget);
      },
    );

    testWidgets(
      'renders multiple citations without question number or author correctly',
      (WidgetTester tester) async {
        const citation1 = ReverseCitation(
          sourceBookId: 'council_of_trent',
          sourceAssetPath: 'assets/catechism/json/council_of_trent.json',
          sourceBookTitle: 'Catechism of the Council of Trent',
          sourceAuthor: 'St. Pius V',
          sectionId: 'sec_faith',
          sectionTitle: 'Article I: Faith in God',
          questionNumber: null,
          itemIndex: 0,
          snippet: 'Without faith it is impossible to please God.',
          citation: BibleCitation(
            rawMatch: 'Heb 11:6',
            displayLabel: 'Hebrews 11:6',
            bookNumber: 58,
            bookName: 'Hebrews',
            chapter: 11,
            verse: 6,
            abbrev: 'HEB',
          ),
        );

        const citation2 = ReverseCitation(
          sourceBookId: 'didache_lightfoot',
          sourceAssetPath: 'assets/catechism/json/didache_lightfoot.json',
          sourceBookTitle: 'The Didache',
          sourceAuthor: '',
          sectionId: 'didache_ch1',
          sectionTitle: 'The Two Ways',
          questionNumber: null,
          itemIndex: 0,
          snippet: 'There are two ways, one of life and one of death.',
          citation: BibleCitation(
            rawMatch: 'Matt 7:13',
            displayLabel: 'Matthew 7:13',
            bookNumber: 40,
            bookName: 'Matthew',
            chapter: 7,
            verse: 13,
            abbrev: 'MAT',
          ),
        );

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showReverseCitationsModal(
                context: context,
                title: 'Passage References',
                citations: [citation1, citation2],
              ),
              child: const Text('Open Citations Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Citations Modal'));
        await tester.pumpAndSettle();

        expect(
          find.text('Library References to Passage References'),
          findsOneWidget,
        );
        expect(find.text('Catechism of the Council of Trent'), findsOneWidget);
        expect(find.text('By St. Pius V'), findsOneWidget);
        expect(find.text('Article I: Faith in God'), findsOneWidget);
        expect(
          find.text('Without faith it is impossible to please God.'),
          findsOneWidget,
        );

        expect(find.text('The Didache'), findsOneWidget);
        expect(find.text('The Two Ways'), findsOneWidget);
        expect(
          find.text('There are two ways, one of life and one of death.'),
          findsOneWidget,
        );
        expect(find.text('Read in Library'), findsNWidgets(2));
      },
    );

    testWidgets(
      'tapping Read in Library navigates to LibraryReaderScreen with series volume details',
      (WidgetTester tester) async {
        const citation = ReverseCitation(
          sourceBookId: 'baltimore_catechism',
          sourceAssetPath: 'assets/catechism/json/baltimore_1.json',
          sourceBookTitle: 'Baltimore Catechism No. 1',
          sectionId: 'lesson_01',
          sectionTitle: 'On the End of Man',
          questionNumber: 1,
          itemIndex: 2,
          snippet: 'Who made the world?',
          citation: BibleCitation(
            rawMatch: 'Gen 1:1',
            displayLabel: 'Genesis 1:1',
            bookNumber: 1,
            bookName: 'Genesis',
            chapter: 1,
            verse: 1,
            abbrev: 'GEN',
          ),
        );

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showReverseCitationsModal(
                context: context,
                title: 'Genesis 1:1',
                citations: [citation],
              ),
              child: const Text('Open Citations Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Citations Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Read in Library'), findsOneWidget);
        await tester.tap(find.text('Read in Library'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final readerFinder = find.byType(LibraryReaderScreen);
        expect(readerFinder, findsOneWidget);
        final readerWidget = tester.widget<LibraryReaderScreen>(readerFinder);
        expect(readerWidget.bookItem.id, equals('baltimore_catechism'));
        expect(
          readerWidget.initialAssetPath,
          equals('assets/catechism/json/baltimore_1.json'),
        );
        expect(readerWidget.initialVolumeKey, equals('no1'));
        expect(readerWidget.initialSectionId, equals('lesson_01'));
        expect(readerWidget.initialQuestionNumber, equals(1));
        expect(readerWidget.initialItemIndex, equals(2));
      },
    );

    testWidgets(
      'tapping Read in Library navigates to LibraryReaderScreen for non-series book',
      (WidgetTester tester) async {
        const citation = ReverseCitation(
          sourceBookId: 'council_of_trent',
          sourceAssetPath: 'assets/catechism/json/council_of_trent.json',
          sourceBookTitle: 'Catechism of the Council of Trent',
          sectionId: 'sec_faith',
          sectionTitle: 'Article I',
          itemIndex: 0,
          snippet: 'Snippet',
          citation: BibleCitation(
            rawMatch: 'Heb 11:6',
            displayLabel: 'Hebrews 11:6',
            bookNumber: 58,
            bookName: 'Hebrews',
            chapter: 11,
            verse: 6,
            abbrev: 'HEB',
          ),
        );

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showReverseCitationsModal(
                context: context,
                title: 'Hebrews 11:6',
                citations: [citation],
              ),
              child: const Text('Open Citations Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Citations Modal'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Read in Library'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final readerFinder = find.byType(LibraryReaderScreen);
        expect(readerFinder, findsOneWidget);
        final readerWidget = tester.widget<LibraryReaderScreen>(readerFinder);
        expect(readerWidget.bookItem.id, equals('council_of_trent'));
        expect(
          readerWidget.initialAssetPath,
          equals('assets/catechism/json/council_of_trent.json'),
        );
        expect(readerWidget.initialVolumeKey, isNull);
        expect(readerWidget.initialSectionId, equals('sec_faith'));
      },
    );

    testWidgets('tapping backdrop dismisses reverse citations bottom sheet', (
      WidgetTester tester,
    ) async {
      const citation = ReverseCitation(
        sourceBookId: 'council_of_trent',
        sourceAssetPath: 'assets/catechism/json/council_of_trent.json',
        sourceBookTitle: 'Council of Trent',
        sectionId: 'sec_1',
        sectionTitle: 'Faith',
        snippet: 'Preview',
        citation: BibleCitation(
          rawMatch: 'Rom 1:1',
          displayLabel: 'Romans 1:1',
          bookNumber: 45,
          bookName: 'Romans',
          chapter: 1,
          verse: 1,
          abbrev: 'ROM',
        ),
      );

      await tester.pumpWidget(
        buildTestScaffold(
          builder: (context) => ElevatedButton(
            onPressed: () => showReverseCitationsModal(
              context: context,
              title: 'Romans 1:1',
              citations: [citation],
            ),
            child: const Text('Open Citations Modal'),
          ),
        ),
      );

      await tester.tap(find.text('Open Citations Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Library References to Romans 1:1'), findsOneWidget);

      // Tap outside the sheet to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Library References to Romans 1:1'), findsNothing);
    });
  });

  group('showVerseCommentsModal Tests', () {
    testWidgets('renders empty state when comments list is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestScaffold(
          builder: (context) => ElevatedButton(
            onPressed: () => showVerseCommentsModal(
              context: context,
              title: 'Matthew 5:3',
              nodeId: 'mat_5_3',
              textPreview: 'Blessed are the poor in spirit.',
              comments: [],
              onCommentsChanged: () {},
              onAddComment: () {},
            ),
            child: const Text('Open Comments Modal'),
          ),
        ),
      );

      await tester.tap(find.text('Open Comments Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Comments for Matthew 5:3'), findsOneWidget);
      expect(find.text('Blessed are the poor in spirit.'), findsOneWidget);
      expect(find.text('No comments yet.'), findsOneWidget);
      expect(find.text('Add Another Comment'), findsOneWidget);
    });

    testWidgets(
      'renders comments list with formatted date, text, edit and delete buttons',
      (WidgetTester tester) async {
        final comment = UserComment(
          id: 1,
          documentId: 'bible_cpdv',
          sectionIndex: 40,
          nodeId: 'mat_5_3',
          commentText: 'Spiritual poverty leads to the kingdom.',
          textPreview: 'Blessed are the poor in spirit.',
          createdAt: DateTime(2026, 8, 30, 14, 5),
        );

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseCommentsModal(
                context: context,
                title: 'Matthew 5:3',
                nodeId: 'mat_5_3',
                textPreview: 'Blessed are the poor in spirit.',
                comments: [comment],
                onCommentsChanged: () {},
                onAddComment: () {},
              ),
              child: const Text('Open Comments Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Comments Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Comments for Matthew 5:3'), findsOneWidget);
        expect(
          find.text('Spiritual poverty leads to the kingdom.'),
          findsOneWidget,
        );
        expect(find.text('2026-08-30 14:05'), findsOneWidget);
        expect(find.byTooltip('Edit comment'), findsOneWidget);
        expect(find.byTooltip('Delete comment'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Add Another Comment pops bottom sheet and triggers onAddComment callback',
      (WidgetTester tester) async {
        bool addCommentCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseCommentsModal(
                context: context,
                title: 'Matthew 5:3',
                nodeId: 'mat_5_3',
                textPreview: 'Blessed are the poor in spirit.',
                comments: [],
                onCommentsChanged: () {},
                onAddComment: () {
                  addCommentCalled = true;
                },
              ),
              child: const Text('Open Comments Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Comments Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Add Another Comment'), findsOneWidget);
        await tester.tap(find.text('Add Another Comment'));
        await tester.pumpAndSettle();

        expect(addCommentCalled, isTrue);
        expect(find.text('Comments for Matthew 5:3'), findsNothing);
      },
    );

    testWidgets(
      'tapping edit icon opens edit dialog, updates comment in state and invokes onCommentsChanged',
      (WidgetTester tester) async {
        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'bible_cpdv',
            sectionIndex: 40,
            nodeId: 'mat_5_3',
            commentText: 'Initial commentary.',
            textPreview: const Value('Blessed are the poor in spirit.'),
            createdAt: DateTime(2026, 8, 30, 10, 0),
          ),
        );

        final initialDbComments = await testDb.getComments(nodeId: 'mat_5_3');
        expect(initialDbComments.length, equals(1));
        final mutableComments = List<UserComment>.from(initialDbComments);

        bool commentsChangedCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseCommentsModal(
                context: context,
                title: 'Matthew 5:3',
                nodeId: 'mat_5_3',
                textPreview: 'Blessed are the poor in spirit.',
                comments: mutableComments,
                onCommentsChanged: () {
                  commentsChangedCalled = true;
                },
                onAddComment: () {},
              ),
              child: const Text('Open Comments Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Comments Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Initial commentary.'), findsOneWidget);

        // Tap Edit comment
        await tester.tap(find.byTooltip('Edit comment'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Comment for Matthew 5:3'), findsOneWidget);
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        await tester.enterText(textFieldFinder, 'Updated commentary.');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(commentsChangedCalled, isTrue);
        expect(find.text('Updated commentary.'), findsOneWidget);
        expect(find.text('Initial commentary.'), findsNothing);

        final updatedDbComments = await testDb.getComments(nodeId: 'mat_5_3');
        expect(
          updatedDbComments.first.commentText,
          equals('Updated commentary.'),
        );
      },
    );

    testWidgets(
      'tapping delete icon deletes comment from DB, updates state, and invokes onCommentsChanged',
      (WidgetTester tester) async {
        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'bible_cpdv',
            sectionIndex: 40,
            nodeId: 'mat_5_3',
            commentText: 'Comment to delete.',
            textPreview: const Value('Blessed are the poor in spirit.'),
            createdAt: DateTime(2026, 8, 30, 10, 0),
          ),
        );

        final dbComments = await testDb.getComments(nodeId: 'mat_5_3');
        expect(dbComments.length, equals(1));
        final mutableComments = List<UserComment>.from(dbComments);

        bool commentsChangedCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseCommentsModal(
                context: context,
                title: 'Matthew 5:3',
                nodeId: 'mat_5_3',
                textPreview: 'Blessed are the poor in spirit.',
                comments: mutableComments,
                onCommentsChanged: () {
                  commentsChangedCalled = true;
                },
                onAddComment: () {},
              ),
              child: const Text('Open Comments Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Comments Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Comment to delete.'), findsOneWidget);

        // Tap Delete comment
        await tester.tap(find.byTooltip('Delete comment'));
        await tester.pumpAndSettle();

        expect(commentsChangedCalled, isTrue);
        expect(find.text('Comment to delete.'), findsNothing);
        expect(find.text('No comments yet.'), findsOneWidget);

        final remainingDbComments = await testDb.getComments(nodeId: 'mat_5_3');
        expect(remainingDbComments, isEmpty);
      },
    );
  });

  group('showAddCommentDialog Tests', () {
    testWidgets(
      'renders dialog with citation title, quoted preview, hint text, Cancel and Save buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddCommentDialog(
                context: context,
                citation: 'Luke 1:28',
                textPreview: 'Hail, full of grace, the Lord is with thee.',
                documentId: 'bible_cpdv',
                sectionIndex: 42,
                nodeId: 'luk_1_28',
              ),
              child: const Text('Open Add Dialog'),
            ),
          ),
        );

        await tester.tap(find.text('Open Add Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Add Comment for Luke 1:28'), findsOneWidget);
        expect(
          find.text('"Hail, full of grace, the Lord is with thee."'),
          findsOneWidget,
        );
        expect(find.text('Enter your comment...'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );

    testWidgets(
      'entering text and tapping Save inserts comment to DB, shows SnackBar, and invokes onCommentSaved',
      (WidgetTester tester) async {
        bool commentSavedCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddCommentDialog(
                context: context,
                citation: 'Luke 1:28',
                textPreview: 'Hail, full of grace, the Lord is with thee.',
                documentId: 'bible_cpdv',
                sectionIndex: 42,
                nodeId: 'luk_1_28',
                onCommentSaved: () {
                  commentSavedCalled = true;
                },
              ),
              child: const Text('Open Add Dialog'),
            ),
          ),
        );

        await tester.tap(find.text('Open Add Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'The angelic salutation.',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(commentSavedCalled, isTrue);
        expect(find.text('Saved comment for Luke 1:28'), findsOneWidget);

        final dbComments = await testDb.getComments(nodeId: 'luk_1_28');
        expect(dbComments.length, equals(1));
        expect(dbComments.first.commentText, equals('The angelic salutation.'));
        expect(
          dbComments.first.textPreview,
          equals('Hail, full of grace, the Lord is with thee.'),
        );
        expect(dbComments.first.documentId, equals('bible_cpdv'));
        expect(dbComments.first.sectionIndex, equals(42));
      },
    );

    testWidgets(
      'tapping Cancel dismisses dialog without saving to DB or invoking onCommentSaved',
      (WidgetTester tester) async {
        bool commentSavedCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddCommentDialog(
                context: context,
                citation: 'Luke 1:28',
                textPreview: 'Hail, full of grace.',
                documentId: 'bible_cpdv',
                sectionIndex: 42,
                nodeId: 'luk_1_28',
                onCommentSaved: () {
                  commentSavedCalled = true;
                },
              ),
              child: const Text('Open Add Dialog'),
            ),
          ),
        );

        await tester.tap(find.text('Open Add Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Draft note');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(commentSavedCalled, isFalse);
        final dbComments = await testDb.getComments(nodeId: 'luk_1_28');
        expect(dbComments, isEmpty);
        expect(find.text('Add Comment for Luke 1:28'), findsNothing);
      },
    );

    testWidgets(
      'tapping Save with empty text dismisses dialog without saving or invoking callback',
      (WidgetTester tester) async {
        bool commentSavedCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddCommentDialog(
                context: context,
                citation: 'Luke 1:28',
                textPreview: 'Hail, full of grace.',
                documentId: 'bible_cpdv',
                sectionIndex: 42,
                nodeId: 'luk_1_28',
                onCommentSaved: () {
                  commentSavedCalled = true;
                },
              ),
              child: const Text('Open Add Dialog'),
            ),
          ),
        );

        await tester.tap(find.text('Open Add Dialog'));
        await tester.pumpAndSettle();

        // Save with empty/spaces text
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(commentSavedCalled, isFalse);
        final dbComments = await testDb.getComments(nodeId: 'luk_1_28');
        expect(dbComments, isEmpty);
      },
    );
  });

  group('showEditCommentDialog Tests', () {
    testWidgets('renders dialog pre-filled with initialText and textPreview', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestScaffold(
          builder: (context) => ElevatedButton(
            onPressed: () => showEditCommentDialog(
              context: context,
              citation: 'Romans 8:28',
              textPreview: 'All things work together for good.',
              commentId: 1,
              initialText: 'God provides in all circumstances.',
            ),
            child: const Text('Open Edit Dialog'),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Dialog'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Edit Comment for Romans 8:28'), findsOneWidget);
      expect(find.text('"All things work together for good."'), findsOneWidget);
      expect(find.text('God provides in all circumstances.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets(
      'modifying text and tapping Save updates DB, shows SnackBar, and invokes onCommentUpdated',
      (WidgetTester tester) async {
        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'bible_cpdv',
            sectionIndex: 45,
            nodeId: 'rom_8_28',
            commentText: 'Old reflection.',
            createdAt: DateTime(2026, 8, 30, 10, 0),
          ),
        );

        final initialDbComments = await testDb.getComments(nodeId: 'rom_8_28');
        final commentId = initialDbComments.first.id;

        String? updatedTextReceived;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showEditCommentDialog(
                context: context,
                citation: 'Romans 8:28',
                textPreview: 'All things work together for good.',
                commentId: commentId,
                initialText: 'Old reflection.',
                onCommentUpdated: (newText) {
                  updatedTextReceived = newText;
                },
              ),
              child: const Text('Open Edit Dialog'),
            ),
          ),
        );

        await tester.tap(find.text('Open Edit Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'Refined reflection on Romans 8:28.',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(
          updatedTextReceived,
          equals('Refined reflection on Romans 8:28.'),
        );
        expect(find.text('Updated comment for Romans 8:28'), findsOneWidget);

        final updatedDbComments = await testDb.getComments(nodeId: 'rom_8_28');
        expect(
          updatedDbComments.first.commentText,
          equals('Refined reflection on Romans 8:28.'),
        );
      },
    );

    testWidgets(
      'tapping Cancel dismisses dialog without updating DB or calling onCommentUpdated',
      (WidgetTester tester) async {
        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'bible_cpdv',
            sectionIndex: 45,
            nodeId: 'rom_8_28',
            commentText: 'Original text.',
            createdAt: DateTime(2026, 8, 30, 10, 0),
          ),
        );

        final initialDbComments = await testDb.getComments(nodeId: 'rom_8_28');
        final commentId = initialDbComments.first.id;

        String? updatedTextReceived;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showEditCommentDialog(
                context: context,
                citation: 'Romans 8:28',
                textPreview: 'All things work together for good.',
                commentId: commentId,
                initialText: 'Original text.',
                onCommentUpdated: (newText) {
                  updatedTextReceived = newText;
                },
              ),
              child: const Text('Open Edit Dialog'),
            ),
          ),
        );

        await tester.tap(find.text('Open Edit Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Modified draft');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(updatedTextReceived, isNull);
        final checkDbComments = await testDb.getComments(nodeId: 'rom_8_28');
        expect(checkDbComments.first.commentText, equals('Original text.'));
      },
    );

    testWidgets(
      'handles empty textPreview without rendering quotation preview',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showEditCommentDialog(
                context: context,
                citation: 'Romans 8:28',
                textPreview: '',
                commentId: 1,
                initialText: 'Comment without quote preview.',
              ),
              child: const Text('Open Edit Dialog'),
            ),
          ),
        );

        await tester.tap(find.text('Open Edit Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Comment for Romans 8:28'), findsOneWidget);
        expect(find.text('""'), findsNothing);
      },
    );
  });

  group('showVerseFavoritesModal Tests', () {
    testWidgets('renders empty state when favorites list is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestScaffold(
          builder: (context) => ElevatedButton(
            onPressed: () => showVerseFavoritesModal(
              context: context,
              title: 'Genesis 1:1',
              favorites: [],
              onFavoritesChanged: () {},
            ),
            child: const Text('Open Favorites Modal'),
          ),
        ),
      );

      await tester.tap(find.text('Open Favorites Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Favorite Passage for Genesis 1:1'), findsOneWidget);
      expect(find.text('No favorite passages found.'), findsOneWidget);
    });

    testWidgets(
      'renders single favorite with singular title and single verse citation',
      (WidgetTester tester) async {
        const fav = FavoritePassage(
          id: 1,
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          textPreview: 'In the beginning God created heaven, and earth.',
        );

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseFavoritesModal(
                context: context,
                title: 'Genesis 1:1',
                favorites: [fav],
                onFavoritesChanged: () {},
              ),
              child: const Text('Open Favorites Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Favorites Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Favorite Passage for Genesis 1:1'), findsOneWidget);
        expect(find.text('Genesis 1:1'), findsOneWidget);
        expect(
          find.text('In the beginning God created heaven, and earth.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );

    testWidgets(
      'renders multiple favorites with plural title and verse range citation',
      (WidgetTester tester) async {
        const fav1 = FavoritePassage(
          id: 1,
          bookNumber: 43,
          bookName: 'John',
          chapter: 1,
          startVerse: 1,
          endVerse: 5,
          textPreview: 'In the beginning was the Word...',
        );
        const fav2 = FavoritePassage(
          id: 2,
          bookNumber: 43,
          bookName: 'John',
          chapter: 1,
          startVerse: 14,
          endVerse: 14,
          textPreview: 'And the Word was made flesh...',
        );

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseFavoritesModal(
                context: context,
                title: 'John 1',
                favorites: [fav1, fav2],
                onFavoritesChanged: () {},
              ),
              child: const Text('Open Favorites Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Favorites Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Favorite Passages for John 1'), findsOneWidget);
        expect(find.text('John 1:1-5'), findsOneWidget);
        expect(find.text('In the beginning was the Word...'), findsOneWidget);
        expect(find.text('John 1:14'), findsOneWidget);
        expect(find.text('And the Word was made flesh...'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
      },
    );

    testWidgets(
      'deleting favorite removes from DB, mutates list, calls onFavoritesChanged, and auto-closes when list becomes empty',
      (WidgetTester tester) async {
        await testDb.saveFavorite(
          FavoritePassagesCompanion.insert(
            bookNumber: 43,
            bookName: 'John',
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            textPreview: 'In the beginning was the Word.',
          ),
        );

        final initialFavs = await testDb.getFavoritesForChapter(43, 1);
        expect(initialFavs.length, equals(1));
        final mutableFavs = List<FavoritePassage>.from(initialFavs);

        bool favoritesChangedCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseFavoritesModal(
                context: context,
                title: 'John 1:1',
                favorites: mutableFavs,
                onFavoritesChanged: () {
                  favoritesChangedCalled = true;
                },
              ),
              child: const Text('Open Favorites Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Favorites Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Favorite Passage for John 1:1'), findsOneWidget);

        // Tap Delete favorite
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(favoritesChangedCalled, isTrue);
        expect(mutableFavs, isEmpty);

        // Modal should auto-close
        expect(find.text('Favorite Passage for John 1:1'), findsNothing);

        final remainingFavs = await testDb.getFavoritesForChapter(43, 1);
        expect(remainingFavs, isEmpty);
      },
    );

    testWidgets(
      'deleting one of multiple favorites removes only that favorite and leaves modal open',
      (WidgetTester tester) async {
        await testDb.saveFavorite(
          FavoritePassagesCompanion.insert(
            bookNumber: 43,
            bookName: 'John',
            chapter: 1,
            startVerse: 1,
            endVerse: 5,
            textPreview: 'In the beginning was the Word...',
          ),
        );
        await testDb.saveFavorite(
          FavoritePassagesCompanion.insert(
            bookNumber: 43,
            bookName: 'John',
            chapter: 1,
            startVerse: 14,
            endVerse: 14,
            textPreview: 'And the Word was made flesh...',
          ),
        );

        final allFavorites = await testDb.getFavorites();
        expect(allFavorites.length, equals(2));
        final mutableFavs = List<FavoritePassage>.from(allFavorites);

        bool favoritesChangedCalled = false;

        await tester.pumpWidget(
          buildTestScaffold(
            builder: (context) => ElevatedButton(
              onPressed: () => showVerseFavoritesModal(
                context: context,
                title: 'John 1',
                favorites: mutableFavs,
                onFavoritesChanged: () {
                  favoritesChangedCalled = true;
                },
              ),
              child: const Text('Open Favorites Modal'),
            ),
          ),
        );

        await tester.tap(find.text('Open Favorites Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Favorite Passages for John 1'), findsOneWidget);
        expect(find.text('John 1:1-5'), findsOneWidget);
        expect(find.text('John 1:14'), findsOneWidget);

        // Delete the first favorite (John 1:1-5)
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();

        expect(favoritesChangedCalled, isTrue);
        expect(mutableFavs.length, equals(1));
        expect(find.text('John 1:1-5'), findsNothing);
        expect(find.text('John 1:14'), findsOneWidget);
        // Modal is still open with single favorite title
        expect(find.text('Favorite Passage for John 1'), findsOneWidget);

        final remainingFavs = await testDb.getFavorites();
        expect(remainingFavs.length, equals(1));
        expect(remainingFavs.first.startVerse, equals(14));
      },
    );
  });
}
