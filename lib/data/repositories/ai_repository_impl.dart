import '../../../domain/repositories/ai_repository.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/ai_config.dart';
import '../datasources/remote/gemini_service.dart';
import '../datasources/remote/openai_service.dart';

class AIRepositoryImpl implements AIRepository {
  final GeminiService _geminiService;
  final OpenAIService _openAIService;

  AIRepositoryImpl({
    required GeminiService geminiService,
    required OpenAIService openAIService,
  })  : _geminiService = geminiService,
        _openAIService = openAIService;

  @override
  Stream<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    required AIConfig config,
    required String apiKey,
  }) async* {
    if (config.provider == AIProvider.gemini) {
      final stream = await _geminiService.generateResponseStream(
        message: message,
        history: history,
        config: config,
        apiKey: apiKey,
      );
      yield* stream;
    } else {
      yield* _openAIService.generateResponseStream(
        message: message,
        history: history,
        config: config,
        apiKey: apiKey,
      );
    }
  }
}
