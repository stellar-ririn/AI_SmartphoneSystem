import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Keys for Secure Storage
const _kGeminiKey = 'GEMINI_API_KEY';
const _kOpenAiKey = 'OPENAI_API_KEY';
const _kAivisKey = 'AIVIS_API_KEY';

const _storage = FlutterSecureStorage();

// Providers that hold the current value of the keys
final geminiKeyProvider = StateProvider<String>((ref) => '');
final openaiKeyProvider = StateProvider<String>((ref) => '');
final aivisKeyProvider = StateProvider<String>((ref) => '');

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

    // Update state
    ref.read(geminiKeyProvider.notifier).state = geminiKey;
    ref.read(openaiKeyProvider.notifier).state = openAiKey;
    ref.read(aivisKeyProvider.notifier).state = aivisKey;
  }

  Future<void> loadKeys(WidgetRef ref) async {
    final gemini = await _storage.read(key: _kGeminiKey) ?? '';
    final openai = await _storage.read(key: _kOpenAiKey) ?? '';
    final aivis = await _storage.read(key: _kAivisKey) ?? '';

    ref.read(geminiKeyProvider.notifier).state = gemini;
    ref.read(openaiKeyProvider.notifier).state = openai;
    ref.read(aivisKeyProvider.notifier).state = aivis;
  }
}

final settingsServiceProvider = Provider((ref) => SettingsService());
