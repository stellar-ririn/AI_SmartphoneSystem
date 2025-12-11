import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import '../../domain/services/calendar_service.dart';

class GoogleCalendarService implements CalendarService {
  final GoogleSignIn _googleSignIn;

  GoogleCalendarService()
      : _googleSignIn = GoogleSignIn(
          scopes: [calendar.CalendarApi.calendarScope],
        );

  Future<calendar.CalendarApi?> _getCalendarApi() async {
    final account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final authenticateClient = _GoogleAuthClient(authHeaders);
    return calendar.CalendarApi(authenticateClient);
  }

  @override
  Future<List<String>> getUpcomingEvents({int days = 7}) async {
    try {
      final api = await _getCalendarApi();
      if (api == null) return ['Error: Not signed in to Google.'];

      final now = DateTime.now();
      final end = now.add(Duration(days: days));

      final events = await api.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items == null || events.items!.isEmpty) {
        return ['No upcoming events found for the next $days days.'];
      }

      return events.items!.map((e) {
        final start = e.start?.dateTime ?? e.start?.date;
        return '- ${e.summary} at ${start?.toLocal()}';
      }).toList();
    } catch (e) {
      return ['Error fetching events: $e'];
    }
  }

  @override
  Future<void> createEvent({required String title, required DateTime startTime, required DateTime endTime}) async {
    final api = await _getCalendarApi();
    if (api == null) throw Exception('Not signed in');

    final event = calendar.Event(
      summary: title,
      start: calendar.EventDateTime(dateTime: startTime.toUtc()),
      end: calendar.EventDateTime(dateTime: endTime.toUtc()),
    );

    await api.events.insert(event, 'primary');
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
