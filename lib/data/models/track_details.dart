import 'package:equatable/equatable.dart';

/// Extended track details (API-B) and lyrics (API-C) for the details screen.
class TrackDetails extends Equatable {
  const TrackDetails({
    required this.trackId,
    required this.title,
    required this.artistName,
    this.albumTitle,
    this.durationSeconds,
    this.previewUrl,
    this.coverUrl,
    this.lyrics,
  });

  final String trackId;
  final String title;
  final String artistName;
  final String? albumTitle;
  final int? durationSeconds;
  final String? previewUrl;
  final String? coverUrl;
  final String? lyrics;

  /// Tries common keys and nested objects (e.g. lyrics.body) for lyrics.
  static String? _lyricsFromJson(Map<String, dynamic> json) {
    const keys = ['lyrics', 'lyrics_body', 'body', 'text', 'lyric', 'content', 'message', 'lyric_text'];
    for (final key in keys) {
      final v = json[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map) {
        final nested = _lyricsFromJson(Map<String, dynamic>.from(v));
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  factory TrackDetails.fromJson(Map<String, dynamic> json) {
    // Unwrap if response is { "track": {...} } or { "data": {...} }
    final data = (json['track'] is Map
            ? Map<String, dynamic>.from(json['track'] as Map)
            : null) ??
        (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null) ??
        json;

    return TrackDetails(
      trackId: (data['id'] ?? data['track_id'])?.toString() ?? '',
      title: data['title'] as String? ?? '',
      artistName: (data['artist'] is Map
              ? (data['artist']['name'] as String?)
              : data['artist_name'] as String?) ??
          '',
      albumTitle: data['album'] is Map
          ? (data['album']['title'] as String?)
          : data['album_title'] as String?,
      durationSeconds: (data['duration'] as num?)?.toInt(),
      previewUrl: data['preview'] as String?,
      coverUrl: data['cover'] as String? ?? (data['album'] is Map ? data['album']['cover'] as String? : null),
      lyrics: _lyricsFromJson(data) ?? _lyricsFromJson(json),
    );
  }

  @override
  List<Object?> get props => [trackId, title, artistName, lyrics];
}
