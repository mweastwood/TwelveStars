import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import '../test_helper.dart';

void main() {
  group('PrayerCard Widget', () {
    final testPrayer = Prayer.mock(
      id: 'our_father',
      defaultTitle: 'Our Father',
      translations: {
        PrayerLanguage.english: [
          PrayerTranslation.mock(
            title: 'Our Father',
            subtitle: "The Lord's Prayer (Traditional)",
            text:
                'Our Father, who art in heaven,\nhallowed be thy name;\nthy kingdom come;\nthy will be done\non earth as it is in heaven.\n\nGive us this day our daily bread;\nand forgive us our trespasses\nas we forgive those who trespass against us;\nand lead us not into temptation,\nbut deliver us from evil.\n\nAmen.',
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
                '我們的天父，願祢的名受顯揚；願祢的國來臨；願祢的旨意奉行在人間，如同在天上。求祢今天賞給我們日用的食糧；求祢寬恕我們的罪過，如同我們寬恕別人一樣；不要讓我們陷於誘惑；但救我們免於凶惡。亞孟。',
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
              [
                ChineseChar('亞', 'yà'),
                ChineseChar('孟', 'mèng'),
                ChineseChar('。', ''),
              ],
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
        final testPrayerWithTokens = Prayer.mock(
          id: 'our_father',
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

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SingleChildScrollView(
                child: PrayerCard(
                  prayer: testPrayerWithTokens,
                  selectedLanguage: PrayerLanguage.english,
                  compareLanguage: PrayerLanguage.spanish,
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

    testGoldens('renders English and Traditional Chinese states correctly', (
      tester,
    ) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'English State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.spanish,
            onLaunchSource: (_) {},
          ),
        )
        ..addScenario(
          'Traditional Chinese State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.traditionalChinese,
            compareLanguage: PrayerLanguage.spanish,
            onLaunchSource: (_) {},
          ),
        )
        ..addScenario(
          'Side-by-Side Dual Language State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.spanish,
            onLaunchSource: (_) {},
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 2600),
      );

      // Tap the split button in the third scenario (Side-by-Side State) to enable dual mode
      final compareButtons = find.byTooltip('Compare Translations');
      await tester.tap(compareButtons.last);
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'prayer_card_golden');
    });
  });
}
