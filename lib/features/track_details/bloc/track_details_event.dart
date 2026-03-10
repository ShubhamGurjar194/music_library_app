part of 'track_details_bloc.dart';

abstract class TrackDetailsEvent extends Equatable {
  const TrackDetailsEvent();

  @override
  List<Object?> get props => [];
}

class TrackDetailsLoadRequested extends TrackDetailsEvent {
  const TrackDetailsLoadRequested({
    required this.trackId,
    this.track,
  });
  final String trackId;
  final Track? track;

  @override
  List<Object?> get props => [trackId, track];
}
