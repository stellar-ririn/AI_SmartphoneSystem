import 'package:flutter_tts/flutter_tts.dart';
import '../../../domain/services/tts_service.dart';

class StandardTTSService implements TextToSpeechService {
  final FlutterTts _flutterTts;

  StandardTTSService() : _flutterTts = FlutterTts() {
    _flutterTts.setLanguage("ja-JP"); // Default to Japanese
  }

  @override
  Future<void> speak(String text, {required String voiceId, double speed = 1.0}) async {
    await _flutterTts.setSpeechRate(speed);
    // On standard TTS, 'voiceId' might be ignored or mapped to available voices
    // For now we just speak.
    await _flutterTts.speak(text);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
