import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/track.dart';
import '../../../data/repositories/track_repository.dart';

part 'library_event.dart';
part 'library_state.dart';

const List<String> sectionOrder = [
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
];

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc(this._repository) : super(const LibraryState()) {
    on<LibraryLoadSection>(_onLoadSection);
    on<LibraryLoadMoreSection>(_onLoadMoreSection);
    on<LibrarySearch>(_onSearch);
    on<LibrarySearchLoadMore>(_onSearchLoadMore);
    on<LibraryClearSearch>(_onClearSearch);
    on<LibrarySectionVisibilityChanged>(_onSectionVisibilityChanged);
  }

  final TrackRepository _repository;

  Future<void> _onLoadSection(
    LibraryLoadSection event,
    Emitter<LibraryState> emit,
  ) async {
    final letter = event.letter.toLowerCase();
    if (letter.isEmpty) return;
    final current = state;
    if (current.sectionTracks[letter] != null && current.sectionTracks[letter]!.isNotEmpty) {
      return;
    }
    if (current.sectionLoading[letter] == true) return;

    emit(current.copyWith(
      sectionLoading: {...current.sectionLoading, letter: true},
      errorMessage: null,
    ));

    try {
      final result = await _repository.getTracks(
        query: letter,
        index: 0,
        limit: 50,
      );
      final nextIndex = result.tracks.length;
      final hasMore = result.hasMore && result.tracks.length >= 50;

      emit(state.copyWith(
        sectionTracks: {...state.sectionTracks, letter: result.tracks},
        sectionNextIndex: {...state.sectionNextIndex, letter: nextIndex},
        sectionHasMore: {...state.sectionHasMore, letter: hasMore},
        sectionLoading: {...state.sectionLoading, letter: false},
        errorMessage: null,
      ));
    } on TrackRepositoryException catch (e) {
      emit(state.copyWith(
        sectionLoading: {...state.sectionLoading, letter: false},
        errorMessage: e.message,
        offline: e.offline,
      ));
    } catch (_) {
      emit(state.copyWith(
        sectionLoading: {...state.sectionLoading, letter: false},
        errorMessage: 'Failed to load section',
      ));
    }
  }

  Future<void> _onLoadMoreSection(
    LibraryLoadMoreSection event,
    Emitter<LibraryState> emit,
  ) async {
    final letter = event.letter.toLowerCase();
    final current = state;
    final tracks = current.sectionTracks[letter];
    if (tracks == null) return;
    if (current.sectionHasMore[letter] != true) return;
    if (current.sectionLoading[letter] == true) return;

    final index = current.sectionNextIndex[letter] ?? tracks.length;

    emit(state.copyWith(
      sectionLoading: {...state.sectionLoading, letter: true},
      errorMessage: null,
    ));

    try {
      final result = await _repository.getTracks(
        query: letter,
        index: index,
        limit: 50,
      );
      final newList = [...tracks, ...result.tracks];
      final nextIndex = index + result.tracks.length;
      final hasMore = result.hasMore && result.tracks.length >= 50;

      emit(state.copyWith(
        sectionTracks: {...state.sectionTracks, letter: newList},
        sectionNextIndex: {...state.sectionNextIndex, letter: nextIndex},
        sectionHasMore: {...state.sectionHasMore, letter: hasMore},
        sectionLoading: {...state.sectionLoading, letter: false},
        errorMessage: null,
      ));
    } on TrackRepositoryException catch (e) {
      emit(state.copyWith(
        sectionLoading: {...state.sectionLoading, letter: false},
        errorMessage: e.message,
        offline: e.offline,
      ));
    } catch (_) {
      emit(state.copyWith(
        sectionLoading: {...state.sectionLoading, letter: false},
        errorMessage: 'Failed to load more',
      ));
    }
  }

  void _onSectionVisibilityChanged(
    LibrarySectionVisibilityChanged event,
    Emitter<LibraryState> emit,
  ) {
    add(LibraryLoadSection(event.letter));
  }

  Future<void> _onSearch(
    LibrarySearch event,
    Emitter<LibraryState> emit,
  ) async {
    final query = (event.query ?? '').trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        searchResults: const [],
        searchNextIndex: 0,
        searchHasMore: false,
        searchLoading: false,
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(
      searchQuery: query,
      searchResults: const [],
      searchNextIndex: 0,
      searchHasMore: true,
      searchLoading: true,
      errorMessage: null,
    ));

    try {
      final result = await _repository.getTracks(
        query: query,
        index: 0,
        limit: 50,
      );
      emit(state.copyWith(
        searchResults: result.tracks,
        searchNextIndex: result.tracks.length,
        searchHasMore: result.hasMore && result.tracks.length >= 50,
        searchLoading: false,
        errorMessage: null,
      ));
    } on TrackRepositoryException catch (e) {
      emit(state.copyWith(
        searchLoading: false,
        searchHasMore: false,
        errorMessage: e.message,
        offline: e.offline,
      ));
    } catch (_) {
      emit(state.copyWith(
        searchLoading: false,
        searchHasMore: false,
        errorMessage: 'Search failed',
      ));
    }
  }

  Future<void> _onSearchLoadMore(
    LibrarySearchLoadMore event,
    Emitter<LibraryState> emit,
  ) async {
    final query = state.searchQuery;
    if (query.isEmpty) return;
    if (state.searchLoading || !state.searchHasMore) return;

    final index = state.searchNextIndex;
    emit(state.copyWith(searchLoading: true, errorMessage: null));

    try {
      final result = await _repository.getTracks(
        query: query,
        index: index,
        limit: 50,
      );
      final newList = [...state.searchResults, ...result.tracks];
      emit(state.copyWith(
        searchResults: newList,
        searchNextIndex: index + result.tracks.length,
        searchHasMore: result.hasMore && result.tracks.length >= 50,
        searchLoading: false,
        errorMessage: null,
      ));
    } on TrackRepositoryException catch (e) {
      emit(state.copyWith(
        searchLoading: false,
        errorMessage: e.message,
        offline: e.offline,
      ));
    } catch (_) {
      emit(state.copyWith(
        searchLoading: false,
        errorMessage: 'Failed to load more',
      ));
    }
  }

  void _onClearSearch(LibraryClearSearch event, Emitter<LibraryState> emit) {
    emit(state.copyWith(
      searchQuery: '',
      searchResults: const [],
      searchNextIndex: 0,
      searchHasMore: false,
      searchLoading: false,
      errorMessage: state.offline ? state.errorMessage : null,
    ));
  }
}
