import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/widgets/reader/reader_parallel_view.dart';

void main() {
  group('Phase 3 ReaderParallelView Widget Tests', () {
    testWidgets('renders primary and secondary side-by-side nodes', (
      tester,
    ) async {
      const nodes = [
        ReaderContentNode(
          id: '1_1',
          nodeType: ReaderNodeType.verse,
          primaryText: 'In the beginning God created heaven, and earth.',
          secondaryText: 'In principio creavit Deus caelum et terram.',
          questionNumber: '1',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReaderParallelView(nodes: nodes, fontSize: 16.0),
          ),
        ),
      );

      expect(
        find.textContaining('In the beginning', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('In principio creavit Deus caelum et terram.'),
        findsOneWidget,
      );
      expect(find.textContaining('1', findRichText: true), findsOneWidget);
    });

    testWidgets('handles selection highlighting and gestures', (tester) async {
      String? tappedId;
      String? longPressedId;

      const nodes = [
        ReaderContentNode(
          id: 'node_1',
          nodeType: ReaderNodeType.paragraph,
          primaryText: 'Paragraph text content.',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderParallelView(
              nodes: nodes,
              selectedNodeIds: const {'node_1'},
              onNodeTap: (id) => tappedId = id,
              onNodeLongPress: (id) => longPressedId = id,
            ),
          ),
        ),
      );

      await tester.tap(
        find.textContaining('Paragraph text content.', findRichText: true),
      );
      await tester.pump();
      expect(tappedId, equals('node_1'));

      await tester.longPress(
        find.textContaining('Paragraph text content.', findRichText: true),
      );
      await tester.pump();
      expect(longPressedId, equals('node_1'));
    });
  });
}
