import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayers/prayer_rich_text_span_builder.dart';

void main() {
  final theme = ThemeData.light(useMaterial3: true);

  List<TextSpan> collectLeafTextSpans(List<InlineSpan> spans) {
    final leaves = <TextSpan>[];
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text != null) {
          leaves.add(span);
        }
        span.children?.forEach(visit);
      }
    }

    for (final s in spans) {
      visit(s);
    }
    return leaves;
  }

  List<WidgetSpan> collectWidgetSpans(List<InlineSpan> spans) {
    final widgets = <WidgetSpan>[];
    void visit(InlineSpan span) {
      if (span is WidgetSpan) {
        widgets.add(span);
      } else if (span is TextSpan) {
        span.children?.forEach(visit);
      }
    }

    for (final s in spans) {
      visit(s);
    }
    return widgets;
  }

  group('PrayerRichTextSpanBuilder.parseItalicsSpans', () {
    test(
      'parses *italic* segments with FontStyle.italic and preserves underscores',
      () {
        const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
        final recognizer = TapGestureRecognizer();
        addTearDown(recognizer.dispose);

        final asteriskSpans = PrayerRichTextSpanBuilder.parseItalicsSpans(
          'He came down, *and became man*, for us.',
          baseStyle,
          recognizer: recognizer,
        );

        expect(asteriskSpans, hasLength(3));
        final a0 = asteriskSpans[0] as TextSpan;
        final a1 = asteriskSpans[1] as TextSpan;
        final a2 = asteriskSpans[2] as TextSpan;

        expect(a0.text, equals('He came down, '));
        expect(a0.style?.fontStyle, isNull);
        expect(a0.recognizer, same(recognizer));

        expect(a1.text, equals('and became man'));
        expect(a1.style?.fontStyle, equals(FontStyle.italic));
        expect(a1.style?.fontSize, equals(16));
        expect(a1.recognizer, same(recognizer));

        expect(a2.text, equals(', for us.'));
        expect(a2.style?.fontStyle, isNull);
        expect(a2.recognizer, same(recognizer));

        final multiSpans = PrayerRichTextSpanBuilder.parseItalicsSpans(
          'Bow at *et incarnatus est* here (*genuflect*).',
          baseStyle,
        );

        expect(multiSpans, hasLength(5));
        expect((multiSpans[0] as TextSpan).text, equals('Bow at '));
        expect(
          (multiSpans[0] as TextSpan).style?.fontStyle,
          isNot(FontStyle.italic),
        );
        expect((multiSpans[1] as TextSpan).text, equals('et incarnatus est'));
        expect(
          (multiSpans[1] as TextSpan).style?.fontStyle,
          equals(FontStyle.italic),
        );
        expect((multiSpans[2] as TextSpan).text, equals(' here ('));
        expect((multiSpans[3] as TextSpan).text, equals('genuflect'));
        expect(
          (multiSpans[3] as TextSpan).style?.fontStyle,
          equals(FontStyle.italic),
        );
        expect((multiSpans[4] as TextSpan).text, equals(').'));
      },
    );

    test('returns single TextSpan when no italics markers are present', () {
      const baseStyle = TextStyle(fontSize: 14);
      final spans = PrayerRichTextSpanBuilder.parseItalicsSpans(
        'Plain liturgical text.',
        baseStyle,
      );

      expect(spans, hasLength(1));
      final span = spans.single as TextSpan;
      expect(span.text, equals('Plain liturgical text.'));
      expect(span.style, equals(baseStyle));
    });
  });

  group('PrayerRichTextSpanBuilder token spans (single vs dual mode)', () {
    test(
      'buildTokenSpan in single mode renders plain TextSpan without dashed underline or recognizer',
      () {
        final recognizers = <String, TapGestureRecognizer>{};
        final activeKeys = <String>{};
        addTearDown(() {
          for (final r in recognizers.values) {
            r.dispose();
          }
        });

        final builder = PrayerRichTextSpanBuilder(
          theme: theme,
          fontSize: 18.0,
          isDualMode: false,
          recognizers: recognizers,
          activeRecognizerKeys: activeKeys,
        );

        final span = builder.buildTokenSpan(
          PrayerToken('who art in heaven', 'heaven'),
          0,
        );

        final leaves = collectLeafTextSpans([span]);
        expect(leaves, hasLength(1));
        expect(leaves.single.text, equals('who art in heaven'));
        expect(leaves.single.style?.fontSize, equals(18.0));
        expect(
          leaves.single.style?.decoration,
          anyOf(isNull, equals(TextDecoration.none)),
        );
        expect(leaves.single.recognizer, isNull);
        expect(activeKeys, isEmpty);
      },
    );

    test(
      'buildTokenSpan in dual mode styles unselected aligned tokens with dashed underline and registers recognizer',
      () {
        final recognizers = <String, TapGestureRecognizer>{};
        final activeKeys = <String>{};
        String? tappedPhrase;
        addTearDown(() {
          for (final r in recognizers.values) {
            r.dispose();
          }
        });

        final builder = PrayerRichTextSpanBuilder(
          theme: theme,
          isDualMode: true,
          recognizers: recognizers,
          activeRecognizerKeys: activeKeys,
          onPhraseSelected: (id) => tappedPhrase = id,
        );

        final alignedSpan = builder.buildTokenSpan(
          PrayerToken('who art in heaven', 'heaven'),
          1,
          isTarget: false,
        );
        final unalignedSpan = builder.buildTokenSpan(
          PrayerToken(', ', null),
          2,
          isTarget: false,
        );

        final alignedLeaf = collectLeafTextSpans([alignedSpan]).single;
        expect(alignedLeaf.style?.decoration, equals(TextDecoration.underline));
        expect(
          alignedLeaf.style?.decorationStyle,
          equals(TextDecorationStyle.dashed),
        );
        expect(alignedLeaf.recognizer, isA<TapGestureRecognizer>());
        expect(activeKeys, contains('primary_1_heaven'));

        (alignedLeaf.recognizer as TapGestureRecognizer).onTap!();
        expect(tappedPhrase, equals('heaven'));

        final unalignedLeaf = collectLeafTextSpans([unalignedSpan]).single;
        expect(
          unalignedLeaf.style?.decoration,
          anyOf(isNull, equals(TextDecoration.none)),
        );
        expect(unalignedLeaf.recognizer, isNull);
      },
    );

    testWidgets(
      'selected phrase highlights token, toggles deselection on tap, and attaches CompositedTransformTarget only to last matching target token',
      (tester) async {
        final recognizers = <String, TapGestureRecognizer>{};
        final activeKeys = <String>{};
        final layerLink = LayerLink();
        final targetKey = GlobalKey();
        String? lastSelected = 'p1';
        addTearDown(() {
          for (final r in recognizers.values) {
            r.dispose();
          }
        });

        final tokens = [
          PrayerToken('Et ne', 'p1'),
          PrayerToken(' nos ', 'p2'),
          PrayerToken('inducas', 'p1'),
        ];

        final primaryBuilder = PrayerRichTextSpanBuilder(
          theme: theme,
          isDualMode: true,
          selectedPhraseId: 'p1',
          layerLink: layerLink,
          recognizers: recognizers,
          activeRecognizerKeys: activeKeys,
          onPhraseSelected: (id) => lastSelected = id,
        );

        final targetBuilder = PrayerRichTextSpanBuilder(
          theme: theme,
          isDualMode: true,
          selectedPhraseId: 'p1',
          layerLink: layerLink,
          targetKey: targetKey,
          recognizers: recognizers,
          activeRecognizerKeys: activeKeys,
          onPhraseSelected: (id) => lastSelected = id,
        );

        final primarySpans = primaryBuilder.buildTokenizedSpans(
          tokens,
          isTargetColumn: false,
        );
        final targetSpans = targetBuilder.buildTokenizedSpans(
          tokens,
          isTargetColumn: true,
        );

        // Primary column must not attach CompositedTransformTarget
        expect(collectWidgetSpans(primarySpans), isEmpty);

        // Target column attaches exactly one CompositedTransformTarget (on the last matching token)
        final targetWidgets = collectWidgetSpans(targetSpans);
        expect(targetWidgets, hasLength(1));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text.rich(TextSpan(children: primarySpans)),
                  Text.rich(TextSpan(children: targetSpans)),
                ],
              ),
            ),
          ),
        );

        expect(find.byKey(targetKey), findsOneWidget);
        expect(find.byType(CompositedTransformTarget), findsOneWidget);

        final targetLeaves = collectLeafTextSpans(targetSpans);
        final firstMatch = targetLeaves.firstWhere((s) => s.text == 'Et ne');
        final middleUnselected = targetLeaves.firstWhere(
          (s) => s.text == ' nos ',
        );
        final secondMatch = targetLeaves.firstWhere((s) => s.text == 'inducas');

        expect(
          firstMatch.style?.backgroundColor,
          equals(theme.colorScheme.primaryContainer.withValues(alpha: 0.8)),
        );
        expect(
          secondMatch.style?.backgroundColor,
          equals(theme.colorScheme.primaryContainer.withValues(alpha: 0.8)),
        );
        expect(middleUnselected.style?.backgroundColor, isNull);

        // Tapping an already-selected token deselects it (passes null)
        (firstMatch.recognizer as TapGestureRecognizer).onTap!();
        expect(lastSelected, isNull);

        // Tapping an unselected token selects its phraseId
        (middleUnselected.recognizer as TapGestureRecognizer).onTap!();
        expect(lastSelected, equals('p2'));
      },
    );
  });

  group('PrayerRichTextSpanBuilder multi-line response bolding', () {
    test(
      'buildTokenizedSpans splits newline tokens and bolds R. response lines while keeping leader lines normal',
      () {
        final builder = PrayerRichTextSpanBuilder(
          theme: theme,
          isDualMode: false,
        );

        final tokens = [
          PrayerToken('V. ', null),
          PrayerToken('The Lord be with you.', 'v1'),
          PrayerToken('\nR. ', null),
          PrayerToken('And with your *spirit*.', 'r1'),
          PrayerToken('\nCelebrant: Let us pray.\nR. Amen.', null),
        ];

        final spans = builder.buildTokenizedSpans(tokens);
        final leaves = collectLeafTextSpans(spans);

        final byText = <String, TextSpan>{
          for (final leaf in leaves)
            if (leaf.text != null && leaf.text!.trim().isNotEmpty)
              leaf.text!.trim(): leaf,
        };

        expect(byText['V.']?.style?.fontWeight, isNull);
        expect(byText['The Lord be with you.']?.style?.fontWeight, isNull);

        expect(byText['R.']?.style?.fontWeight, equals(FontWeight.bold));
        expect(
          byText['And with your']?.style?.fontWeight,
          equals(FontWeight.bold),
        );
        expect(byText['spirit']?.style?.fontWeight, equals(FontWeight.bold));
        expect(byText['spirit']?.style?.fontStyle, equals(FontStyle.italic));

        expect(byText['Celebrant: Let us pray.']?.style?.fontWeight, isNull);
        expect(byText['R. Amen.']?.style?.fontWeight, equals(FontWeight.bold));
      },
    );

    test(
      'buildPlainTextSpans bolds R. response lines and preserves inline italics across lines',
      () {
        final builder = PrayerRichTextSpanBuilder(theme: theme, fontSize: 17.0);

        const dialogueText =
            'Priest: The Word of the Lord.\nR. Thanks be to *God*.';
        final dialogueSpans = builder.buildPlainTextSpans(dialogueText);
        final dialogueLeaves = collectLeafTextSpans(dialogueSpans);

        final leaderSpan = dialogueLeaves.firstWhere(
          (s) => s.text == 'Priest: The Word of the Lord.',
        );
        final responseNormalSpan = dialogueLeaves.firstWhere(
          (s) => s.text == 'R. Thanks be to ',
        );
        final responseItalicSpan = dialogueLeaves.firstWhere(
          (s) => s.text == 'God',
        );

        expect(leaderSpan.style?.fontWeight, isNull);
        expect(leaderSpan.style?.fontSize, equals(17.0));

        expect(responseNormalSpan.style?.fontWeight, equals(FontWeight.bold));
        expect(responseItalicSpan.style?.fontWeight, equals(FontWeight.bold));
        expect(responseItalicSpan.style?.fontStyle, equals(FontStyle.italic));

        const nonDialogueText =
            'Hail Mary, *full of grace*, the Lord is with thee.';
        final plainSpans = builder.buildPlainTextSpans(nonDialogueText);
        final plainLeaves = collectLeafTextSpans(plainSpans);

        expect(plainLeaves, hasLength(3));
        expect(plainLeaves[0].style?.fontWeight, isNull);
        expect(plainLeaves[1].text, equals('full of grace'));
        expect(plainLeaves[1].style?.fontStyle, equals(FontStyle.italic));
      },
    );
  });
}
