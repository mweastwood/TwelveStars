import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';

class FakeAiService implements AiService {
  int checkStatusCount = 0;
  int triggerDownloadCount = 0;
  int setModelConfigCount = 0;
  int generateContentCount = 0;
  AiCoreStatus mockStatus = AiCoreStatus.available;

  @override
  Future<AiCoreStatus> checkStatus() async {
    checkStatusCount++;
    return mockStatus;
  }

  @override
  Future<void> triggerDownload() async {
    triggerDownloadCount++;
  }

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {
    setModelConfigCount++;
  }

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    generateContentCount++;
    return 'mock response';
  }

  @override
  Future<int> countTokens({
    required String prompt,
    Uint8List? imageBytes,
  }) async {
    return 0;
  }

  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    return AiResponse(text: 'mock response', isTruncated: false);
  }
}

void main() {
  group('CachingAiService', () {
    test(
      'checkStatus caches the result and only calls the delegate once',
      () async {
        final fake = FakeAiService();
        final cachingService = CachingAiService(fake);

        expect(fake.checkStatusCount, 0);

        final status1 = await cachingService.checkStatus();
        expect(status1, AiCoreStatus.available);
        expect(fake.checkStatusCount, 1);

        final status2 = await cachingService.checkStatus();
        expect(status2, AiCoreStatus.available);
        expect(fake.checkStatusCount, 1); // should still be 1!
      },
    );

    test('triggerDownload clears the checkStatus cache', () async {
      final fake = FakeAiService();
      final cachingService = CachingAiService(fake);

      await cachingService.checkStatus();
      expect(fake.checkStatusCount, 1);

      // Trigger download should clear cache and increment triggerDownloadCount
      await cachingService.triggerDownload();
      expect(fake.triggerDownloadCount, 1);

      // Next checkStatus should call delegate again
      fake.mockStatus = AiCoreStatus.downloading;
      final status = await cachingService.checkStatus();
      expect(status, AiCoreStatus.downloading);
      expect(fake.checkStatusCount, 2);
    });

    test('generateContent delegates calls correctly', () async {
      final fake = FakeAiService();
      final cachingService = CachingAiService(fake);

      final response = await cachingService.generateContent(prompt: 'hello');
      expect(response, 'mock response');
      expect(fake.generateContentCount, 1);
    });

    test('setModelConfig delegates calls correctly', () async {
      final fake = FakeAiService();
      final cachingService = CachingAiService(fake);

      await cachingService.setModelConfig(
        releaseStage: 'test',
        preference: 'test',
      );
      expect(fake.setModelConfigCount, 1);
    });
  });
}
