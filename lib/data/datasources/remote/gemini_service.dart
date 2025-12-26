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

    // Prepare contents including system prompt
    final List<Content> contents = [];

    // Inject System Prompt at the beginning
    // Gemini API (via google_generative_ai) handles system instructions best
    // if added as a 'model' part or prepended to the first user message if 'system' role isn't fully supported in all versions.
    // However, recent versions support a specific param or treating it as context.
    // For robust chat, we can prepend it as a User message saying "Instructions: ..." or just text.
    // Here we act as if it's the first message from User to define the persona.
    if (config.systemPrompt.isNotEmpty) {
      contents.add(Content.text("System Instructions: ${config.systemPrompt}"));
    }

    // Convert history to Gemini Content
    contents.addAll(history.map((msg) {
      if (msg.role == MessageRole.user) {
        return Content.text(msg.content);
      } else if (msg.role == MessageRole.system) {
        // Map system messages (tool results) to User role for Gemini context
        // so it acts as "Observation" input.
        return Content.text(msg.content);
      } else {
        return Content.model([TextPart(msg.content)]);
      }
    }).toList());

    // Add current message if it exists
    if (message.isNotEmpty) {
      contents.add(Content.text(message));
    }

    final response = model.generateContentStream(contents);
    return response.map((event) => event.text ?? '');
  }
}
