abstract class CalendarService {
  /// Fetches events for the next [days] days.
  Future<List<String>> getUpcomingEvents({int days = 7});

  /// Creates a new event.
  Future<void> createEvent({required String title, required DateTime startTime, required DateTime endTime});
}
