import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/track.dart';
import '../../../data/models/track_details.dart';
import '../../../data/repositories/track_repository.dart';

part 'track_details_event.dart';
part 'track_details_state.dart';

class TrackDetailsBloc extends Bloc<TrackDetailsEvent, TrackDetailsState> {
  TrackDetailsBloc(this._repository) : super(const TrackDetailsState.initial()) {
    on<TrackDetailsLoadRequested>(_onLoadRequested);
  }

  final TrackRepository _repository;

  Future<void> _onLoadRequested(
    TrackDetailsLoadRequested event,
    Emitter<TrackDetailsState> emit,
  ) async {
    final trackId = event.trackId;
    final track = event.track;

    emit(const TrackDetailsState.loading());

    try {
      TrackDetails? details;
      String? lyrics;

      try {
        details = await _repository.getTrackDetails(trackId);
      } on TrackRepositoryException catch (e) {
        if (e.offline) {
          emit(TrackDetailsState.error(e.message));
          return;
        }
        rethrow;
      }

      try {
        lyrics = await _repository.getTrackLyrics(trackId);
      } on TrackRepositoryException catch (e) {
        if (e.offline) {
          emit(TrackDetailsState.error(e.message));
          return;
        }
        lyrics = null;
      } catch (_) {
        lyrics = null;
      }

      if (details == null && track != null) {
        details = _repository.detailsFromTrack(track);
      }
      if (details == null) {
        emit(const TrackDetailsState.error('Track not found'));
        return;
      }
      final mergedLyrics = (lyrics != null && lyrics.isNotEmpty)
          ? lyrics
          : details.lyrics;
      if (mergedLyrics != null && mergedLyrics.isNotEmpty) {
        details = TrackDetails(
          trackId: details.trackId,
          title: details.title,
          artistName: details.artistName,
          albumTitle: details.albumTitle,
          durationSeconds: details.durationSeconds,
          previewUrl: details.previewUrl,
          coverUrl: details.coverUrl,
          lyrics: mergedLyrics,
        );
      }

      emit(TrackDetailsState.loaded(details));
    } on TrackRepositoryException catch (e) {
      emit(TrackDetailsState.error(e.message));
    } catch (_) {
      emit(const TrackDetailsState.error('Failed to load track details'));
    }
  }
}
