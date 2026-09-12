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

    testWidgets(
      'renders heading node with titleMedium, bold weight, and primary color',
      (tester) async {
        const nodes = [
          ReaderContentNode(
            id: 'heading_1',
            nodeType: ReaderNodeType.heading,
            primaryText: 'Chapter 1: The Beginning',
          ),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ReaderParallelView(nodes: nodes)),
          ),
        );

        final textFinder = find.text('Chapter 1: The Beginning');
        expect(textFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(textFinder);
        final theme = Theme.of(tester.element(textFinder));

        expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
        expect(textWidget.style?.color, equals(theme.colorScheme.primary));
        expect(
          textWidget.style?.fontSize,
          equals(theme.textTheme.titleMedium?.fontSize),
        );
      },
    );

    testWidgets('renders qa node with question number and answer', (
      tester,
    ) async {
      const nodes = [
        ReaderContentNode(
          id: 'qa_1',
          nodeType: ReaderNodeType.qa,
          questionNumber: '1',
          question: 'What is the chief end of man?',
          answer: 'Man\'s chief end is to glorify God...',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReaderParallelView(nodes: nodes)),
        ),
      );

      final theme = Theme.of(tester.element(find.byType(ReaderParallelView)));

      final richTexts = tester
          .widgetList<RichText>(find.byType(RichText))
          .toList();
      expect(richTexts.length, equals(2));

      final questionSpan = richTexts[0].text as TextSpan;
      final qPrefixSpan = questionSpan.children![0] as TextSpan;
      final qTextSpan = questionSpan.children![1] as TextSpan;

      expect(qPrefixSpan.text, equals('Q. 1. '));
      expect(qPrefixSpan.style?.fontWeight, equals(FontWeight.bold));
      expect(qPrefixSpan.style?.color, equals(theme.colorScheme.primary));

      expect(qTextSpan.text, equals('What is the chief end of man?'));
      expect(qTextSpan.style?.fontWeight, equals(FontWeight.bold));

      final answerSpan = richTexts[1].text as TextSpan;
      final aPrefixSpan = answerSpan.children![0] as TextSpan;
      final aTextSpan = answerSpan.children![1] as TextSpan;

      expect(aPrefixSpan.text, equals('A. '));
      expect(aPrefixSpan.style?.fontWeight, equals(FontWeight.bold));
      expect(aPrefixSpan.style?.color, equals(theme.colorScheme.secondary));

      expect(aTextSpan.text, equals('Man\'s chief end is to glorify God...'));
    });

    testWidgets('renders qa node without question number and without answer', (
      tester,
    ) async {
      const nodes = [
        ReaderContentNode(
          id: 'qa_2',
          nodeType: ReaderNodeType.qa,
          questionNumber: null,
          question: 'What is faith?',
          answer: null,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReaderParallelView(nodes: nodes)),
        ),
      );

      final richTexts = tester
          .widgetList<RichText>(find.byType(RichText))
          .toList();
      expect(richTexts.length, equals(1));

      final questionSpan = richTexts[0].text as TextSpan;
      final qPrefixSpan = questionSpan.children![0] as TextSpan;

      expect(qPrefixSpan.text, equals('Q. '));
      expect(find.textContaining('A. ', findRichText: true), findsNothing);
    });

    testWidgets('renders verse node with questionNumber prefix', (
      tester,
    ) async {
      const nodes = [
        ReaderContentNode(
          id: 'v_12',
          nodeType: ReaderNodeType.verse,
          primaryText: 'And God said, Let there be light: and there was light.',
          questionNumber: '12',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReaderParallelView(nodes: nodes, fontSize: 16.0),
          ),
        ),
      );

      final theme = Theme.of(tester.element(find.byType(ReaderParallelView)));
      final richText = tester.widget<RichText>(find.byType(RichText));
      final rootSpan = richText.text as TextSpan;

      expect(rootSpan.children?.length, equals(2));
      final prefixSpan = rootSpan.children![0] as TextSpan;
      final textSpan = rootSpan.children![1] as TextSpan;

      expect(prefixSpan.text, equals('12 '));
      expect(prefixSpan.style?.fontWeight, equals(FontWeight.bold));
      expect(prefixSpan.style?.fontSize, equals(16.0 * 0.85));
      expect(prefixSpan.style?.color, equals(theme.colorScheme.primary));
      expect(
        textSpan.text,
        equals('And God said, Let there be light: and there was light.'),
      );
    });

    testWidgets('renders verse node without questionNumber prefix when null', (
      tester,
    ) async {
      const nodes = [
        ReaderContentNode(
          id: 'v_no_num',
          nodeType: ReaderNodeType.verse,
          primaryText: 'No verse number here.',
          questionNumber: null,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReaderParallelView(nodes: nodes)),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final rootSpan = richText.text as TextSpan;

      expect(rootSpan.children?.length, equals(1));
      final textSpan = rootSpan.children![0] as TextSpan;
      expect(textSpan.text, equals('No verse number here.'));
    });

    testWidgets(
      'renders single-column layout when secondaryText is null or empty',
      (tester) async {
        const nodes = [
          ReaderContentNode(
            id: 'single_null',
            nodeType: ReaderNodeType.paragraph,
            primaryText: 'Primary paragraph without secondary text.',
            secondaryText: null,
          ),
          ReaderContentNode(
            id: 'single_empty',
            nodeType: ReaderNodeType.paragraph,
            primaryText: 'Primary paragraph with empty secondary text.',
            secondaryText: '',
          ),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ReaderParallelView(nodes: nodes)),
          ),
        );

        expect(find.byType(Row), findsNothing);
        expect(find.byType(Expanded), findsNothing);
        expect(
          find.textContaining(
            'Primary paragraph without secondary text.',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Primary paragraph with empty secondary text.',
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders dual-column layout with Row, Expanded, and divider when secondaryText is populated',
      (tester) async {
        const nodes = [
          ReaderContentNode(
            id: 'dual_1',
            nodeType: ReaderNodeType.paragraph,
            primaryText: 'Left column text.',
            secondaryText: 'Right column text.',
          ),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ReaderParallelView(nodes: nodes)),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsNWidgets(2));
        expect(
          find.textContaining('Left column text.', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Right column text.'), findsOneWidget);

        final theme = Theme.of(tester.element(find.byType(ReaderParallelView)));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.constraints?.maxWidth == 1 &&
                widget.constraints?.maxHeight == 40 &&
                widget.color ==
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('scales body text and prefix font sizes with custom fontSize', (
      tester,
    ) async {
      const customFontSize = 24.0;
      const nodes = [
        ReaderContentNode(
          id: 'v_scale',
          nodeType: ReaderNodeType.verse,
          primaryText: 'Scaled primary verse.',
          secondaryText: 'Scaled secondary translation.',
          questionNumber: '5',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReaderParallelView(nodes: nodes, fontSize: customFontSize),
          ),
        ),
      );

      final primaryRichText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(Expanded).first,
          matching: find.byType(RichText),
        ),
      );
      final rootSpan = primaryRichText.text as TextSpan;
      expect(rootSpan.style?.fontSize, equals(customFontSize));

      final prefixSpan = rootSpan.children![0] as TextSpan;
      expect(prefixSpan.style?.fontSize, equals(customFontSize * 0.85));

      final secondaryTextWidget = tester.widget<Text>(
        find.text('Scaled secondary translation.'),
      );
      expect(secondaryTextWidget.style?.fontSize, equals(customFontSize));
    });
  });
}
