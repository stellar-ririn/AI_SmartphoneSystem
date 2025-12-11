import 'package:dio/dio.dart';
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:ai_assistant_app/domain/services/news_service.dart';

class RssNewsService implements NewsService {
  final Dio _dio;
  // Default feeds, user configuration to be added later
  final List<String> _feedUrls = [
    'https://news.yahoo.co.jp/rss/topics/top-picks.xml', // Example JP News
    // 'http://feeds.bbci.co.uk/news/rss.xml',
  ];

  RssNewsService({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<List<String>> getHeadlines() async {
    List<String> headlines = [];
    for (final url in _feedUrls) {
      try {
        final response = await _dio.get(url);
        final rss = RssFeed.parse(response.data);

        if (rss.items != null) {
          headlines.addAll(rss.items!.take(3).map((item) => item.title ?? 'No Title'));
        }
      } catch (e) {
        print('Error fetching RSS $url: $e');
      }
    }
    return headlines;
  }

  @override
  Future<String> getNewsContentForAI() async {
    final headlines = await getHeadlines();
    if (headlines.isEmpty) return "No news found currently.";

    return "Here are the latest news headlines:\n" + headlines.map((h) => "- $h").join("\n");
  }
}
