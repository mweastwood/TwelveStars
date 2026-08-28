import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/homily_service.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';

class MockAiServiceForHomily implements AiService {
  AiCoreStatus mockStatus = AiCoreStatus.available;
  int checkStatusCallCount = 0;
  int triggerDownloadCallCount = 0;
  int countTokensCallCount = 0;
  int generateContentCallCount = 0;
  String lastPromptPassed = '';
  int mockTokenCount = 500;
  bool shouldThrowOnCountTokens = false;
  String mockResponseText =
      'This is a Catholic homily reflection connecting the Old Testament typology to Christ in the Gospel.';

  @override
  Future<AiCoreStatus> checkStatus() async {
    checkStatusCallCount++;
    return mockStatus;
  }

  @override
  Future<void> triggerDownload() async {
    triggerDownloadCallCount++;
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
    countTokensCallCount++;
    lastPromptPassed = prompt;
    if (shouldThrowOnCountTokens) {
      throw Exception('AICore model not loaded');
    }
    return mockTokenCount;
  }

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    generateContentCallCount++;
    lastPromptPassed = prompt;
    return mockResponseText;
  }

  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    generateContentCallCount++;
    lastPromptPassed = prompt;
    return AiResponse(text: mockResponseText, isTruncated: false);
  }
}

void main() {
  group('HomilyReadingData', () {
    test('formats type headers correctly', () {
      const first = HomilyReadingData(
        readingType: 'first',
        citation: 'Gen 1:1-5',
        text: 'In the beginning...',
      );
      expect(first.typeHeader, 'First Reading');

      const psalm = HomilyReadingData(
        readingType: 'psalm',
        citation: 'Ps 23:1-6',
        text: 'The Lord is my shepherd...',
      );
      expect(psalm.typeHeader, 'Responsorial Psalm');

      const second = HomilyReadingData(
        readingType: 'second',
        citation: 'Rom 8:1-4',
        text: 'There is now no condemnation...',
      );
      expect(second.typeHeader, 'Second Reading');

      const gospel = HomilyReadingData(
        readingType: 'gospel',
        citation: 'Jn 1:1-5',
        text: 'In the beginning was the Word...',
      );
      expect(gospel.typeHeader, 'Gospel');

      const custom = HomilyReadingData(
        readingType: 'other',
        citation: 'Sir 1:1',
        text: 'All wisdom comes from the Lord...',
      );
      expect(custom.typeHeader, 'Reading');
    });
  });

  group('HomilyService.buildPrompt', () {
    test(
      'builds standard weekday prompt with theological hermeneutics instructions',
      () {
        final readings = [
          const HomilyReadingData(
            readingType: 'gospel',
            citation: 'Mt 14:22-33',
            text:
                'Jesus made the disciples get into the boat and go before him.',
          ),
          const HomilyReadingData(
            readingType: 'first',
            citation: '1 Kgs 19:9a, 11-13a',
            text: 'There came a sound of a gentle breeze.',
          ),
          const HomilyReadingData(
            readingType: 'psalm',
            citation: 'Ps 85:9-14',
            text:
                'Lord, let us see your kindness, and grant us your salvation.',
          ),
        ];

        final prompt = HomilyService.buildPrompt(readings);

        expect(
          prompt,
          contains(
            "You are a Catholic pastor and theologian delivering a brief homily reflection",
          ),
        );
        expect(
          prompt,
          contains('[First Reading]: 1 Kgs 19:9a, 11-13a - There came a sound'),
        );
        expect(
          prompt,
          contains('[Responsorial Psalm]: Ps 85:9-14 - Lord, let us see'),
        );
        expect(
          prompt,
          contains('[Gospel]: Mt 14:22-33 - Jesus made the disciples'),
        );
        expect(prompt, isNot(contains('[Second Reading]')));
        expect(
          prompt,
          contains(
            '1. Draws out the Catholic theological and typological connections between the readings',
          ),
        );
        expect(
          prompt,
          contains(
            '2. Offers a practical application for Catholic Christian daily spiritual life.',
          ),
        );

        // Verify correct sorting order: First reading appears before Psalm, Psalm before Gospel
        final firstIdx = prompt.indexOf('[First Reading]');
        final psalmIdx = prompt.indexOf('[Responsorial Psalm]');
        final gospelIdx = prompt.indexOf('[Gospel]');
        expect(firstIdx < psalmIdx, isTrue);
        expect(psalmIdx < gospelIdx, isTrue);
      },
    );

    test('builds Sunday prompt with Second Reading included in order', () {
      final readings = [
        const HomilyReadingData(
          readingType: 'gospel',
          citation: 'Mt 14:22-33',
          text: 'Gospel text',
        ),
        const HomilyReadingData(
          readingType: 'second',
          citation: 'Rom 9:1-5',
          text: 'Second reading text',
        ),
        const HomilyReadingData(
          readingType: 'psalm',
          citation: 'Ps 85',
          text: 'Psalm text',
        ),
        const HomilyReadingData(
          readingType: 'first',
          citation: '1 Kgs 19',
          text: 'First reading text',
        ),
      ];

      final prompt = HomilyService.buildPrompt(readings);

      final firstIdx = prompt.indexOf('[First Reading]');
      final psalmIdx = prompt.indexOf('[Responsorial Psalm]');
      final secondIdx = prompt.indexOf('[Second Reading]');
      final gospelIdx = prompt.indexOf('[Gospel]');

      expect(firstIdx < psalmIdx, isTrue);
      expect(psalmIdx < secondIdx, isTrue);
      expect(secondIdx < gospelIdx, isTrue);
    });

    test('compresses psalm and second reading when requested', () {
      final longPsalmText = 'A ' * 300;
      final longSecondText = 'B ' * 400;

      final readings = [
        HomilyReadingData(
          readingType: 'psalm',
          citation: 'Ps 85',
          text: longPsalmText,
        ),
        HomilyReadingData(
          readingType: 'second',
          citation: 'Rom 9',
          text: longSecondText,
        ),
      ];

      final uncompressedPrompt = HomilyService.buildPrompt(readings);
      expect(uncompressedPrompt, contains(longPsalmText.trim()));

      final compressedPsalmPrompt = HomilyService.buildPrompt(
        readings,
        compressPsalm: true,
      );
      expect(compressedPsalmPrompt, contains('[excerpt]'));

      final compressedBothPrompt = HomilyService.buildPrompt(
        readings,
        compressPsalm: true,
        compressSecondReading: true,
      );
      expect(compressedBothPrompt, contains('[excerpt]'));
    });
  });

  group('HomilyService.preparePromptWithTokenBudget', () {
    test('returns full prompt when under token ceiling', () async {
      final mockAi = MockAiServiceForHomily();
      mockAi.mockTokenCount = 1000;

      final readings = [
        const HomilyReadingData(
          readingType: 'first',
          citation: 'Gen 1',
          text: 'Short text',
        ),
      ];

      final prompt = await HomilyService.preparePromptWithTokenBudget(
        readings,
        aiService: mockAi,
        tokenCeiling: 2048,
      );

      expect(prompt, contains('Short text'));
      expect(mockAi.countTokensCallCount, 1);
    });

    test('dynamically compresses when token count exceeds budget', () async {
      final mockAi = MockAiServiceForHomily();
      // First count exceeds budget (3000 > 2000), but compressed is under budget (1500)
      mockAi.countTokensCallCount = 0;

      final readings = [
        const HomilyReadingData(
          readingType: 'first',
          citation: '1 Kgs 19',
          text: 'First reading content',
        ),
        HomilyReadingData(
          readingType: 'psalm',
          citation: 'Ps 85',
          text: 'Psalm verse content ' * 50,
        ),
        HomilyReadingData(
          readingType: 'second',
          citation: 'Rom 9',
          text: 'Second reading content ' * 50,
        ),
        const HomilyReadingData(
          readingType: 'gospel',
          citation: 'Mt 14',
          text: 'Gospel content',
        ),
      ];

      final prompt = await HomilyService.preparePromptWithTokenBudget(
        readings,
        aiService: mockAi,
        tokenCeiling: 100, // force compression
      );

      expect(prompt, contains('[excerpt]'));
    });

    test(
      'returns full prompt without compression when countTokens returns 0 and heuristic is under ceiling',
      () async {
        final mockAi = MockAiServiceForHomily();
        mockAi.mockTokenCount = 0;

        final readings = [
          const HomilyReadingData(
            readingType: 'first',
            citation: 'Gen 1',
            text: 'First reading text',
          ),
          const HomilyReadingData(
            readingType: 'psalm',
            citation: 'Ps 23',
            text: 'The Lord is my shepherd; there is nothing I lack.',
          ),
          const HomilyReadingData(
            readingType: 'second',
            citation: 'Rom 8',
            text: 'If God is for us, who can be against us?',
          ),
          const HomilyReadingData(
            readingType: 'gospel',
            citation: 'Jn 1',
            text: 'In the beginning was the Word.',
          ),
        ];

        final prompt = await HomilyService.preparePromptWithTokenBudget(
          readings,
          aiService: mockAi,
          tokenCeiling: 2048,
        );

        expect(prompt, contains('The Lord is my shepherd'));
        expect(prompt, contains('If God is for us'));
        expect(prompt, isNot(contains('[excerpt]')));
        expect(mockAi.countTokensCallCount, 1);
      },
    );

    test(
      'returns full prompt without compression when countTokens throws exception and heuristic is under ceiling',
      () async {
        final mockAi = MockAiServiceForHomily();
        mockAi.shouldThrowOnCountTokens = true;

        final readings = [
          const HomilyReadingData(
            readingType: 'first',
            citation: 'Gen 1',
            text: 'First reading text',
          ),
          const HomilyReadingData(
            readingType: 'psalm',
            citation: 'Ps 23',
            text: 'The Lord is my shepherd; there is nothing I lack.',
          ),
          const HomilyReadingData(
            readingType: 'second',
            citation: 'Rom 8',
            text: 'If God is for us, who can be against us?',
          ),
          const HomilyReadingData(
            readingType: 'gospel',
            citation: 'Jn 1',
            text: 'In the beginning was the Word.',
          ),
        ];

        final prompt = await HomilyService.preparePromptWithTokenBudget(
          readings,
          aiService: mockAi,
          tokenCeiling: 2048,
        );

        expect(prompt, contains('The Lord is my shepherd'));
        expect(prompt, contains('If God is for us'));
        expect(prompt, isNot(contains('[excerpt]')));
        expect(mockAi.countTokensCallCount, 1);
      },
    );

    test(
      'applies compression using heuristic token estimation when countTokens returns 0 but prompt is oversized',
      () async {
        final mockAi = MockAiServiceForHomily();
        mockAi.mockTokenCount = 0;

        final readings = [
          const HomilyReadingData(
            readingType: 'first',
            citation: '1 Kgs 19',
            text: 'First reading content',
          ),
          HomilyReadingData(
            readingType: 'psalm',
            citation: 'Ps 85',
            text: 'Psalm verse content ' * 50,
          ),
          HomilyReadingData(
            readingType: 'second',
            citation: 'Rom 9',
            text: 'Second reading content ' * 50,
          ),
          const HomilyReadingData(
            readingType: 'gospel',
            citation: 'Mt 14',
            text: 'Gospel content',
          ),
        ];

        final prompt = await HomilyService.preparePromptWithTokenBudget(
          readings,
          aiService: mockAi,
          tokenCeiling: 100, // force compression via heuristic token estimate
        );

        expect(prompt, contains('[excerpt]'));
      },
    );

    test(
      'applies compression using heuristic token estimation when countTokens throws exception and prompt is oversized',
      () async {
        final mockAi = MockAiServiceForHomily();
        mockAi.shouldThrowOnCountTokens = true;

        final readings = [
          const HomilyReadingData(
            readingType: 'first',
            citation: '1 Kgs 19',
            text: 'First reading content',
          ),
          HomilyReadingData(
            readingType: 'psalm',
            citation: 'Ps 85',
            text: 'Psalm verse content ' * 50,
          ),
          HomilyReadingData(
            readingType: 'second',
            citation: 'Rom 9',
            text: 'Second reading content ' * 50,
          ),
          const HomilyReadingData(
            readingType: 'gospel',
            citation: 'Mt 14',
            text: 'Gospel content',
          ),
        ];

        final prompt = await HomilyService.preparePromptWithTokenBudget(
          readings,
          aiService: mockAi,
          tokenCeiling: 100, // force compression via heuristic token estimate
        );

        expect(prompt, contains('[excerpt]'));
      },
    );
  });

  group('HomilyService.generateReflection', () {
    test('calls generateContentWithContinuation with valid response', () async {
      final mockAi = MockAiServiceForHomily();
      LocalAgentHelper.instance = mockAi;

      final readings = [
        const HomilyReadingData(
          readingType: 'first',
          citation: 'Gen 1:1',
          text: 'In the beginning',
        ),
      ];

      final result = await HomilyService.generateReflection(
        readings,
        aiService: mockAi,
      );

      expect(result, isNotNull);
      expect(result, contains('This is a Catholic homily reflection'));
    });
  });

  group('HomilyService.fetchReadingsData', () {
    late BibleDatabase testDb;

    setUp(() async {
      testDb = BibleDatabase(NativeDatabase.memory());
      BibleDatabaseHelper.db = testDb;
      await testDb.ensurePopulated();

      // Seed a test verse
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVersesCompanion.insert(
              translationCode: 'drc',
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created heaven, and earth.',
            ),
          );

      await PrayerDatabase.saveSettings(
        UserSettings(
          id: 1,
          primaryLanguageCode: 'english',
          compareLanguageCode: 'latin',
          primaryBibleTranslation: 'drc',
          compareBibleTranslation: 'vul',
          preferredVersions: null,
          hapticsEnabled: true,
          appThemeModeCode: 'marian_blue',
          sundayNotificationsEnabled: true,
          showBibleTranslationSelectors: false,
        ),
      );
    });

    test('fetches verse text correctly for a reading', () async {
      final reading = LectionaryReading(
        id: 1,
        readingKey: 'test_reading',
        readingType: 'first',
        bookNumber: 1,
        bookName: 'Genesis',
        chapter: 1,
        verseRange: '1',
        citation: 'Gen 1:1',
      );

      final data = await HomilyService.fetchReadingsData([
        reading,
      ], translation: 'drc');
      expect(data.length, 1);
      expect(data.first.readingType, 'first');
      expect(data.first.citation, 'Gen 1:1');
      expect(
        data.first.text,
        'In the beginning God created heaven, and earth.',
      );
    });
  });
}
