import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/services/tts_service.dart';
import '../../domain/services/calendar_service.dart';
import '../../domain/services/news_service.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/datasources/remote/gemini_service.dart';
import '../../data/datasources/remote/openai_service.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/audio_player_manager.dart';
import '../../core/utils/function_parser.dart';
import 'voice_provider.dart';
import 'settings_provider.dart';
import 'assistant_provider.dart';

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
  const systemPrompt = '''
You are a helpful AI assistant. You have access to the following tools:

1. calendar_list: Get upcoming events. JSON: { "tool": "calendar_list" }
2. calendar_create: Create an event. JSON: { "tool": "calendar_create", "title": "Meeting", "startTime": "2024-01-01T10:00:00", "endTime": "2024-01-01T11:00:00" }
3. news_summary: Get latest news headlines. JSON: { "tool": "news_summary" }

If the user asks for something requiring these tools, output ONLY the JSON command.
Do not wrap JSON in markdown blocks.
If no tool is needed, respond normally.
''';

  return const AIConfig(
    provider: AIProvider.gemini,
    modelName: 'gemini-pro',
    systemPrompt: systemPrompt,
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
  final CalendarService _calendarService;
  final NewsService _newsService;

  ChatNotifier({
    required AIRepository repository,
    required AIConfig config,
    required String apiKey,
    required TextToSpeechService ttsService,
    required VoiceConfig voiceConfig,
    required CalendarService calendarService,
    required NewsService newsService,
  })  : _repository = repository,
        _config = config,
        _apiKey = apiKey,
        _ttsService = ttsService,
        _voiceConfig = voiceConfig,
        _calendarService = calendarService,
        _newsService = newsService,
        _audioManager = AudioPlayerManager(),
        super(ChatState(messages: []));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Check API Key
    if (_apiKey.isEmpty) {
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        content: 'Please set your API Key in Settings to start chatting.',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errorMessage]);
      return;
    }

    // Stop previous
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

    await _processResponse(text, isInternal: false);
  }

  Future<void> _processResponse(String input, {bool isInternal = false}) async {
    try {
      // If isInternal (tool loop), the history includes everything in state.
      // If not internal (user sent message), the last message in state is 'input', so we exclude it from history
      // to avoid duplication in the API call (as services append 'input' manually).
      final historyForAI = isInternal
          ? state.messages
          : state.messages.sublist(0, state.messages.length - 1);

      final stream = _repository.sendMessage(
        message: input,
        history: historyForAI,
        config: _config,
        apiKey: _apiKey,
      );

      String fullResponse = '';
      String ttsBuffer = '';

      await for (final chunk in stream) {
        fullResponse += chunk;
        ttsBuffer += chunk;

        // Don't speak tool commands (starting with {)
        if (!fullResponse.trimLeft().startsWith('{')) {
          if (ttsBuffer.contains(RegExp(r'[.!?。！？\n]'))) {
             _queueTts(ttsBuffer);
             ttsBuffer = '';
          }
        }

        state = state.copyWith(currentStreamResponse: fullResponse);
      }

      // Flush TTS if not tool
      if (ttsBuffer.isNotEmpty && !fullResponse.trimLeft().startsWith('{')) {
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

      // Check for Tool Call
      final toolCall = FunctionParser.parse(fullResponse);
      if (toolCall != null) {
        await _handleToolCall(toolCall);
      }

    } catch (e) {
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        content: 'Error: $e',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        currentStreamResponse: null,
        messages: [...state.messages, errorMessage],
      );
    }
  }

  Future<void> _handleToolCall(FunctionCall call) async {
    String toolResult = '';
    state = state.copyWith(isLoading: true, currentStreamResponse: 'Processing tool: ${call.name}...');

    try {
      if (call.name == 'calendar_list') {
        final events = await _calendarService.getUpcomingEvents();
        toolResult = "Calendar Events:\n${events.join('\n')}";
      } else if (call.name == 'calendar_create') {
        // Simple parsing of args, assuming ISO strings or handled by service
        final title = call.args['title'] ?? 'New Event';
        final start = DateTime.tryParse(call.args['startTime'] ?? '') ?? DateTime.now();
        final end = DateTime.tryParse(call.args['endTime'] ?? '') ?? start.add(const Duration(hours: 1));
        await _calendarService.createEvent(title: title, startTime: start, endTime: end);
        toolResult = "Event '$title' created successfully.";
      } else if (call.name == 'news_summary') {
        toolResult = await _newsService.getNewsContentForAI();
      } else {
        toolResult = "Error: Unknown tool '${call.name}'";
      }
    } catch (e) {
      toolResult = "Error executing tool: $e";
    }

    // Add tool result as a System message so AI sees it
    // In real apps, you might use a 'tool' role if supported, or 'user' role with explicit context.
    // For simplicity, we treat it as a hidden system injection and re-prompt.

    final resultMsg = ChatMessage(
      id: const Uuid().v4(),
      content: "[Tool Result for ${call.name}]: $toolResult\nPlease provide a natural response to the user based on this.",
      role: MessageRole.system,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, resultMsg],
    );

    // Recursively call to get the final answer.
    // We pass an empty string because the 'prompt' is already embedded in the resultMsg above.
    await _processResponse("", isInternal: true);
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
  final calendarService = ref.watch(calendarServiceProvider);
  final newsService = ref.watch(newsServiceProvider);

  return ChatNotifier(
    repository: repo,
    config: config,
    apiKey: apiKey,
    ttsService: ttsService,
    voiceConfig: voiceConfig,
    calendarService: calendarService,
    newsService: newsService,
  );
});
