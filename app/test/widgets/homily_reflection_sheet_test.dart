import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/homily_service.dart';
import 'package:twelve_stars/widgets/homily_reflection_sheet.dart';
import '../test_helper.dart';

class TestAiService implements AiService {
  AiCoreStatus status = AiCoreStatus.available;
  int checkStatusCalls = 0;
  int triggerDownloadCalls = 0;
  int countTokensCalls = 0;
  int generateContentCalls = 0;
  String? generatedText =
      '## Reflection\n\nToday\'s readings invite us to place our trust in God.';
  bool shouldThrowOnGenerate = false;

  @override
  Future<AiCoreStatus> checkStatus() async {
    checkStatusCalls++;
    return status;
  }

  @override
  Future<void> triggerDownload() async {
    triggerDownloadCalls++;
    status = AiCoreStatus.available;
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
    return AiResponse(text: generatedText ?? '', isTruncated: false);
  }
}

void main() {
  late TestAiService mockAi;

  setUp(() {
    mockAi = TestAiService();
    LocalAgentHelper.instance = mockAi;
  });

  const testReadingsData = [
    HomilyReadingData(
      readingType: 'first',
      citation: '1 Kgs 19:9a, 11-13a',
      text: 'First reading text',
    ),
    HomilyReadingData(
      readingType: 'psalm',
      citation: 'Ps 85:9-14',
      text: 'Psalm text',
    ),
    HomilyReadingData(
      readingType: 'gospel',
      citation: 'Mt 14:22-33',
      text: 'Gospel text',
    ),
  ];

  testWidgets('renders reflection successfully when AICore is available', (
    tester,
  ) async {
    mockAi.status = AiCoreStatus.available;

    await tester.pumpWidget(
      buildTestableWidget(
        child: const Scaffold(
          body: HomilyReflectionSheet(
            celebrationTitle: '19th Sunday in Ordinary Time',
            readings: [],
            preloadedReadingsData: testReadingsData,
          ),
        ),
      ),
    );

    // Initial pump shows loading
    await tester.pump();
    // Finish async loading and reflection generation
    await tester.pumpAndSettle();

    expect(find.text('Homily Reflection'), findsOneWidget);
    expect(find.text('19th Sunday in Ordinary Time'), findsNWidgets(2));
    expect(
      find.text('1 Kgs 19:9a, 11-13a • Ps 85:9-14 • Mt 14:22-33'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Today\'s readings invite us to place our trust in God.',
      ),
      findsOneWidget,
    );
    expect(find.text('Copy reflection'), findsOneWidget);
  });

  testWidgets(
    'copies reflection text to clipboard when copy button is pressed',
    (tester) async {
      final List<Map<String, dynamic>> clipboardLog = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(methodCall.arguments as Map<String, dynamic>);
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {
              'text': clipboardLog.isNotEmpty ? clipboardLog.last['text'] : '',
            };
          }
          return null;
        },
      );

      mockAi.status = AiCoreStatus.available;

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: HomilyReflectionSheet(
              celebrationTitle: '19th Sunday in Ordinary Time',
              readings: [],
              preloadedReadingsData: testReadingsData,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.widgetWithText(OutlinedButton, 'Copy reflection');
      expect(copyButton, findsOneWidget);

      await tester.ensureVisible(copyButton);
      await tester.tap(copyButton);
      await tester.pump();
      await tester.pump();

      expect(find.text('Copied'), findsOneWidget);
      expect(find.text('Reflection copied to clipboard'), findsOneWidget);
      expect(clipboardLog.isNotEmpty, isTrue);
      expect(
        clipboardLog.last['text'],
        contains('Today\'s readings invite us to place our trust in God.'),
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('renders unavailable status when AICore is unavailable', (
    tester,
  ) async {
    mockAi.status = AiCoreStatus.unavailable;

    await tester.pumpWidget(
      buildTestableWidget(
        child: const Scaffold(
          body: HomilyReflectionSheet(
            celebrationTitle: 'Daily Mass',
            readings: [],
            preloadedReadingsData: testReadingsData,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('AI Core Unavailable'), findsOneWidget);
    expect(
      find.textContaining(
        'On-device AI features (Gemini Nano) are not supported',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders downloadable status and triggers download when button pressed',
    (tester) async {
      mockAi.status = AiCoreStatus.downloadable;

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: HomilyReflectionSheet(
              celebrationTitle: 'Daily Mass',
              readings: [],
              preloadedReadingsData: testReadingsData,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Download AI Model'), findsOneWidget);
      final downloadButton = find.widgetWithText(
        ElevatedButton,
        'Download now',
      );
      expect(downloadButton, findsOneWidget);

      await tester.tap(downloadButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(mockAi.triggerDownloadCalls, 1);
    },
  );

  testWidgets('renders error state and retries on button tap', (tester) async {
    mockAi.status = AiCoreStatus.available;
    mockAi.shouldThrowOnGenerate = true;

    await tester.pumpWidget(
      buildTestableWidget(
        child: const Scaffold(
          body: HomilyReflectionSheet(
            celebrationTitle: 'Daily Mass',
            readings: [],
            preloadedReadingsData: testReadingsData,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Failed to generate homily reflection'), findsOneWidget);
    final retryButton = find.widgetWithText(ElevatedButton, 'Retry');
    expect(retryButton, findsOneWidget);

    // Now fix error and tap retry
    mockAi.shouldThrowOnGenerate = false;
    await tester.tap(retryButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Failed to generate homily reflection'), findsNothing);
    expect(
      find.textContaining(
        'Today\'s readings invite us to place our trust in God.',
      ),
      findsOneWidget,
    );
  });
}
