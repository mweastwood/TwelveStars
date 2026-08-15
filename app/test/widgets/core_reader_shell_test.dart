import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        ReaderTocEntry(index: 1, title: 'Chapter 1'),
        ReaderTocEntry(index: 2, title: 'Chapter 2'),
        ReaderTocEntry(index: 3, title: 'Chapter 3'),
      ],
    );
  }

  @override
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  }) async {
    return ReaderSection(
      sectionIndex: sectionIndex,
      title: 'Chapter $sectionIndex',
      nodes: [
        ReaderContentNode(
          id: '${sectionIndex}_1',
          nodeType: ReaderNodeType.verse,
          primaryText: 'Primary verse content for chapter $sectionIndex.',
          secondaryText: compareVariant != null && compareVariant != 'none'
              ? 'Secondary verse content for chapter $sectionIndex.'
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
        int selectedSection = 0;
        const entries = [
          ReaderTocEntry(index: 1, title: 'Genesis 1'),
          ReaderTocEntry(index: 2, title: 'Genesis 2'),
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
                      currentSectionIndex: 1,
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

        expect(selectedSection, equals(2));
      },
    );

    testWidgets('CoreReaderShell renders document pages and header controls', (
      tester,
    ) async {
      final mockAdapter = MockReaderAdapter();

      await tester.pumpWidget(
        MaterialApp(
          home: CoreReaderShell(adapter: mockAdapter, initialSectionIndex: 1),
        ),
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
  });
}
