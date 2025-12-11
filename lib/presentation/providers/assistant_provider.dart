import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_assistant_app/domain/services/calendar_service.dart';
import 'package:ai_assistant_app/domain/services/news_service.dart';
import '../../data/datasources/remote/google_calendar_service.dart';
import '../../data/datasources/remote/rss_news_service.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return GoogleCalendarService();
});

final newsServiceProvider = Provider<NewsService>((ref) {
  return RssNewsService();
});
