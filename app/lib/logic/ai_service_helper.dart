import 'package:flutter/foundation.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';

class LocalAgentHelper {
  static AiService? _instance;

  @visibleForTesting
  static set instance(AiService? service) => _instance = service;

  static AiService get instance {
    _instance ??= CachingAiService(getAiService());
    return _instance!;
  }
}

class CachingAiService implements AiService {
  final AiService delegate;
  Future<AiCoreStatus>? _statusFuture;

  CachingAiService(this.delegate);

  @override
  Future<AiCoreStatus> checkStatus() {
    _statusFuture ??= delegate.checkStatus();
    return _statusFuture!;
  }

  @override
  Future<void> triggerDownload() {
    _statusFuture = null;
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
