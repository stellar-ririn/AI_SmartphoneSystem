import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:ai_assistant_app/domain/services/alarm_service.dart';

class AndroidAlarmService implements AlarmService {
  @override
  Future<bool> setAlarm({required DateTime dateTime, String? message}) async {
    if (!Platform.isAndroid) {
      // iOS/Desktop implementation omitted for this scope (usually requires local notifications)
      print('Alarm setting is only supported on Android for now via Intents.');
      return false;
    }

    try {
      // Create an intent to set an alarm
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.HOUR': dateTime.hour,
          'android.intent.extra.alarm.MINUTES': dateTime.minute,
          'android.intent.extra.alarm.SKIP_UI': true,
          'android.intent.extra.alarm.MESSAGE': message ?? 'AI Alarm',
        },
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      await intent.launch();
      return true;
    } catch (e) {
      print('Error setting alarm: $e');
      return false;
    }
  }
}
