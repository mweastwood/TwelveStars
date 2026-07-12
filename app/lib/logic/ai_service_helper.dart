import 'package:flutter/foundation.dart';
import 'package:local_agent/local_agent.dart';

class LocalAgentHelper {
  static AiService? _instance;

  @visibleForTesting
  static set instance(AiService? service) => _instance = service;

  static AiService get instance {
    _instance ??= getAiService();
    return _instance!;
  }
}
