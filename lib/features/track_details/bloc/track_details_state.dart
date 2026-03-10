part of 'track_details_bloc.dart';

enum TrackDetailsStatus { initial, loading, loaded, error }

class TrackDetailsState extends Equatable {
  const TrackDetailsState._({
    this.status = TrackDetailsStatus.initial,
    this.details,
    this.errorMessage,
  });

  const TrackDetailsState.initial()
      : this._(status: TrackDetailsStatus.initial);

  const TrackDetailsState.loading()
      : this._(status: TrackDetailsStatus.loading);

  const TrackDetailsState.loaded(TrackDetails d)
      : this._(status: TrackDetailsStatus.loaded, details: d);

  const TrackDetailsState.error(String message)
      : this._(status: TrackDetailsStatus.error, errorMessage: message);

  final TrackDetailsStatus status;
  final TrackDetails? details;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, details, errorMessage];
}
