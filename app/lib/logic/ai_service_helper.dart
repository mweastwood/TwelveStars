import 'package:flutter/foundation.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/widgets/ai_generation_sheet.dart'
    show AiGenerationUserMessageException;

class LocalAgentHelper {
  static AiService? _instance;

  @visibleForTesting
  static set instance(AiService? service) => _instance = service;

  static AiService get instance {
    _instance ??= CachingAiService(getAiService());
    return _instance!;
  }

  /// Builds the structured theological/etymological LLM prompt for explaining
  /// a selected prayer phrase translation in context.
  static String buildTranslationExplanationPrompt({
    required String originalPhrase,
    required String translatedPhrase,
    required String originalContext,
    required String translatedContext,
    String? originalLang,
    String? translatedLang,
  }) {
    return '''
Original phrase:
$originalPhrase

Translated phrase:
$translatedPhrase

Original phrase in context:
$originalContext

Translated phrase in context:
$translatedContext

Define each translated word in the selected phrase and explain how the translated phrase carries the meaning of the original phrase. Focus your explanation only on the selected phrase in context, not the rest of the prayer.
''';
  }

  /// Generates a local AI explanation for a translated prayer phrase,
  /// throwing [AiGenerationUserMessageException] if the model returns null or empty output.
  static Future<String> generateTranslationExplanation({
    required String originalPhrase,
    required String translatedPhrase,
    required String originalContext,
    required String translatedContext,
    String? originalLang,
    String? translatedLang,
    AiService? aiService,
  }) async {
    final prompt = buildTranslationExplanationPrompt(
      originalPhrase: originalPhrase,
      translatedPhrase: translatedPhrase,
      originalContext: originalContext,
      translatedContext: translatedContext,
      originalLang: originalLang,
      translatedLang: translatedLang,
    );

    final service = aiService ?? instance;
    final response = await service.generateContentWithContinuation(
      prompt: prompt,
      maxOutputTokens: 256,
      autoContinueLimit: 3,
    );
    if (response == null || response.trim().isEmpty) {
      throw const AiGenerationUserMessageException('No explanation generated.');
    }
    return response;
  }
}

extension TranslationExplanationAiServiceExtension on AiService {
  /// Generates a local AI explanation for a translated prayer phrase using this [AiService].
  Future<String> generateTranslationExplanation({
    required String originalPhrase,
    required String translatedPhrase,
    required String originalContext,
    required String translatedContext,
    String? originalLang,
    String? translatedLang,
  }) {
    return LocalAgentHelper.generateTranslationExplanation(
      originalPhrase: originalPhrase,
      translatedPhrase: translatedPhrase,
      originalContext: originalContext,
      translatedContext: translatedContext,
      originalLang: originalLang,
      translatedLang: translatedLang,
      aiService: this,
    );
  }
}

class CachingAiService implements AiService {
  final AiService delegate;
  AiCoreStatus? _cachedStatus;
  Future<AiCoreStatus>? _inFlightStatus;

  CachingAiService(this.delegate);

  @override
  Future<AiCoreStatus> checkStatus() async {
    if (_cachedStatus == AiCoreStatus.available) {
      return _cachedStatus!;
    }
    if (_inFlightStatus != null) {
      return _inFlightStatus!;
    }

    final future = delegate.checkStatus();
    _inFlightStatus = future;

    try {
      final status = await future;
      if (status == AiCoreStatus.available) {
        _cachedStatus = status;
      }
      return status;
    } finally {
      _inFlightStatus = null;
    }
  }

  @override
  Future<void> triggerDownload() {
    _cachedStatus = null;
    _inFlightStatus = null;
    return delegate.triggerDownload();
  }

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) {
    return delegate.setModelConfig(
      releaseStage: releaseStage,
      preference: preference,
    );
  }

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) {
    return delegate.generateContent(
      prompt: prompt,
      imageBytes: imageBytes,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  @override
  Future<int> countTokens({required String prompt, Uint8List? imageBytes}) {
    return delegate.countTokens(prompt: prompt, imageBytes: imageBytes);
  }

  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) {
    return delegate.generateContentRaw(
      prompt: prompt,
      imageBytes: imageBytes,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }
}
