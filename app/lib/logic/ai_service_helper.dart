import 'package:local_agent/local_agent.dart';

class LocalAgentHelper {
  static AiService? _instance;

  static AiService get instance {
    _instance ??= getAiService();
    return _instance!;
  }
}
