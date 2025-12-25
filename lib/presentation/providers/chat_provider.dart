import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_assistant_app/domain/entities/chat_message.dart';
import 'package:ai_assistant_app/domain/entities/ai_config.dart';
import 'package:ai_assistant_app/domain/services/tts_service.dart';
import 'package:ai_assistant_app/domain/services/calendar_service.dart';
import 'package:ai_assistant_app/domain/services/news_service.dart';
import 'package:ai_assistant_app/domain/services/alarm_service.dart';
import 'package:ai_assistant_app/domain/repositories/ai_repository.dart';
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

1. calendar_list: Get upcoming events.
   - Usage: { "tool": "calendar_list" }
2. calendar_create: Create an event.
   - Usage: { "tool": "calendar_create", "title": "Meeting", "startTime": "ISO8601", "endTime": "ISO8601" }
3. news_summary: Get latest news headlines.
   - Usage: { "tool": "news_summary" }
4. alarm_set: Set an alarm.
   - Usage: { "tool": "alarm_set", "time": "ISO8601", "message": "Alarm Label" }

IMPORTANT:
- When using a tool, your entire response must be ONLY the JSON object.
- Do NOT add markdown blocks (like ```json), explanations, or extra text.
- Just the raw JSON string.
- If no tool is needed, respond normally in natural language.
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
  final Ref _ref;
  final AIRepository _repository;
  final AudioPlayerManager _audioManager;
  final CalendarService _calendarService;
  final NewsService _newsService;
  final AlarmService _alarmService;

  ChatNotifier({
    required Ref ref,
    required AIRepository repository,
    required CalendarService calendarService,
    required NewsService newsService,
    required AlarmService alarmService,
  })  : _ref = ref,
        _repository = repository,
        _calendarService = calendarService,
        _newsService = newsService,
        _alarmService = alarmService,
        _audioManager = AudioPlayerManager(),
        super(ChatState(messages: []));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final ttsService = _ref.read(ttsServiceProvider);

    // Stop previous
    _audioManager.clear();
    await ttsService.stop();

    // Add User Message first so it appears in UI
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

    final apiKey = _ref.read(apiKeyProvider);
    final config = _ref.read(aiConfigProvider);

    // Check API Key
    if (apiKey.isEmpty) {
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        content: 'Please set your API Key for ${config.provider.name.toUpperCase()} in Settings to start chatting.',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false, // Stop loading
      );
      return;
    }

    await _processResponse(text, isInternal: false);
  }

  Future<void> _processResponse(String input, {bool isInternal = false}) async {
    final config = _ref.read(aiConfigProvider);
    final apiKey = _ref.read(apiKeyProvider);

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
        config: config,
        apiKey: apiKey,
      );

      String fullResponse = '';
      String ttsBuffer = '';

      await for (final chunk in stream) {
        fullResponse += chunk;
        ttsBuffer += chunk;

        // Debug Log
        // print('Stream chunk: $chunk');

        // Don't speak tool commands (starting with {)
        if (!fullResponse.trimLeft().startsWith('{')) {
          if (ttsBuffer.contains(RegExp(r'[.!?。！？\n]'))) {
             _queueTts(ttsBuffer);
             ttsBuffer = '';
          }
        }

        state = state.copyWith(currentStreamResponse: fullResponse);
      }

      print('Full AI Response: $fullResponse'); // Debug Log

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
      } else if (call.name == 'alarm_set') {
        final timeStr = call.args['time'] ?? '';
        final message = call.args['message'];
        final dateTime = DateTime.tryParse(timeStr);

        if (dateTime != null) {
          final success = await _alarmService.setAlarm(dateTime: dateTime, message: message);
          toolResult = success
              ? "Alarm set for $timeStr successfully."
              : "Failed to set alarm (Platform limitation or error).";
        } else {
          toolResult = "Invalid time format for alarm.";
        }
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

  Future<void> handleNotification(String text) async {
    final ttsService = _ref.read(ttsServiceProvider);
    final shouldSummarize = _ref.read(notificationSummaryProvider);

    if (shouldSummarize) {
      // Send to AI for summary
      final prompt = "A new notification arrived: \"$text\". Please summarize this briefly for me.";
      await sendMessage(prompt); // This will naturally trigger TTS on the response
    } else {
      // Read raw text
      await ttsService.speak(text, voiceId: _ref.read(voiceConfigProvider).voiceId);
    }
  }

  void _queueTts(String text) {
    final voiceConfig = _ref.read(voiceConfigProvider);
    final ttsService = _ref.read(ttsServiceProvider);

    if (voiceConfig.type == VoiceType.off) return;

    _audioManager.enqueue(AudioTask(
      text: text,
      service: ttsService,
      voiceId: voiceConfig.voiceId,
      speed: voiceConfig.speed,
    ));
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  // We do NOT watch volatile providers (config, key, voice) here to prevent
  // the ChatNotifier (and chat history) from resetting when settings change.
  final calendarService = ref.watch(calendarServiceProvider);
  final newsService = ref.watch(newsServiceProvider);
  final alarmService = ref.watch(alarmServiceProvider);

  return ChatNotifier(
    ref: ref,
    repository: repo,
    calendarService: calendarService,
    newsService: newsService,
    alarmService: alarmService,
  );
});
