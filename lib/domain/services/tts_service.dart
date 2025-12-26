abstract class TextToSpeechService {
  /// Synthesizes text to audio and returns a stream of audio bytes or plays it directly.
  /// Returns a Future that completes when the audio is finished playing (or queued).
  Future<void> speak(String text, {required String voiceId, double speed = 1.0});

  /// Stops any current playback.
  Future<void> stop();
}
