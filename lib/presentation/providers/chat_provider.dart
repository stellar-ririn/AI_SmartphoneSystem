import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/services/tts_service.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/datasources/remote/gemini_service.dart';
import '../../data/datasources/remote/openai_service.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/audio_player_manager.dart';
import 'voice_provider.dart';
import 'settings_provider.dart';

// --- Data Sources & Repositories Providers ---

import '../../domain/repositories/ai_repository.dart';

final geminiServiceProvider = Provider((ref) => GeminiService());
final openAIServiceProvider = Provider((ref) => OpenAIService());

final aiRepositoryProvider = Provider<AIRepository>((ref) {
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
  final config = ref.watch(aiConfigProvider);
  if (config.provider == AIProvider.gemini) {
    return ref.watch(geminiKeyProvider);
  } else {
    return ref.watch(openaiKeyProvider);
  }
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
  final AIRepository _repository;
  final AIConfig _config;
  final String _apiKey;
  final AudioPlayerManager _audioManager;
  final TextToSpeechService _ttsService;
  final VoiceConfig _voiceConfig;

  ChatNotifier({
    required AIRepository repository,
    required AIConfig config,
    required String apiKey,
    required TextToSpeechService ttsService,
    required VoiceConfig voiceConfig,
  })  : _repository = repository,
        _config = config,
        _apiKey = apiKey,
        _ttsService = ttsService,
        _voiceConfig = voiceConfig,
        _audioManager = AudioPlayerManager(),
        super(ChatState(messages: []));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_apiKey.isEmpty) {
      // Handle missing API key error
      return;
    }

    // Stop any previous audio
    _audioManager.clear();
    await _ttsService.stop();

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
      // Simple buffering for TTS to avoid chopping sentences too much
      // Ideally we should wait for punctuation (. ? !)
      String ttsBuffer = '';

      await for (final chunk in stream) {
        fullResponse += chunk;
        ttsBuffer += chunk;

        // Check for punctuation to flush to TTS
        if (ttsBuffer.contains(RegExp(r'[.!?。！？\n]'))) {
          _queueTts(ttsBuffer);
          ttsBuffer = '';
        }

        state = state.copyWith(
          currentStreamResponse: fullResponse,
        );
      }

      // Flush remaining
      if (ttsBuffer.isNotEmpty) {
        _queueTts(ttsBuffer);
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

  void _queueTts(String text) {
    if (_voiceConfig.type == VoiceType.off) return;

    _audioManager.enqueue(AudioTask(
      text: text,
      service: _ttsService,
      voiceId: _voiceConfig.voiceId,
      speed: _voiceConfig.speed,
    ));
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  final config = ref.watch(aiConfigProvider);
  final apiKey = ref.watch(apiKeyProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  final voiceConfig = ref.watch(voiceConfigProvider);

  return ChatNotifier(
    repository: repo,
    config: config,
    apiKey: apiKey,
    ttsService: ttsService,
    voiceConfig: voiceConfig,
  );
});
