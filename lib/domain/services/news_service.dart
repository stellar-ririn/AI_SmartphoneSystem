abstract class NewsService {
  /// Fetches top news headlines from the configured RSS feeds.
  Future<List<String>> getHeadlines();

  /// Fetches news and returns a string suitable for AI summarization.
  Future<String> getNewsContentForAI();
}
