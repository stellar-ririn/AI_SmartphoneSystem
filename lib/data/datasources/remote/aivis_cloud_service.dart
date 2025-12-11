import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/services/tts_service.dart';

class AivisCloudService implements TextToSpeechService {
  final Dio _dio;
  final AudioPlayer _player;
  final String _apiKey; // Injected via provider/repository later

  AivisCloudService({required Dio dio, String apiKey = ''})
      : _dio = dio,
        _player = AudioPlayer(),
        _apiKey = apiKey;

  @override
  Future<void> speak(String text, {required String voiceId, double speed = 1.0}) async {
    if (text.isEmpty) return;

    try {
      // Assuming standard Aivis endpoint based on common cloud TTS patterns
      // Since docs were not readable, we implement a standard POST request structure.
      // User can correct the endpoint/body structure later.
      final response = await _dio.post(
        'https://api.aivis-project.com/v1/synthesis', // Hypothetical Endpoint
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'Accept': 'audio/wav', // or mp3
          },
          responseType: ResponseType.bytes,
        ),
        data: {
          'text': text,
          'speaker_id': voiceId, // e.g., 'announcer_a'
          'speed': speed,
          'pitch': 1.0,
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.data as Uint8List;
        // Audioplayers 5.x Source.bytes logic
        // But Source.bytes might be buggy on some platforms, file is safer.

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_${const Uuid().v4()}.wav');
        await file.writeAsBytes(bytes);

        final completer = Completer<void>();
        // Set listener for completion
        StreamSubscription? sub;
        sub = _player.onPlayerComplete.listen((_) {
          completer.complete();
          sub?.cancel();
        });

        await _player.play(DeviceFileSource(file.path));
        await completer.future;
      } else {
        print('Aivis API Error: ${response.statusCode} ${response.statusMessage}');
      }
    } catch (e) {
      print('Aivis TTS Exception: $e');
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }
}
