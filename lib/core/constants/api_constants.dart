/// API base URL and endpoint constants for Deezer Track Fetcher.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://5.78.43.182:5050';
  static const String deezerBaseUrl = 'https://api.deezer.com';

  static const String tracksPath = '/tracks';
  static const String tracksAllPath = '/tracks/all';
  static const String deezerSearchPath = '/search';

  /// Track details and lyrics - same server; common REST patterns.
  static String trackDetailsPath(String trackId) => '/tracks/$trackId';
  static String trackLyricsPath(String trackId) => '/tracks/$trackId/lyrics';
}
