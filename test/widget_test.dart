import 'package:flutter_test/flutter_test.dart';

import 'package:music_library_app/data/models/track.dart';

void main() {
  group('Track model', () {
    test('fromJson parses Deezer-style map', () {
      final json = {
        'id': 123,
        'title': 'Test Track',
        'artist': {'name': 'Test Artist'},
      };
      final track = Track.fromJson(json);
      expect(track.id, 123);
      expect(track.title, 'Test Track');
      expect(track.artistName, 'Test Artist');
      expect(track.trackId, '123');
    });

    test('fromJson handles flat artist_name', () {
      final json = {
        'id': 456,
        'title': 'Another',
        'artist_name': 'Flat Artist',
      };
      final track = Track.fromJson(json);
      expect(track.artistName, 'Flat Artist');
    });
  });
}
