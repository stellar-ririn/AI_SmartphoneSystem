import '../entities/chat_message.dart';
import '../entities/ai_config.dart';

abstract class AIRepository {
  /// Sends a message to the AI and returns the response stream.
  Stream<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    required AIConfig config,
    required String apiKey,
  });
}
