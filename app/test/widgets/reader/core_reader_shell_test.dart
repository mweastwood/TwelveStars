import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/reader/reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/widgets/reader/core_reader_shell.dart';
import 'package:twelve_stars/widgets/reader/reader_parallel_view.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

class _FakeReaderAdapter extends ReaderAdapter {
  _FakeReaderAdapter({required this.document, required this.sectionBuilder});

  final Future<ReaderDocument> Function() document;
  final Future<ReaderSection> Function(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  })
  sectionBuilder;

  final List<ReaderBookmark> savedBookmarks = [];

  @override
  Future<ReaderDocument> loadDocument() => document();

  @override
  Future<ReaderSection> loadSection(
    int sectionIndex, {
    String? primaryVariant,
    String? compareVariant,
  }) {
    return sectionBuilder(
      sectionIndex,
      primaryVariant: primaryVariant,
      compareVariant: compareVariant,
    );
  }

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    savedBookmarks.add(bookmark);
  }

  @override
  Future<List<ReaderBookmark>> loadBookmarks() async => savedBookmarks;
}

ScrollableState _findVerticalListScrollable(WidgetTester tester) {
  final listFinder = find.descendant(
    of: find.byType(ReaderParallelView),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(listFinder);
}

void main() {
  group('CoreReaderShell', () {
    testWidgets(
      'preserves vertical scroll offset and does not show CircularProgressIndicator on selection or font size changes',
      (tester) async {
        var sectionLoadCount = 0;
        final nodes = List.generate(
          60,
          (i) => ReaderContentNode(
            id: 'node_$i',
            nodeType: ReaderNodeType.verse,
            questionNumber: '${i + 1}',
            primaryText:
                'Verse number ${i + 1} with enough text to occupy vertical space in the reader list view.',
          ),
        );

        final adapter = _FakeReaderAdapter(
          document: () async => const ReaderDocument(
            documentId: 'doc_1',
            title: 'Test Document',
            subtitle: 'Test Subtitle',
            sectionsCount: 3,
            tocEntries: [
              ReaderTocEntry(index: 0, title: 'Section 1'),
              ReaderTocEntry(index: 1, title: 'Section 2'),
              ReaderTocEntry(index: 2, title: 'Section 3'),
            ],
          ),
          sectionBuilder:
              (sectionIndex, {primaryVariant, compareVariant}) async {
                sectionLoadCount++;
                return ReaderSection(
                  sectionIndex: sectionIndex,
                  title: 'Section ${sectionIndex + 1}',
                  nodes: nodes,
                );
              },
        );

        await tester.pumpWidget(
          MaterialApp(home: CoreReaderShell(adapter: adapter)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ReaderParallelView), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(sectionLoadCount, 1);

        final scrollableBefore = _findVerticalListScrollable(tester);
        expect(scrollableBefore.position.pixels, 0.0);

        // Scroll down significantly in the section list
        await tester.drag(
          find.byType(ReaderParallelView),
          const Offset(0, -800),
        );
        await tester.pumpAndSettle();

        final scrolledOffset = _findVerticalListScrollable(
          tester,
        ).position.pixels;
        expect(scrolledOffset, greaterThan(400.0));

        // Find a visible node after scrolling and long-press it to select
        final visibleNodeFinder = find
            .descendant(
              of: find.byType(ReaderParallelView),
              matching: find.byType(InkWell),
            )
            .hitTestable()
            .first;
        await tester.longPress(visibleNodeFinder);

        // Pump a single frame to catch any transient FutureBuilder reset to CircularProgressIndicator
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(ReaderParallelView), findsOneWidget);
        expect(find.byType(ReaderSelectionActionBar), findsOneWidget);
        expect(
          identical(_findVerticalListScrollable(tester), scrollableBefore),
          isTrue,
        );
        expect(
          _findVerticalListScrollable(tester).position.pixels,
          equals(scrolledOffset),
        );

        await tester.pumpAndSettle();
        expect(
          _findVerticalListScrollable(tester).position.pixels,
          equals(scrolledOffset),
        );

        // Tap another visible node to extend the selection
        final secondVisibleNodeFinder = find
            .descendant(
              of: find.byType(ReaderParallelView),
              matching: find.byType(InkWell),
            )
            .hitTestable()
            .at(1);
        await tester.tap(secondVisibleNodeFinder);
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(ReaderParallelView), findsOneWidget);
        expect(
          _findVerticalListScrollable(tester).position.pixels,
          equals(scrolledOffset),
        );

        // Clear selection via the action bar close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(ReaderSelectionActionBar), findsNothing);
        expect(
          _findVerticalListScrollable(tester).position.pixels,
          equals(scrolledOffset),
        );

        // Open Text Options sheet and change font size
        await tester.tap(find.byTooltip('Text Options'));
        await tester.pumpAndSettle();
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);
        await tester.drag(sliderFinder, const Offset(50, 0));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(ReaderParallelView), findsOneWidget);
        expect(
          _findVerticalListScrollable(tester).position.pixels,
          greaterThan(0.0),
        );
        // Section was only loaded once across all setState rebuilds
        expect(sectionLoadCount, 1);
      },
    );

    testWidgets(
      'updating primaryVariant while section load is in flight discards stale section load',
      (tester) async {
        final v1Completer = Completer<ReaderSection>();
        final v2Completer = Completer<ReaderSection>();

        final adapter = _FakeReaderAdapter(
          document: () async => const ReaderDocument(
            documentId: 'doc_1',
            title: 'Variant Race Doc',
            sectionsCount: 1,
            tocEntries: [ReaderTocEntry(index: 0, title: 'Section 1')],
          ),
          sectionBuilder: (sectionIndex, {primaryVariant, compareVariant}) {
            if (primaryVariant == 'V1') {
              return v1Completer.future;
            }
            return v2Completer.future;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(adapter: adapter, primaryVariant: 'V1'),
          ),
        );
        // Pump to finish loadDocument() and start loadSection(0, primaryVariant: 'V1')
        await tester.pump();
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Switch primaryVariant to 'V2' while 'V1' loadSection is still in flight
        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(adapter: adapter, primaryVariant: 'V2'),
          ),
        );
        await tester.pump();

        // Complete the stale 'V1' section load first
        v1Completer.complete(
          const ReaderSection(
            sectionIndex: 0,
            title: 'Section 1 (Stale V1)',
            nodes: [
              ReaderContentNode(
                id: 'n1',
                nodeType: ReaderNodeType.verse,
                primaryText: 'Stale V1 text',
              ),
            ],
          ),
        );
        await tester.pump();

        // Should still be waiting on V2, not showing stale V1
        expect(find.text('Stale V1 text'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Now complete the active 'V2' section load
        v2Completer.complete(
          const ReaderSection(
            sectionIndex: 0,
            title: 'Section 1 (Active V2)',
            nodes: [
              ReaderContentNode(
                id: 'n1',
                nodeType: ReaderNodeType.verse,
                primaryText: 'Fresh V2 text',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fresh V2 text'), findsOneWidget);
        expect(find.text('Stale V1 text'), findsNothing);

        // Trigger a setState (long-press node) to verify _loadedSections was not polluted by V1
        await tester.longPress(find.text('Fresh V2 text'));
        await tester.pump();
        expect(find.text('Fresh V2 text'), findsOneWidget);
        expect(find.text('Stale V1 text'), findsNothing);
      },
    );

    testWidgets(
      'updating adapter clamps _currentSectionIndex and discards stale document loads',
      (tester) async {
        final longAdapter = _FakeReaderAdapter(
          document: () async => const ReaderDocument(
            documentId: 'long_doc',
            title: 'Long Document',
            sectionsCount: 5,
            tocEntries: [
              ReaderTocEntry(index: 0, title: 'Ch 1'),
              ReaderTocEntry(index: 1, title: 'Ch 2'),
              ReaderTocEntry(index: 2, title: 'Ch 3'),
              ReaderTocEntry(index: 3, title: 'Ch 4'),
              ReaderTocEntry(index: 4, title: 'Ch 5'),
            ],
          ),
          sectionBuilder:
              (sectionIndex, {primaryVariant, compareVariant}) async =>
                  ReaderSection(
                    sectionIndex: sectionIndex,
                    title: 'Long Ch ${sectionIndex + 1}',
                    nodes: [
                      ReaderContentNode(
                        id: 'long_${sectionIndex}_1',
                        nodeType: ReaderNodeType.verse,
                        primaryText:
                            'Long content for chapter ${sectionIndex + 1}',
                      ),
                    ],
                  ),
        );

        final shortAdapter = _FakeReaderAdapter(
          document: () async => const ReaderDocument(
            documentId: 'short_doc',
            title: 'Short Document',
            sectionsCount: 2,
            tocEntries: [
              ReaderTocEntry(index: 0, title: 'Part 1'),
              ReaderTocEntry(index: 1, title: 'Part 2'),
            ],
          ),
          sectionBuilder:
              (sectionIndex, {primaryVariant, compareVariant}) async =>
                  ReaderSection(
                    sectionIndex: sectionIndex,
                    title: 'Short Part ${sectionIndex + 1}',
                    nodes: [
                      ReaderContentNode(
                        id: 'short_${sectionIndex}_1',
                        nodeType: ReaderNodeType.verse,
                        primaryText:
                            'Short content for part ${sectionIndex + 1}',
                      ),
                    ],
                  ),
        );

        // Start at section index 4 (5th chapter) of the 5-chapter document
        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(adapter: longAdapter, initialSectionIndex: 4),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Long Document'), findsOneWidget);
        expect(find.text('Long content for chapter 5'), findsOneWidget);

        // Select a node before switching adapters
        await tester.longPress(find.text('Long content for chapter 5'));
        await tester.pump();
        expect(find.byType(ReaderSelectionActionBar), findsOneWidget);

        // Switch to shortAdapter (which only has 2 sections: indices 0 and 1)
        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(
              adapter: shortAdapter,
              initialSectionIndex: 4,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Selection is cleared, document title updated, and section index clamped to 1 (Part 2)
        expect(find.byType(ReaderSelectionActionBar), findsNothing);
        expect(find.text('Short Document'), findsOneWidget);
        expect(find.text('Short content for part 2'), findsOneWidget);
      },
    );

    testWidgets(
      'updating adapter while loadDocument is in flight ignores stale document result',
      (tester) async {
        final staleDocCompleter = Completer<ReaderDocument>();
        final freshDocCompleter = Completer<ReaderDocument>();

        final staleAdapter = _FakeReaderAdapter(
          document: () => staleDocCompleter.future,
          sectionBuilder:
              (sectionIndex, {primaryVariant, compareVariant}) async =>
                  const ReaderSection(
                    sectionIndex: 0,
                    title: 'Stale Section',
                    nodes: [
                      ReaderContentNode(
                        id: 's1',
                        nodeType: ReaderNodeType.verse,
                        primaryText: 'Stale adapter verse',
                      ),
                    ],
                  ),
        );

        final freshAdapter = _FakeReaderAdapter(
          document: () => freshDocCompleter.future,
          sectionBuilder:
              (sectionIndex, {primaryVariant, compareVariant}) async =>
                  const ReaderSection(
                    sectionIndex: 0,
                    title: 'Fresh Section',
                    nodes: [
                      ReaderContentNode(
                        id: 'f1',
                        nodeType: ReaderNodeType.verse,
                        primaryText: 'Fresh adapter verse',
                      ),
                    ],
                  ),
        );

        await tester.pumpWidget(
          MaterialApp(home: CoreReaderShell(adapter: staleAdapter)),
        );
        await tester.pump();
        expect(find.text('Loading...'), findsOneWidget);

        // Update to freshAdapter before staleAdapter.loadDocument completes
        await tester.pumpWidget(
          MaterialApp(home: CoreReaderShell(adapter: freshAdapter)),
        );
        await tester.pump();

        // Complete the stale document first
        staleDocCompleter.complete(
          const ReaderDocument(
            documentId: 'stale',
            title: 'Stale Doc Title',
            sectionsCount: 1,
            tocEntries: [ReaderTocEntry(index: 0, title: 'Stale Ch 1')],
          ),
        );
        await tester.pump();

        // Should still be loading freshAdapter, not showing Stale Doc Title
        expect(find.text('Loading...'), findsOneWidget);
        expect(find.text('Stale Doc Title'), findsNothing);

        // Complete the fresh document
        freshDocCompleter.complete(
          const ReaderDocument(
            documentId: 'fresh',
            title: 'Fresh Doc Title',
            sectionsCount: 1,
            tocEntries: [ReaderTocEntry(index: 0, title: 'Fresh Ch 1')],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fresh Doc Title'), findsOneWidget);
        expect(find.text('Fresh adapter verse'), findsOneWidget);
        expect(find.text('Stale Doc Title'), findsNothing);
      },
    );

    testWidgets(
      'switching primaryVariant after V1 has loaded hides stale V1 data and shows CircularProgressIndicator while V2 loads',
      (tester) async {
        final v2Completer = Completer<ReaderSection>();

        final adapter = _FakeReaderAdapter(
          document: () async => const ReaderDocument(
            documentId: 'doc_1',
            title: 'Post-Load Variant Switch Doc',
            sectionsCount: 1,
            tocEntries: [ReaderTocEntry(index: 0, title: 'Section 1')],
          ),
          sectionBuilder: (sectionIndex, {primaryVariant, compareVariant}) {
            if (primaryVariant == 'V1') {
              return Future.value(
                const ReaderSection(
                  sectionIndex: 0,
                  title: 'Section 1 (V1)',
                  nodes: [
                    ReaderContentNode(
                      id: 'n1',
                      nodeType: ReaderNodeType.verse,
                      primaryText: 'Loaded V1 text',
                    ),
                  ],
                ),
              );
            }
            return v2Completer.future;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(adapter: adapter, primaryVariant: 'V1'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Loaded V1 text'), findsOneWidget);

        // Switch primaryVariant to 'V2' (whose Completer is still pending)
        await tester.pumpWidget(
          MaterialApp(
            home: CoreReaderShell(adapter: adapter, primaryVariant: 'V2'),
          ),
        );
        await tester.pump();

        // Stale V1 text must NOT remain visible while V2 is loading
        expect(find.text('Loaded V1 text'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete V2
        v2Completer.complete(
          const ReaderSection(
            sectionIndex: 0,
            title: 'Section 1 (V2)',
            nodes: [
              ReaderContentNode(
                id: 'n1',
                nodeType: ReaderNodeType.verse,
                primaryText: 'Loaded V2 text',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Loaded V2 text'), findsOneWidget);
        expect(find.text('Loaded V1 text'), findsNothing);
      },
    );

    testWidgets(
      'failed section load is evicted from _sectionFutures and can be retried',
      (tester) async {
        var shouldFail = true;

        final adapter = _FakeReaderAdapter(
          document: () async => const ReaderDocument(
            documentId: 'doc_err',
            title: 'Error Retry Doc',
            sectionsCount: 1,
            tocEntries: [ReaderTocEntry(index: 0, title: 'Section 1')],
          ),
          sectionBuilder:
              (sectionIndex, {primaryVariant, compareVariant}) async {
                if (shouldFail) {
                  throw StateError('Simulated section load failure');
                }
                return const ReaderSection(
                  sectionIndex: 0,
                  title: 'Recovered Section 1',
                  nodes: [
                    ReaderContentNode(
                      id: 'n1',
                      nodeType: ReaderNodeType.verse,
                      primaryText: 'Recovered verse text',
                    ),
                  ],
                );
              },
        );

        await tester.pumpWidget(
          MaterialApp(home: CoreReaderShell(adapter: adapter)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to load section.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Allow next load to succeed and tap Retry
        shouldFail = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('Recovered verse text'), findsOneWidget);
        expect(find.text('Failed to load section.'), findsNothing);
      },
    );
  });
}
