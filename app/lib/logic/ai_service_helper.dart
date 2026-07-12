import 'package:flutter/foundation.dart';
import 'package:local_agent/local_agent.dart';

class LocalAgentHelper {
  static AiService? _instance;

  static AiService get instance {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = getWebAiService();
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        _instance = MethodChannelAiService();
      } else {
        _instance = MockAiService();
      }
    }
    return _instance!;
  }
}
