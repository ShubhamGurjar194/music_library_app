import 'package:equatable/equatable.dart';

class Track extends Equatable {
  const Track({
    required this.id,
    required this.title,
    required this.artistName,
    this.albumTitle,
    this.duration,
    this.previewUrl,
    this.coverUrl,
  });

  final int id;
  final String title;
  final String artistName;
  final String? albumTitle;
  final int? duration;
  final String? previewUrl;
  final String? coverUrl;

  String get trackId => id.toString();

  factory Track.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'];
    final artistName = artist is Map
        ? (artist['name'] as String? ?? '')
        : (json['artist_name'] as String? ?? '');
    return Track(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      artistName: artistName,
      albumTitle: json['album'] is Map
          ? (json['album']['title'] as String?)
          : json['album_title'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      previewUrl: json['preview'] as String?,
      coverUrl: (json['cover'] as String?) ??
          (json['album'] is Map ? (json['album']['cover'] as String?) : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist_name': artistName,
        'album_title': albumTitle,
        'duration': duration,
        'preview': previewUrl,
        'cover': coverUrl,
      };

  @override
  List<Object?> get props => [id, title, artistName];
}
