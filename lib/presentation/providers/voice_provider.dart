import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/tts_service.dart';
import '../../data/datasources/remote/aivis_cloud_service.dart';
import '../../data/datasources/local/standard_tts_service.dart';
import 'package:dio/dio.dart';
import 'settings_provider.dart'; // To get API Key

enum VoiceType {
  aivis,
  standard,
  off,
}

class VoiceConfig {
  final VoiceType type;
  final String voiceId; // For Aivis
  final double speed;

  const VoiceConfig({
    this.type = VoiceType.standard,
    this.voiceId = '888753760', // Example default ID
    this.speed = 1.0,
  });
}

final voiceConfigProvider = StateProvider<VoiceConfig>((ref) => const VoiceConfig());

final ttsServiceProvider = Provider<TextToSpeechService>((ref) {
  final config = ref.watch(voiceConfigProvider);
  final aivisKey = ref.watch(aivisKeyProvider);

  switch (config.type) {
    case VoiceType.aivis:
      return AivisCloudService(dio: Dio(), apiKey: aivisKey);
    case VoiceType.standard:
      return StandardTTSService();
    case VoiceType.off:
      return _SilentService();
  }
});

class _SilentService implements TextToSpeechService {
  @override
  Future<void> speak(String text, {required String voiceId, double speed = 1.0}) async {
    // Do nothing
  }
  @override
  Future<void> stop() async {}
}
