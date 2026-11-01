import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/prayer_text_parser.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/ai_generation_sheet.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/prayers/prayer_card_components.dart';
import 'package:twelve_stars/widgets/prayers/prayer_pinyin_view.dart';

import '../test_helper.dart';

class _CapturingAiService implements AiService {
  AiCoreStatus status = AiCoreStatus.available;
  String? nextResponse = 'Detailed etymological explanation.';
  String? lastPrompt;
  int? lastMaxOutputTokens;

  @override
  Future<AiCoreStatus> checkStatus() async => status;

  @override
  Future<void> triggerDownload() async {}

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {}

  @override
  Future<int> countTokens({
    required String prompt,
    Uint8List? imageBytes,
  }) async => 42;

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    lastPrompt = prompt;
    lastMaxOutputTokens = maxOutputTokens;
    return nextResponse;
  }

  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    lastPrompt = prompt;
    lastMaxOutputTokens = maxOutputTokens;
    final res = nextResponse;
    if (res == null) return null;
    return AiResponse(text: res, isTruncated: false);
  }
}

void main() {
  group('PrayerTextParser', () {
    test(
      'isResponseLine identifies congregational response prefixes across languages',
      () {
        expect(PrayerTextParser.isResponseLine('People: Amen.'), isTrue);
        expect(
          PrayerTextParser.isResponseLine('  All: Thanks be to God.'),
          isTrue,
        );
        expect(
          PrayerTextParser.isResponseLine('Populus: Et cum spiritu tuo.'),
          isTrue,
        );
        expect(PrayerTextParser.isResponseLine('Omnes: Amen.'), isTrue);
        expect(
          PrayerTextParser.isResponseLine('Asamblea: Y con tu espíritu.'),
          isTrue,
        );
        expect(
          PrayerTextParser.isResponseLine('Cộng đoàn: Và ở cùng cha.'),
          isTrue,
        );
        expect(PrayerTextParser.isResponseLine('Peuple : Amen.'), isTrue);
        expect(PrayerTextParser.isResponseLine('Tutti: Amen.'), isTrue);
        expect(PrayerTextParser.isResponseLine('Bayan: Amen.'), isTrue);
        expect(PrayerTextParser.isResponseLine('全體: 求主俯聽我們。'), isTrue);
        expect(PrayerTextParser.isResponseLine('眾：阿們。'), isTrue);
        expect(
          PrayerTextParser.isResponseLine('℟. Et cum spiritu tuo.'),
          isTrue,
        );
        expect(PrayerTextParser.isResponseLine('R. Thanks be to God.'), isTrue);
        expect(PrayerTextParser.isResponseLine('R: Amen.'), isTrue);

        expect(
          PrayerTextParser.isResponseLine('Priest: The Lord be with you.'),
          isFalse,
        );
        expect(PrayerTextParser.isResponseLine('領經者: 為此我們同聲祈禱。'), isFalse);
        expect(
          PrayerTextParser.isResponseLine('Our Father, who art in heaven,'),
          isFalse,
        );
        expect(PrayerTextParser.isResponseLine('我們的天父，'), isFalse);
      },
    );

    test(
      'isCelebrantLine identifies celebrant and leader prefixes across languages',
      () {
        expect(
          PrayerTextParser.isCelebrantLine('Priest: The Lord be with you.'),
          isTrue,
        );
        expect(
          PrayerTextParser.isCelebrantLine('Celebrant: Let us pray.'),
          isTrue,
        );
        expect(
          PrayerTextParser.isCelebrantLine('Sacerdos: Dominus vobiscum.'),
          isTrue,
        );
        expect(
          PrayerTextParser.isCelebrantLine(
            'Sacerdote: El Señor esté con vosotros.',
          ),
          isTrue,
        );
        expect(
          PrayerTextParser.isCelebrantLine('Linh mục: Chúa ở cùng anh chị em.'),
          isTrue,
        );
        expect(PrayerTextParser.isCelebrantLine('領經者: 為此'), isTrue);
        expect(PrayerTextParser.isCelebrantLine('領: 為此'), isTrue);
        expect(PrayerTextParser.isCelebrantLine('主祭：願主與你們同在。'), isTrue);
        expect(
          PrayerTextParser.isCelebrantLine('℣. Domine, labia mea aperies.'),
          isTrue,
        );
        expect(
          PrayerTextParser.isCelebrantLine('V. The Lord be with you.'),
          isTrue,
        );

        expect(
          PrayerTextParser.isCelebrantLine('People: And with your spirit.'),
          isFalse,
        );
        expect(PrayerTextParser.isCelebrantLine('全體: 求主'), isFalse);
        expect(
          PrayerTextParser.isCelebrantLine('Our Father, who art in heaven,'),
          isFalse,
        );
      },
    );

    test(
      'computeLineStartOffsets and getLineIndexAt compute accurate character offsets',
      () {
        final lines = ['Priest: Hello', 'People: Amen', 'Third line'];
        final offsets = PrayerTextParser.computeLineStartOffsets(lines);
        // 'Priest: Hello\n' -> length 13 + 1 = 14
        // 'People: Amen\n' -> 14 + 12 + 1 = 27
        expect(offsets, equals([0, 14, 27]));

        expect(PrayerTextParser.getLineIndexAt(offsets, 0), equals(0));
        expect(PrayerTextParser.getLineIndexAt(offsets, 12), equals(0));
        expect(PrayerTextParser.getLineIndexAt(offsets, 14), equals(1));
        expect(PrayerTextParser.getLineIndexAt(offsets, 20), equals(1));
        expect(PrayerTextParser.getLineIndexAt(offsets, 27), equals(2));
        expect(PrayerTextParser.getLineIndexAt(offsets, 100), equals(2));
        expect(PrayerTextParser.getLineIndexAt(const [], 5), equals(0));
      },
    );

    test(
      'extractPhraseText slices phrases from PrayerTranslation tokens, Chinese lines, and plain strings',
      () {
        final tokenTrans = PrayerTranslation.mock(
          title: 'Creed',
          text: 'He came down, *and became man*.',
          tokens: [
            PrayerToken('He came down, ', 'p1'),
            PrayerToken('*and became man*', 'p1'),
            PrayerToken('.', null),
          ],
        );
        expect(
          PrayerTextParser.extractPhraseText(tokenTrans, 'p1'),
          equals('He came down, and became man'),
        );
        expect(
          PrayerTextParser.extractPhraseText(tokenTrans, 'missing'),
          isEmpty,
        );

        final chineseTrans = PrayerTranslation.mock(
          title: '天主經',
          text: '我們的天父',
          tokens: null,
          chineseLines: [
            [
              ChineseChar('我', 'wǒ', 'p1'),
              ChineseChar('們', 'men', 'p1'),
              ChineseChar('的', 'de', 'p1'),
              ChineseChar('天', 'tiān', 'p2'),
              ChineseChar('父', 'fù', 'p2'),
            ],
          ],
        );
        expect(
          PrayerTextParser.extractPhraseText(chineseTrans, 'p1'),
          equals('我們的'),
        );
        expect(
          PrayerTextParser.extractPhraseText(chineseTrans, 'p2'),
          equals('天父'),
        );

        const multiLine =
            'Our Father, who art in heaven,\n*hallowed be thy name*;\nthy kingdom come';
        expect(
          PrayerTextParser.extractPhraseText(multiLine, 0),
          equals('Our Father, who art in heaven,'),
        );
        expect(
          PrayerTextParser.extractPhraseText(multiLine, 1),
          equals('hallowed be thy name;'),
        );
        expect(PrayerTextParser.extractPhraseText(multiLine, null), isEmpty);
        expect(PrayerTextParser.extractPhraseText(multiLine, -1), isEmpty);
        expect(PrayerTextParser.extractPhraseText(multiLine, 99), isEmpty);
      },
    );
  });

  group('LocalAgentHelper Translation Explanation', () {
    late _CapturingAiService fakeAi;

    setUp(() {
      fakeAi = _CapturingAiService();
      LocalAgentHelper.instance = fakeAi;
    });

    tearDown(() {
      LocalAgentHelper.instance = null;
    });

    test(
      'buildTranslationExplanationPrompt formats phrase and context sections',
      () {
        final prompt = LocalAgentHelper.buildTranslationExplanationPrompt(
          originalPhrase: 'qui es in caelis',
          translatedPhrase: 'who art in heaven',
          originalContext: 'Pater noster, qui es in caelis',
          translatedContext: 'Our Father, who art in heaven',
          originalLang: 'Latin',
          translatedLang: 'English',
        );

        expect(prompt, contains('Original phrase:\nqui es in caelis'));
        expect(prompt, contains('Translated phrase:\nwho art in heaven'));
        expect(
          prompt,
          contains(
            'Original phrase in context:\nPater noster, qui es in caelis',
          ),
        );
        expect(
          prompt,
          contains(
            'Translated phrase in context:\nOur Father, who art in heaven',
          ),
        );
        expect(
          prompt,
          contains('Define each translated word in the selected phrase'),
        );
      },
    );

    test(
      'generateTranslationExplanation delegates to AI service and throws AiGenerationUserMessageException when empty or null',
      () async {
        final result = await LocalAgentHelper.instance
            .generateTranslationExplanation(
              originalPhrase: 'qui es in caelis',
              translatedPhrase: 'who art in heaven',
              originalContext: 'Pater noster, qui es in caelis',
              translatedContext: 'Our Father, who art in heaven',
            );

        expect(result, equals('Detailed etymological explanation.'));
        expect(fakeAi.lastPrompt, contains('qui es in caelis'));
        expect(fakeAi.lastMaxOutputTokens, equals(256));

        fakeAi.nextResponse = null;
        await expectLater(
          () => LocalAgentHelper.generateTranslationExplanation(
            originalPhrase: 'qui es in caelis',
            translatedPhrase: 'who art in heaven',
            originalContext: 'Pater noster, qui es in caelis',
            translatedContext: 'Our Father, who art in heaven',
          ),
          throwsA(isA<AiGenerationUserMessageException>()),
        );

        fakeAi.nextResponse = '   \n  ';
        await expectLater(
          () => LocalAgentHelper.instance.generateTranslationExplanation(
            originalPhrase: 'qui es in caelis',
            translatedPhrase: 'who art in heaven',
            originalContext: 'Pater noster, qui es in caelis',
            translatedContext: 'Our Father, who art in heaven',
          ),
          throwsA(isA<AiGenerationUserMessageException>()),
        );
      },
    );
  });

  group('PrayerPinyinView & Extracted Sub-Widgets', () {
    tearDown(() {
      LocalAgentHelper.instance = null;
    });

    testWidgets(
      'PrayerPinyinView attaches targetKey to CompositedTransformTarget and renders celebrant lines in normal weight and non-celebrant lines in bold',
      (tester) async {
        final targetKey = GlobalKey();
        final layerLink = LayerLink();

        final lines = [
          ChineseLine(
            chars: [
              ChineseChar('我', 'wǒ', 'p1'),
              ChineseChar('們', 'men', 'p1'),
            ],
          ),
          ChineseLine(
            chars: [
              ChineseChar('領', 'lǐng'),
              ChineseChar('經', 'jīng'),
              ChineseChar('者', 'zhě'),
              ChineseChar(':', ''),
              ChineseChar('請', 'qǐng'),
            ],
          ),
          ChineseLine(
            chars: [
              ChineseChar('全', 'quán'),
              ChineseChar('體', 'tǐ'),
              ChineseChar(':', ''),
              ChineseChar('求', 'qiú'),
            ],
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: PrayerPinyinView(
                chineseLines: lines,
                selectedPhraseId: 'p1',
                isDualMode: true,
                isTargetColumn: true,
                fontSize: 16.0,
                layerLink: layerLink,
                targetKey: targetKey,
                onPhraseSelected: (_) {},
              ),
            ),
          ),
        );

        // 1. targetKey is attached to CompositedTransformTarget wrapping '們'
        expect(targetKey.currentContext, isNotNull);
        final targetFinder = find.byKey(targetKey);
        expect(targetFinder, findsOneWidget);
        expect(
          find.descendant(of: targetFinder, matching: find.text('們')),
          findsOneWidget,
        );

        // 2. Celebrant line ('領') is FontWeight.normal; non-celebrant lines ('我' and '全') are FontWeight.bold.
        final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
        final normalPrayerChar = textWidgets.firstWhere((w) => w.data == '我');
        final leaderChar = textWidgets.firstWhere((w) => w.data == '領');
        final responseChar = textWidgets.firstWhere((w) => w.data == '全');

        expect(normalPrayerChar.style?.fontWeight, equals(FontWeight.bold));
        expect(leaderChar.style?.fontWeight, equals(FontWeight.normal));
        expect(responseChar.style?.fontWeight, equals(FontWeight.bold));
      },
    );

    testWidgets(
      'PrayerCard clamps floating AI button within Card bounds when right-column target is a Chinese phrase near the right edge',
      (tester) async {
        final fakeAi = _CapturingAiService();
        LocalAgentHelper.instance = fakeAi;

        final chineseEdgePrayer = Prayer.mock(
          id: 'chinese_edge_prayer',
          defaultTitle: 'Our Father',
          translations: {
            PrayerLanguage.english: [
              PrayerTranslation.mock(
                title: 'Our Father',
                text: 'Our Father who art in heaven hallowed be thy name',
                tokens: [
                  PrayerToken(
                    'Our Father who art in heaven hallowed be thy name',
                    'p1',
                  ),
                ],
              ),
            ],
            PrayerLanguage.traditionalChinese: [
              PrayerTranslation.mock(
                title: '天主經',
                text: '我們的天父願祢的名受顯揚',
                tokens: null,
                chineseLines: [
                  [
                    ChineseChar('我', 'wǒ', 'p1'),
                    ChineseChar('們', 'men', 'p1'),
                    ChineseChar('的', 'de', 'p1'),
                    ChineseChar('天', 'tiān', 'p1'),
                    ChineseChar('父', 'fù', 'p1'),
                    ChineseChar('願', 'yuàn', 'p1'),
                    ChineseChar('祢', 'nǐ', 'p1'),
                    ChineseChar('的', 'de', 'p1'),
                    ChineseChar('名', 'míng', 'p1'),
                    ChineseChar('受', 'shòu', 'p1'),
                    ChineseChar('顯', 'xiǎn', 'p1'),
                    ChineseChar('揚', 'yáng', 'p1'),
                  ],
                ],
              ),
            ],
          },
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    child: PrayerCard(
                      prayer: chineseEdgePrayer,
                      selectedLanguage: PrayerLanguage.english,
                      compareLanguage: PrayerLanguage.traditionalChinese,
                      initialVersionIndex: 0,
                      onVersionChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('揚'));
        await tester.pumpAndSettle();

        expect(find.byType(PrayerFloatingExplainButton), findsOneWidget);
        expect(find.byType(PrayerVersionHeader), findsOneWidget);

        final cardRect = tester.getRect(find.byType(Card));
        final fabRect = tester.getRect(find.byType(FloatingActionButton));
        expect(fabRect.right, lessThanOrEqualTo(cardRect.right));
      },
    );
  });
}
