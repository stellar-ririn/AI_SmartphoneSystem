import 'package:dart_openai/dart_openai.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/ai_config.dart';

class OpenAIService {
  Stream<String> generateResponseStream({
    required String message,
    required List<ChatMessage> history,
    required AIConfig config,
    required String apiKey,
  }) {
    OpenAI.apiKey = apiKey;

    // Map history
    final messages = history.map((msg) {
      return OpenAIChatCompletionChoiceMessageModel(
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(msg.content)],
        role: msg.role == MessageRole.user
            ? OpenAIChatMessageRole.user
            : msg.role == MessageRole.system
              ? OpenAIChatMessageRole.system
              : OpenAIChatMessageRole.assistant,
      );
    }).toList();

    // Add System Prompt
    messages.insert(0, OpenAIChatCompletionChoiceMessageModel(
       content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(config.systemPrompt)],
       role: OpenAIChatMessageRole.system,
    ));

    // Add current user message
    messages.add(OpenAIChatCompletionChoiceMessageModel(
       content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(message)],
       role: OpenAIChatMessageRole.user,
    ));

    final stream = OpenAI.instance.chat.createStream(
      model: config.modelName, // e.g., 'gpt-3.5-turbo'
      messages: messages,
      temperature: config.temperature,
    );

    return stream.map((event) => event.choices.first.delta.content?.first.text ?? '');
  }
}
