import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../models/track_details.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/connectivity_service.dart';

/// Thrown when the server or network fails (offline, timeout, 5xx).
class TrackRepositoryException implements Exception {
  TrackRepositoryException(this.message, {this.offline = false});
  final String message;
  final bool offline;

  @override
  String toString() => message;
}

/// Fetches tracks (paged), track details, and lyrics. Handles offline.
class TrackRepository {
  TrackRepository({
    http.Client? client,
    ConnectivityService? connectivity,
  })  : _client = client ?? http.Client(),
        _connectivity = connectivity ?? ConnectivityService();

  final http.Client _client;
  final ConnectivityService _connectivity;

  String get _base => ApiConstants.baseUrl;

  /// Check connectivity. If offline, throws with [TrackRepositoryException.offline].
  Future<void> _ensureOnline() async {
    final ok = await _connectivity.hasConnection;
    if (!ok) {
      throw TrackRepositoryException('NO INTERNET CONNECTION', offline: true);
    }
  }

  /// GET /tracks?q=...&index=...&limit=...
  /// Returns list of tracks and whether there may be more.
  Future<({List<Track> tracks, bool hasMore})> getTracks({
    required String query,
    int index = 0,
    int limit = 50,
  }) async {
    await _ensureOnline();
    final uri = Uri.parse(_base + ApiConstants.tracksPath).replace(
      queryParameters: {
        'q': query.isEmpty ? 'a' : query,
        'index': index.toString(),
        'limit': limit.clamp(1, 50).toString(),
      },
    );
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TrackRepositoryException(
          'NO INTERNET CONNECTION',
          offline: true,
        ),
      );
      if (response.statusCode != 200) {
        throw TrackRepositoryException(
          'Server error: ${response.statusCode}',
          offline: response.statusCode == 0,
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final list = body?['tracks'];
      final tracks = (list is List)
          ? list
              .map((e) => Track.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((t) => t.id > 0)
              .toList()
          : <Track>[];

      // Backend currently returns empty arrays for valid queries.
      // Fallback to Deezer public search API so the app remains functional.
      if (tracks.isNotEmpty) {
        final hasMore = tracks.length >= limit;
        return (tracks: tracks, hasMore: hasMore);
      }

      return await _getTracksFromDeezer(
        query: query.isEmpty ? 'a' : query,
        index: index,
        limit: limit.clamp(1, 50),
      );
    } on http.ClientException {
      throw TrackRepositoryException(
        'NO INTERNET CONNECTION',
        offline: true,
      );
    } on FormatException {
      throw TrackRepositoryException('Invalid response from server');
    }
  }

  Future<({List<Track> tracks, bool hasMore})> _getTracksFromDeezer({
    required String query,
    required int index,
    required int limit,
  }) async {
    final deezerUri = Uri.parse(ApiConstants.deezerBaseUrl + ApiConstants.deezerSearchPath).replace(
      queryParameters: {
        'q': query,
        'index': index.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(deezerUri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TrackRepositoryException(
        'NO INTERNET CONNECTION',
        offline: true,
      ),
    );

    if (response.statusCode != 200) {
      throw TrackRepositoryException('Server error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body is! Map) return (tracks: <Track>[], hasMore: false);
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final tracks = (data is List)
        ? data
            .map((e) => Track.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((t) => t.id > 0)
            .toList()
        : <Track>[];

    final hasMore = map['next'] is String ? true : tracks.length >= limit;
    return (tracks: tracks, hasMore: hasMore);
  }

  /// Fetch track details (API-B style). Uses same server: GET /tracks/:id if available.
  Future<TrackDetails?> getTrackDetails(String trackId) async {
    await _ensureOnline();
    final uri = Uri.parse('$_base${ApiConstants.trackDetailsPath(trackId)}');
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TrackRepositoryException(
          'NO INTERNET CONNECTION',
          offline: true,
        ),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw TrackRepositoryException(
          'Failed to load details: ${response.statusCode}',
          offline: false,
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (body == null) return null;
      return TrackDetails.fromJson(body);
    } on http.ClientException {
      throw TrackRepositoryException(
        'NO INTERNET CONNECTION',
        offline: true,
      );
    } on FormatException {
      return null;
    }
  }

  /// Fetch lyrics (API-C style). GET /tracks/:id/lyrics
  /// Never throws: returns null on any failure so track details can still load.
  /// Parses multiple response shapes: { lyrics }, nested { data: { lyrics } }, raw text, etc.
  Future<String?> getTrackLyrics(String trackId) async {
    await _ensureOnline();
    final uri = Uri.parse('$_base${ApiConstants.trackLyricsPath(trackId)}');
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TrackRepositoryException(
          'NO INTERNET CONNECTION',
          offline: true,
        ),
      );
      // Do not throw on 404/5xx – return null so details screen still shows
      if (response.statusCode != 200) return null;

      final raw = response.body.trim();
      if (raw.isEmpty) return null;

      // Plain text response
      if (!raw.startsWith('{') && !raw.startsWith('[')) {
        return raw;
      }

      final body = jsonDecode(response.body);

      // Direct string (e.g. JSON string value)
      if (body is String) return body.isNotEmpty ? body : null;

      // Object: try top-level and nested keys
      if (body is Map<String, dynamic>) {
        final fromMap = _extractLyricsFromMap(body);
        if (fromMap != null && fromMap.isNotEmpty) return fromMap;
      }

      if (body is Map) {
        final fromMap = _extractLyricsFromMap(Map<String, dynamic>.from(body));
        if (fromMap != null && fromMap.isNotEmpty) return fromMap;
      }

      // Array of lines (strings or objects with line/text)
      if (body is List && body.isNotEmpty) {
        final parts = <String>[];
        for (final e in body) {
          if (e is String) {
            if (e.trim().isNotEmpty) parts.add(e.trim());
          } else if (e is Map) {
            final m = Map<String, dynamic>.from(e);
            final line = m['line'] ?? m['text'] ?? m['lyric'] ?? m['body'];
            if (line is String && line.trim().isNotEmpty) parts.add(line.trim());
          } else {
            final s = e?.toString() ?? '';
            if (s.trim().isNotEmpty) parts.add(s.trim());
          }
        }
        if (parts.isNotEmpty) return parts.join('\n');
      }

      return null;
    } on http.ClientException {
      rethrow; // Preserve offline so bloc can show connection error
    } on TrackRepositoryException {
      rethrow;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Recursively extract lyrics string from a map (handles nested objects).
  static String? _extractLyricsFromMap(Map<String, dynamic> map) {
    const keys = [
      'lyrics', 'lyrics_body', 'body', 'text', 'content', 'lyric',
      'message', 'result', 'value', 'snippet', 'lyric_text', 'song_lyrics',
    ];
    for (final key in keys) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      // Nested: e.g. { "lyrics": { "body": "..." } }
      if (v is Map) {
        final nested = _extractLyricsFromMap(Map<String, dynamic>.from(v));
        if (nested != null && nested.isNotEmpty) return nested;
      }
      // List of lines
      if (v is List && v.isNotEmpty && v.first is String) {
        final lines = v.map((e) => e is String ? e : e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        if (lines.isNotEmpty) return lines.join('\n');
      }
    }
    return null;
  }

  /// Build details from a [Track] when details API is not available.
  TrackDetails detailsFromTrack(Track track) {
    return TrackDetails(
      trackId: track.trackId,
      title: track.title,
      artistName: track.artistName,
      albumTitle: track.albumTitle,
      durationSeconds: track.duration,
      previewUrl: track.previewUrl,
      coverUrl: track.coverUrl,
      lyrics: null,
    );
  }
}
