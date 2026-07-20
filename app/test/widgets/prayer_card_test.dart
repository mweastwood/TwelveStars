import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import '../test_helper.dart';

void main() {
  group('PrayerCard Widget', () {
    final testPrayer = Prayer.mock(
      id: 'our_father',
      defaultTitle: 'Our Father',
      hasAmen: true,
      translations: {
        PrayerLanguage.english: [
          PrayerTranslation.mock(
            title: 'Our Father',
            subtitle: "The Lord's Prayer (Traditional)",
            text:
                'Our Father, who art in heaven,\nhallowed be thy name;\nthy kingdom come;\nthy will be done\non earth as it is in heaven.\n\nGive us this day our daily bread;\nand forgive us our trespasses\nas we forgive those who trespass against us;\nand lead us not into temptation,\nbut deliver us from evil.',
            sourceName:
                'Compendium of the Catechism of the Catholic Church (Vatican)',
            sourceUrl:
                'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_en.html',
            historyOrigin: 'Gospel of Matthew 6:9–13',
            historyDescription:
                'Taught directly by Jesus to His disciples when they asked Him how to pray. It is the fundamental Christian prayer.',
          ),
        ],
        PrayerLanguage.spanish: [
          PrayerTranslation.mock(
            title: 'Padre Nuestro',
            subtitle: 'El Padre Nuestro',
            text: 'Padre nuestro, que estás en el cielo...',
            sourceName: 'Catecismo',
            sourceUrl: 'https://vatican.va',
          ),
        ],
        PrayerLanguage.traditionalChinese: [
          PrayerTranslation.mock(
            title: '天主經',
            subtitle: 'Lord’s Prayer',
            text:
                '我們的天父，願祢的名受顯揚；願祢的國來臨；願祢的旨意奉行在人間，如同在天上。求祢今天賞給我們日用的食糧；求祢寬恕我們的罪過，如同我們寬恕別人一樣；不要讓我們陷於誘惑；但救我們免於凶惡。',
            sourceName: 'Wikipedia',
            sourceUrl:
                'https://zh.wikipedia.org/zh-hant/%E5%A4%A9%E4%B8%BB%E7%B6%93',
            chineseLines: [
              [
                ChineseChar('我', 'wǒ'),
                ChineseChar('們', 'men'),
                ChineseChar('的', 'de'),
                ChineseChar('天', 'tiān'),
                ChineseChar('父', 'fù'),
                ChineseChar('，', ''),
              ],
              [
                ChineseChar('願', 'yuàn'),
                ChineseChar('祢', 'nǐ'),
                ChineseChar('的', 'de'),
                ChineseChar('名', 'míng'),
                ChineseChar('受', 'shòu'),
                ChineseChar('顯', 'xiǎn'),
                ChineseChar('揚', 'yáng'),
                ChineseChar('；', ''),
              ],
              [
                ChineseChar('願', 'yuàn'),
                ChineseChar('祢', 'nǐ'),
                ChineseChar('的', 'de'),
                ChineseChar('國', 'guó'),
                ChineseChar('來', 'lái'),
                ChineseChar('臨', 'lín'),
                ChineseChar('；', ''),
              ],
              [
                ChineseChar('願', 'yuàn'),
                ChineseChar('祢', 'nǐ'),
                ChineseChar('的', 'de'),
                ChineseChar('旨', 'zhǐ'),
                ChineseChar('意', 'yì'),
                ChineseChar('奉', 'fèng'),
                ChineseChar('行', 'xíng'),
                ChineseChar('在', 'zài'),
                ChineseChar('人', 'rén'),
                ChineseChar('間', 'jiān'),
                ChineseChar('，', ''),
              ],
              [
                ChineseChar('如', 'rú'),
                ChineseChar('同', 'tóng'),
                ChineseChar('在', 'zài'),
                ChineseChar('天', 'tiān'),
                ChineseChar('上', 'shang'),
                ChineseChar('。', ''),
              ],
              [
                ChineseChar('求', 'qiú'),
                ChineseChar('祢', 'nǐ'),
                ChineseChar('今', 'jīn'),
                ChineseChar('天', 'tiān'),
                ChineseChar('賞', 'shǎng'),
                ChineseChar('給', 'gěi'),
                ChineseChar('我', 'wǒ'),
                ChineseChar('們', 'men'),
              ],
              [
                ChineseChar('日', 'rì'),
                ChineseChar('用', 'yòng'),
                ChineseChar('的', 'de'),
                ChineseChar('食', 'shí'),
                ChineseChar('糧', 'liáng'),
                ChineseChar('；', ''),
              ],
              [
                ChineseChar('求', 'qiú'),
                ChineseChar('祢', 'nǐ'),
                ChineseChar('寬', 'kuān'),
                ChineseChar('恕', 'shù'),
                ChineseChar('我', 'wǒ'),
                ChineseChar('們', 'men'),
                ChineseChar('的', 'de'),
                ChineseChar('罪', 'zuì'),
                ChineseChar('過', 'guò'),
                ChineseChar('，', ''),
              ],
              [
                ChineseChar('如', 'rú'),
                ChineseChar('同', 'tóng'),
                ChineseChar('我', 'wǒ'),
                ChineseChar('們', 'men'),
                ChineseChar('寬', 'kuān'),
                ChineseChar('恕', 'shù'),
                ChineseChar('別', 'bié'),
                ChineseChar('人', 'rén'),
                ChineseChar('一', 'yí'),
                ChineseChar('樣', 'yàng'),
                ChineseChar('；', ''),
              ],
              [
                ChineseChar('不', 'bù'),
                ChineseChar('要', 'yào'),
                ChineseChar('讓', 'ràng'),
                ChineseChar('我', 'wǒ'),
                ChineseChar('們', 'men'),
                ChineseChar('陷', 'xiàn'),
                ChineseChar('於', 'yú'),
                ChineseChar('誘', 'yòu'),
                ChineseChar('惑', 'huò'),
                ChineseChar('；', ''),
              ],
              [
                ChineseChar('但', 'dàn'),
                ChineseChar('救', 'jiù'),
                ChineseChar('我', 'wǒ'),
                ChineseChar('們', 'men'),
                ChineseChar('免', 'miǎn'),
                ChineseChar('於', 'yú'),
                ChineseChar('凶', 'xiōng'),
                ChineseChar('惡', 'è'),
                ChineseChar('。', ''),
              ],
            ],
          ),
        ],
      },
    );

    final testPrayerWithTokens = Prayer.mock(
      id: 'our_father_tokens',
      defaultTitle: 'Our Father',
      translations: {
        PrayerLanguage.english: [
          PrayerTranslation.mock(
            title: 'Our Father',
            subtitle: "The Lord's Prayer (Traditional)",
            text: 'Our Father, who art in heaven, hallowed be thy name;',
            tokens: [
              PrayerToken('Our Father, ', null),
              PrayerToken('who art in heaven', 'heaven'),
              PrayerToken(', ', null),
              PrayerToken('hallowed be thy name', 'name'),
              PrayerToken(';', null),
            ],
          ),
        ],
        PrayerLanguage.spanish: [
          PrayerTranslation.mock(
            title: 'Padre Nuestro',
            subtitle: 'El Padre Nuestro',
            text:
                'Padre nuestro, que estás in el cielo, santificado sea tu nombre;',
            tokens: [
              PrayerToken('Padre nuestro, ', null),
              PrayerToken('que estás in el cielo', 'heaven'),
              PrayerToken(', ', null),
              PrayerToken('santificado sea tu nombre', 'name'),
              PrayerToken(';', null),
            ],
          ),
        ],
      },
    );

    testWidgets('renders prayer title, subtitle, and content in English', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: PrayerCard(
                prayer: testPrayer,
                selectedLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.spanish,
                initialVersionIndex: 0,
                onVersionChanged: (_) {},
                onLaunchSource: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Our Father'), findsOneWidget);
      expect(find.textContaining("The Lord's Prayer"), findsOneWidget);
      expect(find.textContaining('who art in heaven'), findsOneWidget);
      expect(
        find.textContaining('Compendium of the Catechism'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping on an annotated phrase in single-language mode opens side-by-side (dual) mode',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SingleChildScrollView(
                child: PrayerCard(
                  prayer: testPrayerWithTokens,
                  selectedLanguage: PrayerLanguage.english,
                  compareLanguage: PrayerLanguage.spanish,
                  initialVersionIndex: 0,
                  onVersionChanged: (_) {},
                  onLaunchSource: (_) {},
                ),
              ),
            ),
          ),
        );

        // Verify that initially side-by-side mode is NOT enabled (only one title is rendered)
        expect(find.text('Our Father'), findsOneWidget);
        expect(find.text('Padre Nuestro'), findsNothing);

        // Find the RichText widget containing the phrase
        final richTextFinder = find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('who art in heaven'),
        );
        final richTextWidget =
            tester.element(richTextFinder).widget as RichText;

        // Traverse the textSpan tree to find the TapGestureRecognizer for the phrase
        TapGestureRecognizer? recognizer;
        richTextWidget.text.visitChildren((span) {
          if (span is TextSpan && span.text == 'who art in heaven') {
            recognizer = span.recognizer as TapGestureRecognizer?;
            return false; // stop visiting
          }
          return true;
        });

        expect(recognizer, isNotNull);
        recognizer!.onTap!();
        await tester.pumpAndSettle();

        // Verify that side-by-side mode is now enabled (both titles are rendered)
        expect(find.text('Our Father'), findsOneWidget);
        expect(find.text('Padre Nuestro'), findsOneWidget);
      },
    );

    testWidgets(
      'renders SizedBox when selected primary language translation is missing',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SingleChildScrollView(
                child: PrayerCard(
                  prayer: testPrayer,
                  selectedLanguage: PrayerLanguage.french,
                  compareLanguage: PrayerLanguage.spanish,
                  initialVersionIndex: 0,
                  onVersionChanged: (_) {},
                  onLaunchSource: (_) {},
                ),
              ),
            ),
          ),
        );

        // Verify that no card content is rendered
        expect(find.text('Our Father'), findsNothing);
        expect(find.text('Padre Nuestro'), findsNothing);
        expect(find.byType(Card), findsNothing);
      },
    );

    testWidgets('hides compare button when comparison translation is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: PrayerCard(
                prayer: testPrayer,
                selectedLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.french,
                initialVersionIndex: 0,
                onVersionChanged: (_) {},
                onLaunchSource: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify that the compare translations button is NOT rendered
      expect(find.byTooltip('Compare Translations'), findsNothing);
    });

    testGoldens('renders English and Traditional Chinese states correctly', (
      tester,
    ) async {
      final mockAi = MockAiService();
      LocalAgentHelper.instance = mockAi;
      mockAi.setMockStatus(AiCoreStatus.available);

      final builder = GoldenBuilder.column()
        ..addScenario(
          'English State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.spanish,
            initialVersionIndex: 0,
            onVersionChanged: (_) {},
            onLaunchSource: (_) {},
          ),
        )
        ..addScenario(
          'Traditional Chinese State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.traditionalChinese,
            compareLanguage: PrayerLanguage.spanish,
            initialVersionIndex: 0,
            onVersionChanged: (_) {},
            onLaunchSource: (_) {},
          ),
        )
        ..addScenario(
          'Side-by-Side Dual Language State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.spanish,
            initialVersionIndex: 0,
            onVersionChanged: (_) {},
            onLaunchSource: (_) {},
          ),
        )
        ..addScenario(
          'Dual Language with Highlighted Phrase and FAB',
          PrayerCard(
            prayer: testPrayerWithTokens,
            selectedLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.spanish,
            initialVersionIndex: 0,
            onVersionChanged: (_) {},
            onLaunchSource: (_) {},
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 3200),
      );

      final compareButtons = find.byTooltip('Compare Translations');

      // Tap the split button in the third scenario (Side-by-Side State) to enable dual mode
      await tester.tap(compareButtons.at(2));
      await tester.pumpAndSettle();

      // Tap the split button in the fourth scenario to enable dual mode
      await tester.tap(compareButtons.at(3));
      await tester.pumpAndSettle();

      // Find the RichText widget inside the fourth scenario containing the phrase
      final richTextFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('who art in heaven'),
      );
      final richTextWidget =
          tester.element(richTextFinder.last).widget as RichText;

      TapGestureRecognizer? recognizer;
      richTextWidget.text.visitChildren((span) {
        if (span is TextSpan && span.text == 'who art in heaven') {
          recognizer = span.recognizer as TapGestureRecognizer?;
          return false;
        }
        return true;
      });

      expect(recognizer, isNotNull);
      recognizer!.onTap!();
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'prayer_card_golden');
    });

    testWidgets(
      'translation explanation FAB visibility depends on AI service availability',
      (tester) async {
        final mockAi = MockAiService();
        LocalAgentHelper.instance = mockAi;

        // 1. Test when AI is NOT available
        mockAi.setMockStatus(AiCoreStatus.unavailable);

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SingleChildScrollView(
                child: PrayerCard(
                  prayer: testPrayerWithTokens,
                  selectedLanguage: PrayerLanguage.english,
                  compareLanguage: PrayerLanguage.spanish,
                  initialVersionIndex: 0,
                  onVersionChanged: (_) {},
                  onLaunchSource: (_) {},
                ),
              ),
            ),
          ),
        );

        // Enable side-by-side mode first
        final compareButtons = find.byTooltip('Compare Translations');
        await tester.tap(compareButtons.first);
        await tester.pumpAndSettle();

        // Find the RichText widget containing the phrase
        final richTextFinder = find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('who art in heaven'),
        );
        final richTextWidget =
            tester.element(richTextFinder).widget as RichText;

        TapGestureRecognizer? recognizer;
        richTextWidget.text.visitChildren((span) {
          if (span is TextSpan && span.text == 'who art in heaven') {
            recognizer = span.recognizer as TapGestureRecognizer?;
            return false;
          }
          return true;
        });

        expect(recognizer, isNotNull);
        recognizer!.onTap!();
        await tester.pumpAndSettle();

        // FAB should NOT be shown since AI is unavailable
        expect(find.byIcon(Icons.auto_awesome), findsNothing);

        // 2. Test when AI IS available
        mockAi.setMockStatus(AiCoreStatus.available);

        // Retap to refresh the state and run the check
        recognizer!.onTap!(); // untap
        await tester.pumpAndSettle();
        recognizer!.onTap!(); // retap
        await tester.pumpAndSettle();

        // FAB should be shown now!
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

        // 3. Test tapping the FAB opens the explainer sheet
        await tester.tap(find.byIcon(Icons.auto_awesome));
        await tester.pumpAndSettle();

        // Check if bottom sheet is shown with the correct title
        expect(find.text('Translation Explainer'), findsOneWidget);
        expect(find.text('who art in heaven'), findsWidgets);
        expect(find.text('que estás in el cielo'), findsWidgets);
      },
    );

    testGoldens('renders Translation Explainer bottom sheet correctly', (
      tester,
    ) async {
      final mockAi = MockAiService();
      LocalAgentHelper.instance = mockAi;
      mockAi.setMockStatus(AiCoreStatus.available);

      await tester.pumpWidgetBuilder(
        buildTestableWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: PrayerCard(
                prayer: testPrayerWithTokens,
                selectedLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.spanish,
                initialVersionIndex: 0,
                onVersionChanged: (_) {},
                onLaunchSource: (_) {},
              ),
            ),
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 800),
      );

      // Enable side-by-side mode
      final compareButtons = find.byTooltip('Compare Translations');
      await tester.tap(compareButtons.first);
      await tester.pumpAndSettle();

      // Find the RichText widget containing the phrase
      final richTextFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('who art in heaven'),
      );
      final richTextWidget = tester.element(richTextFinder).widget as RichText;

      TapGestureRecognizer? recognizer;
      richTextWidget.text.visitChildren((span) {
        if (span is TextSpan && span.text == 'who art in heaven') {
          recognizer = span.recognizer as TapGestureRecognizer?;
          return false;
        }
        return true;
      });

      expect(recognizer, isNotNull);
      recognizer!.onTap!();
      await tester.pumpAndSettle();

      // Tap the FAB to open the bottom sheet
      final fabFinder = find.byIcon(Icons.auto_awesome);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);

      // Pump and settle to let the sheet animate up and the mock response load completely
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'translation_explainer_sheet_golden');
    });

    testGoldens('renders copyright disclaimer correctly', (tester) async {
      final mockAi = MockAiService();
      LocalAgentHelper.instance = mockAi;
      mockAi.setMockStatus(AiCoreStatus.available);

      final prayerWithCopyright = Prayer.mock(
        id: 'nicene_creed',
        defaultTitle: 'Nicene Creed',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Nicene Creed',
              subtitle: 'Symbolum Nicaenum',
              text:
                  'I believe in one God, the Father almighty, maker of heaven and earth...',
              copyright:
                  'English translation of the Nicene Creed © 2010, ICEL. All rights reserved.',
            ),
          ],
        },
      );

      final builder = GoldenBuilder.column()
        ..addScenario(
          'English Liturgical State with Copyright Disclaimer',
          PrayerCard(
            prayer: prayerWithCopyright,
            selectedLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.spanish,
            initialVersionIndex: 0,
            onVersionChanged: (_) {},
            onLaunchSource: (_) {},
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 400),
      );

      await screenMatchesGolden(tester, 'prayer_card_copyright_golden');
    });
  });
}
