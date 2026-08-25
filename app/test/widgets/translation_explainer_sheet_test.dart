import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/translation_explainer_sheet.dart';
import '../test_helper.dart';

class TestAiService implements AiService {
  AiCoreStatus status = AiCoreStatus.available;
  int checkStatusCalls = 0;
  int triggerDownloadCalls = 0;
  int countTokensCalls = 0;
  int generateContentCalls = 0;
  String? generatedText =
      '### Translation Breakdown\n\n'
      '* **qui**: relative pronoun (*who*)\n'
      '* **es**: second-person singular present of *esse* (*art / are*)\n'
      '* **in caelis**: prepositional phrase (*in heaven / the heavens*)';
  bool shouldThrowOnGenerate = false;
  bool shouldThrowOnCheckStatus = false;
  VoidCallback? onTriggerDownload;
  Completer<String?>? generateCompleter;

  @override
  Future<AiCoreStatus> checkStatus() async {
    checkStatusCalls++;
    if (shouldThrowOnCheckStatus) {
      throw Exception('Simulated checkStatus failure');
    }
    return status;
  }

  @override
  Future<void> triggerDownload() async {
    triggerDownloadCalls++;
    if (onTriggerDownload != null) {
      onTriggerDownload!();
    } else {
      status = AiCoreStatus.available;
    }
  }

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {}

  @override
  Future<int> countTokens({
    required String prompt,
    Uint8List? imageBytes,
  }) async {
    countTokensCalls++;
    return 100;
  }

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    generateContentCalls++;
    if (shouldThrowOnGenerate) {
      throw Exception('Simulated AI model generation failure');
    }
    if (generateCompleter != null) {
      return generateCompleter!.future;
    }
    return generatedText;
  }

  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    generateContentCalls++;
    if (shouldThrowOnGenerate) {
      throw Exception('Simulated AI model generation failure');
    }
    if (generateCompleter != null) {
      final res = await generateCompleter!.future;
      return res == null ? null : AiResponse(text: res, isTruncated: false);
    }
    return generatedText == null
        ? null
        : AiResponse(text: generatedText!, isTruncated: false);
  }
}

void main() {
  late TestAiService mockAi;

  setUp(() {
    mockAi = TestAiService();
    LocalAgentHelper.instance = mockAi;
  });

  tearDown(() {
    LocalAgentHelper.instance = null;
  });

  const testOriginalPhrase = 'qui es in caelis';
  const testTranslatedPhrase = 'who art in heaven';
  const testOriginalContext =
      'Pater noster, qui es in caelis, sanctificetur nomen tuum.';
  const testTranslatedContext =
      'Our Father, who art in heaven, hallowed be thy name.';
  const testOriginalLang = 'Latin';
  const testTranslatedLang = 'English';

  Widget buildTestWidget({
    String originalPhrase = testOriginalPhrase,
    String translatedPhrase = testTranslatedPhrase,
    String originalContext = testOriginalContext,
    String translatedContext = testTranslatedContext,
    String originalLang = testOriginalLang,
    String translatedLang = testTranslatedLang,
  }) {
    return buildTestableWidget(
      child: Scaffold(
        body: TranslationExplainerSheet(
          originalPhrase: originalPhrase,
          translatedPhrase: translatedPhrase,
          originalContext: originalContext,
          translatedContext: translatedContext,
          originalLang: originalLang,
          translatedLang: translatedLang,
        ),
      ),
    );
  }

  group('TranslationExplainerSheet Widget Tests', () {
    testWidgets(
      'renders unavailable state when AI Core is not supported on device',
      (tester) async {
        mockAi.status = AiCoreStatus.unavailable;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Translation Explainer'), findsOneWidget);
        expect(find.text('Latin ➜ English'), findsOneWidget);
        expect(find.text('Latin:'), findsOneWidget);
        expect(find.text('qui es in caelis'), findsOneWidget);
        expect(find.text('English:'), findsOneWidget);
        expect(find.text('who art in heaven'), findsOneWidget);

        expect(find.text('AI Core Unavailable'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(
          find.textContaining(
            'On-device AI features (Gemini Nano) are not supported on this device.',
          ),
          findsOneWidget,
        );
        expect(find.byType(ElevatedButton), findsNothing);
      },
    );

    testWidgets(
      'renders downloadable state and triggers download when button is tapped',
      (tester) async {
        mockAi.status = AiCoreStatus.downloadable;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Download AI Model'), findsOneWidget);
        expect(
          find.byIcon(Icons.download_for_offline_outlined),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'The on-device Gemini Nano model needs to be downloaded',
          ),
          findsOneWidget,
        );

        final downloadButton = find.widgetWithText(
          ElevatedButton,
          'Download now',
        );
        expect(downloadButton, findsOneWidget);

        await tester.tap(downloadButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(mockAi.triggerDownloadCalls, 1);
        expect(find.text('Download AI Model'), findsNothing);
        expect(find.textContaining('Translation Breakdown'), findsOneWidget);
      },
    );

    testWidgets(
      'renders downloading message when model download is in progress',
      (tester) async {
        mockAi.status = AiCoreStatus.downloadable;
        mockAi.onTriggerDownload = () {
          mockAi.status = AiCoreStatus.downloading;
        };

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final downloadButton = find.widgetWithText(
          ElevatedButton,
          'Download now',
        );
        expect(downloadButton, findsOneWidget);

        await tester.tap(downloadButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.text('Downloading Gemini Nano model weights (~30MB)...'),
          findsOneWidget,
        );

        // Transition to available
        mockAi.status = AiCoreStatus.available;
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.textContaining('Translation Breakdown'), findsOneWidget);
      },
    );

    testWidgets(
      'renders available state with loading indicator and markdown explanation',
      (tester) async {
        mockAi.status = AiCoreStatus.available;
        mockAi.generateCompleter = Completer<String?>();

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Check loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Running AI analysis locally...'), findsOneWidget);

        // Complete generation and settle
        mockAi.generateCompleter!.complete(mockAi.generatedText);
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Translation Explainer'), findsOneWidget);
        expect(find.text('Latin ➜ English'), findsOneWidget);
        expect(find.text('Latin:'), findsOneWidget);
        expect(find.text('qui es in caelis'), findsOneWidget);
        expect(find.text('English:'), findsOneWidget);
        expect(find.text('who art in heaven'), findsOneWidget);
        expect(find.textContaining('Translation Breakdown'), findsOneWidget);
        expect(find.textContaining('relative pronoun'), findsOneWidget);
        expect(mockAi.generateContentCalls, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'renders error state on generation failure and allows retrying',
      (tester) async {
        mockAi.status = AiCoreStatus.available;
        mockAi.shouldThrowOnGenerate = true;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Failed to generate explanation'), findsOneWidget);
        expect(
          find.textContaining('Simulated AI model generation failure'),
          findsOneWidget,
        );

        final retryButton = find.widgetWithText(ElevatedButton, 'Retry');
        expect(retryButton, findsOneWidget);

        // Fix failure condition and retry
        mockAi.shouldThrowOnGenerate = false;
        await tester.tap(retryButton);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Failed to generate explanation'), findsNothing);
        expect(find.textContaining('Translation Breakdown'), findsOneWidget);
      },
    );

    testWidgets(
      'renders error state on status check failure and recovers on retry',
      (tester) async {
        mockAi.shouldThrowOnCheckStatus = true;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Failed to generate explanation'), findsOneWidget);
        expect(
          find.textContaining('Error initializing AI service'),
          findsOneWidget,
        );

        final retryButton = find.widgetWithText(ElevatedButton, 'Retry');
        expect(retryButton, findsOneWidget);

        // Fix status check failure and retry
        mockAi.shouldThrowOnCheckStatus = false;
        await tester.tap(retryButton);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Failed to generate explanation'), findsNothing);
        expect(find.textContaining('Translation Breakdown'), findsOneWidget);
      },
    );

    testWidgets('dismisses modal bottom sheet when close button is tapped', (
      tester,
    ) async {
      mockAi.status = AiCoreStatus.available;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => const TranslationExplainerSheet(
                        originalPhrase: testOriginalPhrase,
                        translatedPhrase: testTranslatedPhrase,
                        originalContext: testOriginalContext,
                        translatedContext: testTranslatedContext,
                        originalLang: testOriginalLang,
                        translatedLang: testTranslatedLang,
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Translation Explainer'), findsNothing);

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Translation Explainer'), findsOneWidget);

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Translation Explainer'), findsNothing);
    });

    testWidgets('renders fallback message when response is null or empty', (
      tester,
    ) async {
      mockAi.status = AiCoreStatus.available;
      mockAi.generatedText = null;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No explanation generated.'), findsOneWidget);
    });

    group('Golden Tests', () {
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
                  'Padre nuestro, que estás in el cielo, santificado sea tu '
                  'nombre;',
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

      testGoldens('matches golden snapshot for Translation Explainer sheet', (
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
                ),
              ),
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(450, 800),
        );

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

        final fabFinder = find.byIcon(Icons.auto_awesome);
        expect(fabFinder, findsOneWidget);
        await tester.tap(fabFinder);

        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'translation_explainer_sheet_golden');
      });
    });
  });
}
