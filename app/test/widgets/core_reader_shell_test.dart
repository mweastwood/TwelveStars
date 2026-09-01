import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/widgets/reader/core_reader_shell.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
import 'package:twelve_stars/widgets/reader/reader_text_options_sheet.dart';
import 'package:twelve_stars/widgets/reader/reader_toc_bottom_sheet.dart';

class MockReaderAdapter implements ReaderAdapter {
  @override
  Future<ReaderDocument> loadDocument() async {
    return const ReaderDocument(
      documentId: 'mock_doc',
      title: 'Mock Book Title',
      subtitle: 'Mock Subtitle',
      author: 'Mock Author',
      sectionsCount: 3,
      tocEntries: [
        ReaderTocEntry(index: 0, title: 'Chapter 1'),
        ReaderTocEntry(index: 1, title: 'Chapter 2'),
        ReaderTocEntry(index: 2, title: 'Chapter 3'),
      ],
    );
  }

  @override
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  }) async {
    final displayIndex = sectionIndex + 1;
    return ReaderSection(
      sectionIndex: sectionIndex,
      title: 'Chapter $displayIndex',
      nodes: [
        ReaderContentNode(
          id: '${sectionIndex}_1',
          nodeType: ReaderNodeType.verse,
          primaryText: 'Primary verse content for chapter $displayIndex.',
          secondaryText: compareVariant != null && compareVariant != 'none'
              ? 'Secondary verse content for chapter $displayIndex.'
              : null,
          questionNumber: '1',
        ),
      ],
    );
  }

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {}

  @override
  Future<List<ReaderBookmark>> loadBookmarks() async {
    return [];
  }

  @override
  Future<void> saveComment(ReaderComment comment) async {}

  @override
  Future<List<ReaderComment>> loadComments({String? nodeId}) async {
    return [];
  }

  @override
  Future<void> updateComment(String commentId, String updatedText) async {}

  @override
  Future<void> deleteComment(String commentId) async {}
}

void main() {
  group('Phase 2 Reader UI Shell & Components Tests', () {
    testWidgets(
      'ReaderTextOptionsSheet displays font size slider and triggers callback',
      (tester) async {
        double currentSize = 16.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ReaderTextOptionsSheet.show(
                      context,
                      fontSize: currentSize,
                      onFontSizeChanged: (val) {
                        currentSize = val;
                      },
                    );
                  },
                  child: const Text('Open Options'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Options'));
        await tester.pumpAndSettle();

        expect(find.text('Reading Options'), findsOneWidget);
        expect(find.textContaining('Font Size: 16 pt'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);

        await tester.drag(find.byType(Slider), const Offset(50, 0));
        await tester.pumpAndSettle();

        expect(currentSize, isNot(equals(16.0)));
      },
    );

    testWidgets(
      'ReaderSelectionActionBar displays selected citation, correct button order, and triggers callbacks',
      (tester) async {
        bool saved = false;
        bool commentAdded = false;
        bool copied = false;
        bool cleared = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ReaderSelectionActionBar(
                      title: 'Genesis 1:1',
                      selectedCount: 1,
                      onSaveFavorite: () => saved = true,
                      onAddComment: () => commentAdded = true,
                      onCopy: () => copied = true,
                      onClearSelection: () => cleared = true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Genesis 1:1'), findsOneWidget);
        expect(find.text('1 item selected'), findsOneWidget);

        // Verify button order: Save (star) -> Comment (comment_outlined) -> Copy (copy) -> Close (close)
        final starX = tester.getCenter(find.byIcon(Icons.star)).dx;
        final commentX = tester
            .getCenter(find.byIcon(Icons.comment_outlined))
            .dx;
        final copyX = tester.getCenter(find.byIcon(Icons.copy)).dx;
        final closeX = tester.getCenter(find.byIcon(Icons.close)).dx;

        expect(starX, lessThan(commentX));
        expect(commentX, lessThan(copyX));
        expect(copyX, lessThan(closeX));

        await tester.tap(find.byIcon(Icons.star));
        await tester.pump();
        expect(saved, isTrue);

        await tester.tap(find.byIcon(Icons.comment_outlined));
        await tester.pump();
        expect(commentAdded, isTrue);

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        expect(copied, isTrue);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        expect(cleared, isTrue);
      },
    );

    testWidgets(
      'ReaderTocBottomSheet displays section list and selects chapter',
      (tester) async {
        int selectedSection = -1;
        const entries = [
          ReaderTocEntry(index: 0, title: 'Genesis 1'),
          ReaderTocEntry(index: 1, title: 'Genesis 2'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ReaderTocBottomSheet.show(
                      context,
                      documentTitle: 'Genesis',
                      tocEntries: entries,
                      currentSectionIndex: 0,
                      onSectionSelected: (idx) => selectedSection = idx,
                    );
                  },
                  child: const Text('Open TOC'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open TOC'));
        await tester.pumpAndSettle();

        expect(find.text('Table of Contents'), findsOneWidget);
        expect(find.text('Genesis 1'), findsOneWidget);
        expect(find.text('Genesis 2'), findsOneWidget);

        await tester.tap(find.text('Genesis 2'));
        await tester.pumpAndSettle();

        expect(selectedSection, equals(1));
      },
    );

    testWidgets('CoreReaderShell renders document pages and header controls', (
      tester,
    ) async {
      final mockAdapter = MockReaderAdapter();

      await tester.pumpWidget(
        MaterialApp(home: CoreReaderShell(adapter: mockAdapter)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mock Book Title'), findsOneWidget);
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(
        find.textContaining('Primary verse content for chapter 1.'),
        findsOneWidget,
      );

      // Verify app bar action buttons exist
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
    });

    testWidgets(
      'CoreReaderShell navigates sections via TOC sheet without underflow',
      (tester) async {
        final mockAdapter = MockReaderAdapter();

        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(adapter: mockAdapter, initialSectionIndex: 0),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Chapter 1'), findsOneWidget);

        // Open TOC and jump to Chapter 2 (index 1)
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();

        expect(find.text('Chapter 2'), findsOneWidget);
        await tester.tap(find.text('Chapter 2'));
        await tester.pumpAndSettle();

        expect(find.text('Chapter 2'), findsOneWidget);
        expect(
          find.textContaining('Primary verse content for chapter 2.'),
          findsOneWidget,
        );

        // Open TOC and jump back to Chapter 1 (index 0) - tests 0-index jump without underflow (-1 crash)
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();

        expect(find.text('Chapter 1'), findsWidgets);
        await tester.tap(find.text('Chapter 1').last);
        await tester.pumpAndSettle();

        expect(find.text('Chapter 1'), findsOneWidget);
        expect(
          find.textContaining('Primary verse content for chapter 1.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CoreReaderShell renders single-section document with LibraryReaderAdapter without RangeError',
      (tester) async {
        final db = BibleDatabase(NativeDatabase.memory());
        const singleSectionAsset = 'test_assets/single_section_doc.json';
        const singleItem = LibraryBookItem(
          id: 'single_doc',
          title: 'Single Section Book',
          subtitle: 'The Epistle',
          category: 'Cat',
          author: 'Author',
          description: 'Desc',
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
              final String key = utf8.decode(message!.buffer.asUint8List());
              if (key == singleSectionAsset) {
                const jsonString = '''{
                  "bookId": "single_doc",
                  "title": "Single Section Book",
                  "subtitle": "The Epistle",
                  "author": "Author",
                  "toc": [{"id": "s1", "title": "Opening"}],
                  "sections": [{
                    "id": "s1",
                    "title": "Opening",
                    "subtitle": "",
                    "content": [
                      {"type": "paragraph", "text": "First and only section content."}
                    ]
                  }]
                }''';
                return ByteData.view(
                  Uint8List.fromList(utf8.encode(jsonString)).buffer,
                );
              }
              return null;
            });

        final adapter = LibraryReaderAdapter(
          bookItem: singleItem,
          assetPath: singleSectionAsset,
          dbHelper: db,
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(singleSectionAsset);
        });

        await tester.pumpWidget(
          MaterialApp(home: CoreReaderShell(adapter: adapter)),
        );

        await tester.pumpAndSettle();

        expect(find.text('Single Section Book'), findsOneWidget);
        expect(find.text('Opening'), findsOneWidget);
        expect(find.text('First and only section content.'), findsOneWidget);

        await db.close();
      },
    );

    testWidgets(
      'CoreReaderShell correctly loads first section (index 0) of multi-section LibraryReaderAdapter',
      (tester) async {
        final db = BibleDatabase(NativeDatabase.memory());
        const multiSectionAsset = 'test_assets/multi_section_doc.json';
        const multiItem = LibraryBookItem(
          id: 'multi_doc',
          title: 'Multi Section Book',
          subtitle: 'Catechism',
          category: 'Cat',
          author: 'Author',
          description: 'Desc',
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
              final String key = utf8.decode(message!.buffer.asUint8List());
              if (key == multiSectionAsset) {
                const jsonString = '''{
                  "bookId": "multi_doc",
                  "title": "Multi Section Book",
                  "subtitle": "Catechism",
                  "author": "Author",
                  "toc": [
                    {"id": "s1", "title": "Section 1"},
                    {"id": "s2", "title": "Section 2"}
                  ],
                  "sections": [
                    {
                      "id": "s1",
                      "title": "Section 1",
                      "subtitle": "",
                      "content": [
                        {"type": "paragraph", "text": "Content of Section 1"}
                      ]
                    },
                    {
                      "id": "s2",
                      "title": "Section 2",
                      "subtitle": "",
                      "content": [
                        {"type": "paragraph", "text": "Content of Section 2"}
                      ]
                    }
                  ]
                }''';
                return ByteData.view(
                  Uint8List.fromList(utf8.encode(jsonString)).buffer,
                );
              }
              return null;
            });

        final adapter = LibraryReaderAdapter(
          bookItem: multiItem,
          assetPath: multiSectionAsset,
          dbHelper: db,
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(multiSectionAsset);
        });

        await tester.pumpWidget(
          MaterialApp(home: CoreReaderShell(adapter: adapter)),
        );

        await tester.pumpAndSettle();

        // Verify that Section 1 (index 0) is loaded first, not skipped
        expect(find.text('Multi Section Book'), findsOneWidget);
        expect(find.text('Section 1'), findsOneWidget);
        expect(find.text('Content of Section 1'), findsOneWidget);
        expect(find.text('Section 2'), findsNothing);

        // Open TOC and jump to Section 2 (index 1)
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Section 2'));
        await tester.pumpAndSettle();

        expect(find.text('Section 2'), findsOneWidget);
        expect(find.text('Content of Section 2'), findsOneWidget);

        // Open TOC and jump back to Section 1 (index 0)
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Section 1'));
        await tester.pumpAndSettle();

        expect(find.text('Section 1'), findsOneWidget);
        expect(find.text('Content of Section 1'), findsOneWidget);

        await db.close();
      },
    );
  });
}
