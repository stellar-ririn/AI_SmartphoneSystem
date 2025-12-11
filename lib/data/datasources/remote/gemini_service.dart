import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/ai_config.dart';

class GeminiService {
  Future<Stream<String>> generateResponseStream({
    required String message,
    required List<ChatMessage> history,
    required AIConfig config,
    required String apiKey,
  }) async {
    final model = GenerativeModel(
      model: config.modelName, // e.g., 'gemini-pro'
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: config.temperature,
      ),
    );

    // Convert history to Gemini Content
    final chatHistory = history.map((msg) {
      if (msg.role == MessageRole.user) {
        return Content.text(msg.content);
      } else {
        return Content.model([TextPart(msg.content)]);
      }
    }).toList();

    // Add System Prompt if supported (Gemini usually takes it as context or separate param in newer APIs,
    // but for simple chat, prepending it to the first message or using startChat is common.
    // However, google_generative_ai supports systemInstruction in recent versions, check version.
    // ^0.2.0 might be old. Let's assume basic chat for now or prepend.)

    // Create chat session
    final chat = model.startChat(history: chatHistory);

    // Send message
    final content = Content.text(message);
    final response = chat.sendMessageStream(content);

    return response.map((event) => event.text ?? '');
  }
}
