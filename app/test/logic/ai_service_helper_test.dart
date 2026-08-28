import 'dart:async';
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
      'checkStatus caches terminal available status and only calls delegate once',
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

    test(
      'checkStatus does not cache transient downloading status allowing polling',
      () async {
        final fake = FakeAiService();
        fake.mockStatus = AiCoreStatus.downloading;
        final cachingService = CachingAiService(fake);

        final status1 = await cachingService.checkStatus();
        expect(status1, AiCoreStatus.downloading);
        expect(fake.checkStatusCount, 1);

        // Subsequent call should query delegate again
        fake.mockStatus = AiCoreStatus.downloading;
        final status2 = await cachingService.checkStatus();
        expect(status2, AiCoreStatus.downloading);
        expect(fake.checkStatusCount, 2);

        // When it transitions to available, it should return available and cache it
        fake.mockStatus = AiCoreStatus.available;
        final status3 = await cachingService.checkStatus();
        expect(status3, AiCoreStatus.available);
        expect(fake.checkStatusCount, 3);

        // Further calls should use the cached available status
        final status4 = await cachingService.checkStatus();
        expect(status4, AiCoreStatus.available);
        expect(fake.checkStatusCount, 3);
      },
    );

    test(
      'checkStatus does not cache downloadable or unavailable statuses',
      () async {
        final fake = FakeAiService();
        fake.mockStatus = AiCoreStatus.unavailable;
        final cachingService = CachingAiService(fake);

        final status1 = await cachingService.checkStatus();
        expect(status1, AiCoreStatus.unavailable);
        expect(fake.checkStatusCount, 1);

        fake.mockStatus = AiCoreStatus.downloadable;
        final status2 = await cachingService.checkStatus();
        expect(status2, AiCoreStatus.downloadable);
        expect(fake.checkStatusCount, 2);
      },
    );

    test('deduplicates concurrent in-flight checkStatus calls', () async {
      var callCount = 0;
      final completer = Completer<AiCoreStatus>();

      final delayedService = _CustomAiService(() {
        callCount++;
        return completer.future;
      });
      final cachingService = CachingAiService(delayedService);

      // Perform concurrent calls
      final future1 = cachingService.checkStatus();
      final future2 = cachingService.checkStatus();
      final future3 = cachingService.checkStatus();

      expect(callCount, 1);

      completer.complete(AiCoreStatus.available);

      final results = await Future.wait([future1, future2, future3]);
      expect(results, [
        AiCoreStatus.available,
        AiCoreStatus.available,
        AiCoreStatus.available,
      ]);
      expect(callCount, 1);
    });

    test(
      'clears inFlightStatus on delegate error and allows retries',
      () async {
        var shouldThrow = true;
        var callCount = 0;

        // Custom fake behavior for error
        final errorService = _CustomAiService(() {
          callCount++;
          if (shouldThrow) {
            throw Exception('Network error');
          }
          return Future.value(AiCoreStatus.available);
        });

        final cachingService = CachingAiService(errorService);

        // First call fails
        expect(() => cachingService.checkStatus(), throwsA(isA<Exception>()));
        expect(callCount, 1);

        // Retry succeeds
        shouldThrow = false;
        final status = await cachingService.checkStatus();
        expect(status, AiCoreStatus.available);
        expect(callCount, 2);

        // Cached now
        final statusCached = await cachingService.checkStatus();
        expect(statusCached, AiCoreStatus.available);
        expect(callCount, 2);
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

class _CustomAiService implements AiService {
  final Future<AiCoreStatus> Function() onCheckStatus;
  _CustomAiService(this.onCheckStatus);

  @override
  Future<AiCoreStatus> checkStatus() => onCheckStatus();

  @override
  Future<void> triggerDownload() async {}

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {}

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async => null;

  @override
  Future<int> countTokens({
    required String prompt,
    Uint8List? imageBytes,
  }) async => 0;

  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async => null;
}
