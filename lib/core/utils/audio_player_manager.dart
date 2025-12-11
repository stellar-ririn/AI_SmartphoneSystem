import 'dart:async';
import 'dart:collection';
import '../../domain/services/tts_service.dart';

class AudioTask {
  final String text;
  final TextToSpeechService service;
  final String voiceId;
  final double speed;

  AudioTask({
    required this.text,
    required this.service,
    required this.voiceId,
    required this.speed,
  });
}

class AudioPlayerManager {
  final Queue<AudioTask> _queue = Queue();
  bool _isPlaying = false;

  void enqueue(AudioTask task) {
    _queue.add(task);
    _processQueue();
  }

  void clear() {
    _queue.clear();
    // Ideally stop current playback too, but services might need a 'stop' method invoked
  }

  Future<void> _processQueue() async {
    if (_isPlaying || _queue.isEmpty) return;

    _isPlaying = true;
    final task = _queue.removeFirst();

    try {
      // The 'speak' method in our interface should preferably await until completion
      // StandardTTSService does awaitSpeakCompletion(true).
      // AivisCloudService currently plays via audioPlayer but doesn't await completion fully in my previous code.
      // I need to update AivisCloudService to return a Future that completes when audio finishes.
      await task.service.speak(task.text, voiceId: task.voiceId, speed: task.speed);
    } catch (e) {
      print('Audio playback error: $e');
    } finally {
      _isPlaying = false;
      _processQueue();
    }
  }
}
