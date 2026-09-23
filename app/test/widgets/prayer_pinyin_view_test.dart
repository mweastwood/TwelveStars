import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayers/prayer_pinyin_view.dart';
import '../test_helper.dart';

void main() {
  group('PrayerPinyinView Widget Tests', () {
    testWidgets(
      'Phonetic Segmentation: renders Chinese characters, Pinyin annotations, and tone marks',
      (tester) async {
        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('我', 'wǒ', 'phrase_1'),
              ChineseChar('們', 'men', 'phrase_1'),
              ChineseChar('的', 'de', 'phrase_1'),
              ChineseChar('天', 'tiān', 'phrase_2'),
              ChineseChar('父', 'fù', 'phrase_2'),
              ChineseChar('，', '', null),
            ],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: null,
              isDualMode: false,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Chinese characters are rendered
        expect(find.text('我'), findsOneWidget);
        expect(find.text('們'), findsOneWidget);
        expect(find.text('的'), findsOneWidget);
        expect(find.text('天'), findsOneWidget);
        expect(find.text('父'), findsOneWidget);
        expect(find.text('，'), findsOneWidget);

        // Verify Pinyin tone marks are correctly displayed
        expect(find.text('wǒ'), findsOneWidget);
        expect(find.text('men'), findsOneWidget);
        expect(find.text('de'), findsOneWidget);
        expect(find.text('tiān'), findsOneWidget);
        expect(find.text('fù'), findsOneWidget);

        // Verify punctuation character has empty Pinyin string
        expect(find.text(''), findsWidgets);
      },
    );

    testWidgets(
      'Celebrant Prefix Regex: applies normal font weight to celebrant lines across multi-variant prefixes and leading whitespace',
      (tester) async {
        final prefixVariants = [
          '領經者：',
          '主祭:',
          'Priest:',
          '℣.',
          'V.',
          '啟:',
          '  主祭:',
        ];

        for (final prefix in prefixVariants) {
          final lines = [
            ChineseLine(
              chars: [
                ChineseChar(prefix, '', null),
                ChineseChar('主', 'zhǔ', 'p1'),
              ],
            ),
            ChineseLine(chars: [ChineseChar('會', 'huì', 'p2')]),
          ];

          await tester.pumpWidget(
            buildTestableWidget(
              child: PrayerPinyinView(
                chineseLines: lines,
                selectedPhraseId: null,
                isDualMode: false,
                isTargetColumn: false,
                fontSize: 16.0,
                layerLink: LayerLink(),
                onPhraseSelected: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Celebrant line '主' character text widget should have normal font weight
          final celebrantText = tester.widget<Text>(find.text('主'));
          expect(
            celebrantText.style?.fontWeight,
            equals(FontWeight.normal),
            reason: 'Failed for celebrant prefix: "$prefix"',
          );

          // Non-celebrant line '會' character text widget should have bold font weight
          final nonCelebrantText = tester.widget<Text>(find.text('會'));
          expect(
            nonCelebrantText.style?.fontWeight,
            equals(FontWeight.bold),
            reason: 'Failed non-celebrant check for prefix: "$prefix"',
          );
        }
      },
    );

    testWidgets(
      'Display Modes: does not wrap with CompositedTransformTarget when dual mode is disabled',
      (tester) async {
        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('天', 'tiān', 'phrase_1'),
              ChineseChar('主', 'zhǔ', 'phrase_2'),
            ],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: 'phrase_1',
              isDualMode: false,
              isTargetColumn: true,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CompositedTransformTarget), findsNothing);
      },
    );

    testWidgets(
      'Display Modes: renders CompositedTransformTarget in dual mode when target column and phrase match',
      (tester) async {
        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('天', 'tiān', 'phrase_1'),
              ChineseChar('主', 'zhǔ', 'phrase_2'),
            ],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: 'phrase_1',
              isDualMode: true,
              isTargetColumn: true,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CompositedTransformTarget), findsOneWidget);
      },
    );

    testWidgets(
      'Display Modes: renders CompositedTransformTarget for multi-character phrase in dual mode and highlights all constituent characters',
      (tester) async {
        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('我', 'wǒ', 'phrase_1'),
              ChineseChar('們', 'men', 'phrase_1'),
              ChineseChar('的', 'de', 'phrase_1'),
              ChineseChar('天', 'tiān', 'phrase_2'),
              ChineseChar('父', 'fù', 'phrase_2'),
            ],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: 'phrase_1',
              isDualMode: true,
              isTargetColumn: true,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Exactly one CompositedTransformTarget target anchor is mounted for phrase_1
        expect(find.byType(CompositedTransformTarget), findsOneWidget);

        // Verify that all 3 constituent characters of phrase_1 ('我', '們', '的') receive selection highlights
        final theme = Theme.of(tester.element(find.byType(PrayerPinyinView)));
        for (final char in ['我', '們', '的']) {
          final charText = tester.widget<Text>(find.text(char));
          expect(
            charText.style?.color,
            equals(theme.colorScheme.onPrimaryContainer),
            reason: 'Character "$char" of phrase_1 should be highlighted',
          );
        }
      },
    );

    testWidgets(
      'Display Modes: omits CompositedTransformTarget when isTargetColumn is false',
      (tester) async {
        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('天', 'tiān', 'phrase_1'),
              ChineseChar('主', 'zhǔ', 'phrase_2'),
            ],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: 'phrase_1',
              isDualMode: true,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CompositedTransformTarget), findsNothing);
      },
    );

    testWidgets(
      'Phrase Selection Styling: verifies background decoration and text colors for selected vs unselected phrases',
      (tester) async {
        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('我', 'wǒ', 'phrase_1'),
              ChineseChar('天', 'tiān', 'phrase_2'),
            ],
          ),
        ];

        late ThemeData theme;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) {
                theme = Theme.of(context);
                return PrayerPinyinView(
                  chineseLines: lines,
                  selectedPhraseId: 'phrase_1',
                  isDualMode: true,
                  isTargetColumn: false,
                  fontSize: 16.0,
                  layerLink: LayerLink(),
                  onPhraseSelected: (_) {},
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find Container for selected character ('我')
        final selectedCharFinder = find.text('我');
        final selectedContainerFinder = find
            .ancestor(of: selectedCharFinder, matching: find.byType(Container))
            .first;
        final selectedContainer = tester.widget<Container>(
          selectedContainerFinder,
        );
        final selectedBoxDec = selectedContainer.decoration as BoxDecoration;

        expect(
          selectedBoxDec.color,
          equals(theme.colorScheme.primaryContainer.withValues(alpha: 0.8)),
        );

        // Selected text colors
        final selectedCharText = tester.widget<Text>(selectedCharFinder);
        expect(
          selectedCharText.style?.color,
          equals(theme.colorScheme.onPrimaryContainer),
        );

        final selectedPinyinText = tester.widget<Text>(find.text('wǒ'));
        expect(
          selectedPinyinText.style?.color,
          equals(theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
        );

        // Find Container for unselected character ('天')
        final unselectedCharFinder = find.text('天');
        final unselectedContainerFinder = find
            .ancestor(
              of: unselectedCharFinder,
              matching: find.byType(Container),
            )
            .first;
        final unselectedContainer = tester.widget<Container>(
          unselectedContainerFinder,
        );
        final unselectedBoxDec =
            unselectedContainer.decoration as BoxDecoration;

        expect(unselectedBoxDec.color, isNull);

        // Unselected text colors
        final unselectedCharText = tester.widget<Text>(unselectedCharFinder);
        expect(
          unselectedCharText.style?.color,
          equals(theme.colorScheme.onSurface),
        );

        final unselectedPinyinText = tester.widget<Text>(find.text('tiān'));
        expect(
          unselectedPinyinText.style?.color,
          equals(theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        );
      },
    );

    testWidgets(
      'Gesture Interaction: fires onPhraseSelected on tap in dual mode and unselects when already selected',
      (tester) async {
        String? selectedResult;
        bool callbackFired = false;

        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('聖', 'shèng', 'phrase_1'),
              ChineseChar('母', 'mǔ', 'phrase_2'),
            ],
          ),
        ];

        // Dual mode active, tap unselected phrase_1
        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: null,
              isDualMode: true,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (id) {
                callbackFired = true;
                selectedResult = id;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('聖'));
        await tester.pumpAndSettle();

        expect(callbackFired, isTrue);
        expect(selectedResult, equals('phrase_1'));

        // Reset tracking flags
        callbackFired = false;
        selectedResult = null;

        // Dual mode active, tap ALREADY SELECTED phrase_1 -> should pass null to unselect
        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: 'phrase_1',
              isDualMode: true,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (id) {
                callbackFired = true;
                selectedResult = id;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('聖'));
        await tester.pumpAndSettle();

        expect(callbackFired, isTrue);
        expect(selectedResult, isNull);

        // Tap when isDualMode = false -> onPhraseSelected should NOT fire
        callbackFired = false;
        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: null,
              isDualMode: false,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {
                callbackFired = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('聖'));
        await tester.pumpAndSettle();

        expect(callbackFired, isFalse);
      },
    );

    testWidgets(
      'Gesture Interaction: does not fire onPhraseSelected when tapping punctuation or null phraseId characters',
      (tester) async {
        bool callbackFired = false;

        final lines = [
          ChineseLine(
            chars: [ChineseChar('，', '', null), ChineseChar('字', 'zì', null)],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: lines,
              selectedPhraseId: null,
              isDualMode: true,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {
                callbackFired = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap punctuation character with null phraseId
        await tester.tap(find.text('，'));
        await tester.pumpAndSettle();
        expect(callbackFired, isFalse);

        // Tap unannotated character with null phraseId
        await tester.tap(find.text('字'));
        await tester.pumpAndSettle();
        expect(callbackFired, isFalse);
      },
    );

    testWidgets(
      'Empty / Null Handling: handles empty chineseLines, null char lists, and empty strings gracefully',
      (tester) async {
        // 1. Empty lines list
        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: const [],
              selectedPhraseId: null,
              isDualMode: false,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Column), findsOneWidget);

        // 2. Line with null chars
        final nullCharsLines = [ChineseLine(chars: null)];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: nullCharsLines,
              selectedPhraseId: null,
              isDualMode: false,
              isTargetColumn: false,
              fontSize: 16.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Wrap), findsOneWidget);

        // 3. Line with empty chars and blank fields
        final emptyFieldsLines = [
          ChineseLine(
            chars: [
              ChineseChar('', '', null),
              ChineseChar('字', '', 'phrase_x'),
            ],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: PrayerPinyinView(
              chineseLines: emptyFieldsLines,
              selectedPhraseId: 'phrase_y',
              isDualMode: true,
              isTargetColumn: false,
              fontSize: 18.0,
              layerLink: LayerLink(),
              onPhraseSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('字'), findsOneWidget);
      },
    );
  });
}
