abstract class AlarmService {
  /// Sets an alarm at the specified [dateTime].
  /// [message] is an optional label for the alarm.
  Future<bool> setAlarm({required DateTime dateTime, String? message});
}
