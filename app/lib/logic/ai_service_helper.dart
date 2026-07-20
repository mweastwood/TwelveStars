import 'package:flutter/foundation.dart';
import 'package:local_agent/local_agent.dart';

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
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    bool lowTemperature = false,
    int? maxOutputTokens,
  }) {
    return delegate.generateContent(
      prompt: prompt,
      imageBytes: imageBytes,
      lowTemperature: lowTemperature,
      maxOutputTokens: maxOutputTokens,
    );
  }
}
