import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_config.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/datasources/remote/gemini_service.dart';
import '../../data/datasources/remote/openai_service.dart';
import 'package:uuid/uuid.dart';

// --- Data Sources & Repositories Providers ---

final geminiServiceProvider = Provider((ref) => GeminiService());
final openAIServiceProvider = Provider((ref) => OpenAIService());

final aiRepositoryProvider = Provider<AIRepositoryImpl>((ref) {
  return AIRepositoryImpl(
    geminiService: ref.watch(geminiServiceProvider),
    openAIService: ref.watch(openAIServiceProvider),
  );
});

// --- Settings Providers (Mock for now, will connect to SecureStorage later) ---

final aiConfigProvider = StateProvider<AIConfig>((ref) {
  return const AIConfig(
    provider: AIProvider.gemini,
    modelName: 'gemini-pro',
    systemPrompt: 'You are a helpful and friendly assistant.',
  );
});

final apiKeyProvider = Provider<String>((ref) {
  // TODO: Retrieve from FlutterSecureStorage based on selected provider
  // For safety, return empty string. User must input it.
  return '';
});

// --- Chat State ---

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? currentStreamResponse;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.currentStreamResponse,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? currentStreamResponse,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentStreamResponse: currentStreamResponse ?? this.currentStreamResponse,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final AIRepositoryImpl _repository;
  final AIConfig _config;
  final String _apiKey;

  ChatNotifier({
    required AIRepositoryImpl repository,
    required AIConfig config,
    required String apiKey,
  })  : _repository = repository,
        _config = config,
        _apiKey = apiKey,
        super(ChatState(messages: []));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_apiKey.isEmpty) {
      // Handle missing API key error
      return;
    }

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      currentStreamResponse: '',
    );

    try {
      final stream = _repository.sendMessage(
        message: text,
        history: state.messages.where((m) => m.role != MessageRole.system).toList(),
        config: _config,
        apiKey: _apiKey,
      );

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk;
        state = state.copyWith(
          currentStreamResponse: fullResponse,
        );
      }

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        content: fullResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        currentStreamResponse: null,
      );
    } catch (e) {
      // TODO: Handle error properly
      state = state.copyWith(
        isLoading: false,
        currentStreamResponse: null,
        // Add error message to chat or show snackbar
      );
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  final config = ref.watch(aiConfigProvider);
  final apiKey = ref.watch(apiKeyProvider);

  return ChatNotifier(
    repository: repo,
    config: config,
    apiKey: apiKey,
  );
});
