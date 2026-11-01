import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/widgets/library_toc_drawer.dart';
import 'package:twelve_stars/widgets/reader/core_reader_shell.dart';
import 'package:twelve_stars/widgets/reader/library_edition_selector_bar.dart';
import 'package:twelve_stars/widgets/reader/reader_section_navigation_bar.dart';

class _TestReaderAdapter extends ReaderAdapter {
  final int sectionsCount;

  _TestReaderAdapter({this.sectionsCount = 3});

  @override
  Future<ReaderDocument> loadDocument() async {
    return ReaderDocument(
      documentId: 'test_doc',
      title: 'Test Document',
      sectionsCount: sectionsCount,
      tocEntries: List.generate(
        sectionsCount,
        (i) => ReaderTocEntry(index: i, title: 'Section ${i + 1}'),
      ),
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
      title: 'Section ${sectionIndex + 1}',
      nodes: [
        ReaderContentNode(
          id: 'node_${sectionIndex}_0',
          nodeType: ReaderNodeType.paragraph,
          primaryText: 'Body text for section ${sectionIndex + 1}',
        ),
      ],
    );
  }

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {}

  @override
  Future<List<ReaderBookmark>> loadBookmarks() async => const [];
}

void main() {
  group('ReaderSectionNavigationBar', () {
    testWidgets(
      'disables Previous on first section, enables both on middle section, and disables Next on last section',
      (tester) async {
        int prevCalls = 0;
        int nextCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReaderSectionNavigationBar(
                currentIndex: 0,
                totalSections: 3,
                sectionTitle: 'Lesson First',
                onPrevious: () => prevCalls++,
                onNext: () => nextCalls++,
              ),
            ),
          ),
        );

        expect(find.text('Section 1 of 3'), findsOneWidget);
        expect(find.text('Lesson First'), findsOneWidget);

        final prevBtnFirst = tester.widget<IconButton>(
          find.byKey(const Key('prev_section_button')),
        );
        final nextBtnFirst = tester.widget<IconButton>(
          find.byKey(const Key('next_section_button')),
        );
        expect(prevBtnFirst.onPressed, isNull);
        expect(nextBtnFirst.onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('next_section_button')));
        expect(nextCalls, 1);

        // Middle section
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReaderSectionNavigationBar(
                currentIndex: 1,
                totalSections: 3,
                onPrevious: () => prevCalls++,
                onNext: () => nextCalls++,
              ),
            ),
          ),
        );

        expect(find.text('Section 2 of 3'), findsOneWidget);
        final prevBtnMid = tester.widget<IconButton>(
          find.byKey(const Key('prev_section_button')),
        );
        final nextBtnMid = tester.widget<IconButton>(
          find.byKey(const Key('next_section_button')),
        );
        expect(prevBtnMid.onPressed, isNotNull);
        expect(nextBtnMid.onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('prev_section_button')));
        expect(prevCalls, 1);

        // Last section
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReaderSectionNavigationBar(
                currentIndex: 2,
                totalSections: 3,
                onPrevious: () => prevCalls++,
                onNext: () => nextCalls++,
              ),
            ),
          ),
        );

        expect(find.text('Section 3 of 3'), findsOneWidget);
        final nextBtnLast = tester.widget<IconButton>(
          find.byKey(const Key('next_section_button')),
        );
        expect(nextBtnLast.onPressed, isNull);
      },
    );

    testWidgets(
      'CoreReaderShell renders ReaderSectionNavigationBar when sectionsCount > 1 and navigates sections',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(
              adapter: _TestReaderAdapter(sectionsCount: 3),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ReaderSectionNavigationBar), findsOneWidget);
        expect(find.text('Section 1 of 3'), findsOneWidget);
        expect(find.text('Body text for section 1'), findsOneWidget);

        await tester.tap(find.byKey(const Key('next_section_button')));
        await tester.pumpAndSettle();

        expect(find.text('Section 2 of 3'), findsOneWidget);
        expect(find.text('Body text for section 2'), findsOneWidget);

        await tester.tap(find.byKey(const Key('prev_section_button')));
        await tester.pumpAndSettle();

        expect(find.text('Section 1 of 3'), findsOneWidget);
        expect(find.text('Body text for section 1'), findsOneWidget);
      },
    );

    testWidgets(
      'CoreReaderShell omits ReaderSectionNavigationBar when sectionsCount == 1',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(
              adapter: _TestReaderAdapter(sectionsCount: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ReaderSectionNavigationBar), findsNothing);
      },
    );
  });

  group('LibraryEditionSelectorBar', () {
    const volumes = [
      BaltimoreVolume(
        volumeKey: 'baltimore_1',
        name: 'Baltimore Catechism No. 1',
        shortName: 'No. 1',
        description: 'First edition',
        assetPath: 'assets/catechism/json/baltimore_1.json',
      ),
      BaltimoreVolume(
        volumeKey: 'baltimore_2',
        name: 'Baltimore Catechism No. 2',
        shortName: 'No. 2',
        description: 'Second edition',
        assetPath: 'assets/catechism/json/baltimore_2.json',
      ),
    ];

    testWidgets('renders edition chips and invokes onVolumeSelected', (
      tester,
    ) async {
      BaltimoreVolume? selectedVolume;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryEditionSelectorBar(
              volumes: volumes,
              selectedVolumeKey: 'baltimore_1',
              onVolumeSelected: (vol) => selectedVolume = vol,
            ),
          ),
        ),
      );

      expect(find.text('Edition: '), findsOneWidget);
      final chip1 = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('edition_chip_baltimore_1')),
      );
      final chip2 = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('edition_chip_baltimore_2')),
      );
      expect(chip1.selected, isTrue);
      expect(chip2.selected, isFalse);

      await tester.tap(find.byKey(const ValueKey('edition_chip_baltimore_2')));
      await tester.pump();

      expect(selectedVolume?.volumeKey, 'baltimore_2');
    });
  });

  group('LibraryReaderAdapter.buildTocEntries & groupCommentsForSection', () {
    test(
      'buildTocEntries builds entries from sections and matches LibraryTocDrawer.entriesFromBook',
      () {
        final bookData = ParsedBookData(
          bookId: 'test',
          title: 'Test Book',
          subtitle: 'Sub',
          author: 'Author',
          toc: [
            TocEntry(id: 's1', title: 'TOC 1'),
            TocEntry(id: 's2', title: 'TOC 2'),
          ],
          sections: [
            BookSection(
              id: 's1',
              title: 'Lesson 1',
              subtitle: 'On Faith',
              content: [],
            ),
            BookSection(id: 's2', title: 'Lesson 2', subtitle: '', content: []),
          ],
        );

        final entries = LibraryReaderAdapter.buildTocEntries(bookData);
        final drawerEntries = LibraryTocDrawer.entriesFromBook(bookData);

        expect(entries, hasLength(2));
        expect(entries[0].index, 0);
        expect(entries[0].title, 'Lesson 1');
        expect(entries[0].subtitle, 'On Faith');
        expect(entries[1].index, 1);
        expect(entries[1].title, 'Lesson 2');
        expect(entries[1].subtitle, isNull);

        expect(drawerEntries.length, entries.length);
        expect(drawerEntries[0].title, entries[0].title);
        expect(drawerEntries[0].subtitle, entries[0].subtitle);
      },
    );

    test('buildTocEntries falls back to toc when sections list is empty', () {
      final bookData = ParsedBookData(
        bookId: 'toc_only',
        title: 'TOC Only Book',
        subtitle: '',
        author: 'Author',
        toc: [
          TocEntry(id: 'c1', title: 'Chapter 1'),
          TocEntry(id: 'c2', title: 'Chapter 2'),
        ],
        sections: [],
      );

      final entries = LibraryReaderAdapter.buildTocEntries(bookData);
      expect(entries, hasLength(2));
      expect(entries[0].title, 'Chapter 1');
      expect(entries[1].title, 'Chapter 2');
    });

    test(
      'groupCommentsForSection filters by sectionIndex and currentVolumeKey when isSeries is true',
      () {
        final now = DateTime(2026, 1, 1);
        final comments = [
          UserComment(
            id: 1,
            documentId: 'baltimore_catechism',
            sectionIndex: 2,
            nodeId: 'baltimore_1:sec_3:0',
            commentText: 'Vol 1 comment A',
            textPreview: 'Preview A',
            createdAt: now,
          ),
          UserComment(
            id: 2,
            documentId: 'baltimore_catechism',
            sectionIndex: 2,
            nodeId: 'baltimore_1:sec_3:0',
            commentText: 'Vol 1 comment B',
            textPreview: 'Preview B',
            createdAt: now,
          ),
          UserComment(
            id: 3,
            documentId: 'baltimore_catechism',
            sectionIndex: 2,
            nodeId: 'baltimore_2:sec_3:0',
            commentText: 'Vol 2 comment',
            textPreview: 'Preview C',
            createdAt: now,
          ),
          UserComment(
            id: 4,
            documentId: 'baltimore_catechism',
            sectionIndex: 5,
            nodeId: 'baltimore_1:sec_6:1',
            commentText: 'Other section comment',
            textPreview: 'Preview D',
            createdAt: now,
          ),
        ];

        final vol1Grouped = LibraryReaderAdapter.groupCommentsForSection(
          comments,
          2,
          currentVolumeKey: 'baltimore_1',
          isSeries: true,
        );
        expect(vol1Grouped.keys, ['baltimore_1:sec_3:0']);
        expect(vol1Grouped['baltimore_1:sec_3:0'], hasLength(2));

        final vol2Grouped = LibraryReaderAdapter.groupCommentsForSection(
          comments,
          2,
          currentVolumeKey: 'baltimore_2',
          isSeries: true,
        );
        expect(vol2Grouped.keys, ['baltimore_2:sec_3:0']);
        expect(vol2Grouped['baltimore_2:sec_3:0'], hasLength(1));
      },
    );
  });
}
