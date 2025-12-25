import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/ai_config.dart';
import 'chat_provider.dart'; // To update AIConfig

// Keys for Secure Storage
const _kGeminiKey = 'GEMINI_API_KEY';
const _kOpenAiKey = 'OPENAI_API_KEY';
const _kAivisKey = 'AIVIS_API_KEY';
const _kAIProvider = 'AI_PROVIDER';
const _kAIModel = 'AI_MODEL';
const _kAISystemPrompt = 'AI_SYSTEM_PROMPT';
const _kNotificationEnabled = 'NOTIFICATION_ENABLED';
const _kNotificationSummary = 'NOTIFICATION_SUMMARY';

const _storage = FlutterSecureStorage();

// Providers that hold the current value of the keys
final geminiKeyProvider = StateProvider<String>((ref) => '');
final openaiKeyProvider = StateProvider<String>((ref) => '');
final aivisKeyProvider = StateProvider<String>((ref) => '');

final notificationEnabledProvider = StateProvider<bool>((ref) => false);
final notificationSummaryProvider = StateProvider<bool>((ref) => false);

// Service class to handle storage operations
class SettingsService {
  Future<void> saveKeys({
    required String geminiKey,
    required String openAiKey,
    required String aivisKey,
    required WidgetRef ref,
  }) async {
    await _storage.write(key: _kGeminiKey, value: geminiKey);
    await _storage.write(key: _kOpenAiKey, value: openAiKey);
    await _storage.write(key: _kAivisKey, value: aivisKey);

    // Save AI Config as well
    final config = ref.read(aiConfigProvider);
    await _storage.write(key: _kAIProvider, value: config.provider.name);
    await _storage.write(key: _kAIModel, value: config.modelName);
    await _storage.write(key: _kAISystemPrompt, value: config.systemPrompt);

    // Save Notification Settings
    final notifEnabled = ref.read(notificationEnabledProvider);
    final notifSummary = ref.read(notificationSummaryProvider);
    await _storage.write(key: _kNotificationEnabled, value: notifEnabled.toString());
    await _storage.write(key: _kNotificationSummary, value: notifSummary.toString());

    // Update state
    ref.read(geminiKeyProvider.notifier).state = geminiKey;
    ref.read(openaiKeyProvider.notifier).state = openAiKey;
    ref.read(aivisKeyProvider.notifier).state = aivisKey;
  }

  Future<void> loadKeys(WidgetRef ref) async {
    final gemini = await _storage.read(key: _kGeminiKey) ?? '';
    final openai = await _storage.read(key: _kOpenAiKey) ?? '';
    final aivis = await _storage.read(key: _kAivisKey) ?? '';

    final notifEnabledStr = await _storage.read(key: _kNotificationEnabled) ?? 'false';
    final notifSummaryStr = await _storage.read(key: _kNotificationSummary) ?? 'false';

    ref.read(geminiKeyProvider.notifier).state = gemini;
    ref.read(openaiKeyProvider.notifier).state = openai;
    ref.read(aivisKeyProvider.notifier).state = aivis;

    ref.read(notificationEnabledProvider.notifier).state = notifEnabledStr == 'true';
    ref.read(notificationSummaryProvider.notifier).state = notifSummaryStr == 'true';

    // Load AI Config
    final providerStr = await _storage.read(key: _kAIProvider);
    final modelName = await _storage.read(key: _kAIModel);
    final systemPrompt = await _storage.read(key: _kAISystemPrompt);

    if (providerStr != null) {
      final provider = AIProvider.values.firstWhere(
        (e) => e.name == providerStr,
        orElse: () => AIProvider.gemini
      );

      final currentConfig = ref.read(aiConfigProvider);
      ref.read(aiConfigProvider.notifier).state = currentConfig.copyWith(
        provider: provider,
        modelName: modelName ?? currentConfig.modelName,
        systemPrompt: systemPrompt ?? currentConfig.systemPrompt,
      );
    }
  }
}

final settingsServiceProvider = Provider((ref) => SettingsService());
