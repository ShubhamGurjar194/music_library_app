part of 'library_bloc.dart';

class LibraryState extends Equatable {
  const LibraryState({
    this.sectionTracks = const {},
    this.sectionNextIndex = const {},
    this.sectionHasMore = const {},
    this.sectionLoading = const {},
    this.searchQuery = '',
    this.searchResults = const [],
    this.searchNextIndex = 0,
    this.searchHasMore = false,
    this.searchLoading = false,
    this.errorMessage,
    this.offline = false,
  });

  final Map<String, List<Track>> sectionTracks;
  final Map<String, int> sectionNextIndex;
  final Map<String, bool> sectionHasMore;
  final Map<String, bool> sectionLoading;
  final String searchQuery;
  final List<Track> searchResults;
  final int searchNextIndex;
  final bool searchHasMore;
  final bool searchLoading;
  final String? errorMessage;
  final bool offline;

  bool get isSearchMode => searchQuery.isNotEmpty;

  LibraryState copyWith({
    Map<String, List<Track>>? sectionTracks,
    Map<String, int>? sectionNextIndex,
    Map<String, bool>? sectionHasMore,
    Map<String, bool>? sectionLoading,
    String? searchQuery,
    List<Track>? searchResults,
    int? searchNextIndex,
    bool? searchHasMore,
    bool? searchLoading,
    String? errorMessage,
    bool? offline,
  }) {
    return LibraryState(
      sectionTracks: sectionTracks ?? this.sectionTracks,
      sectionNextIndex: sectionNextIndex ?? this.sectionNextIndex,
      sectionHasMore: sectionHasMore ?? this.sectionHasMore,
      sectionLoading: sectionLoading ?? this.sectionLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      searchNextIndex: searchNextIndex ?? this.searchNextIndex,
      searchHasMore: searchHasMore ?? this.searchHasMore,
      searchLoading: searchLoading ?? this.searchLoading,
      errorMessage: errorMessage,
      offline: offline ?? this.offline,
    );
  }

  @override
  List<Object?> get props => [
        sectionTracks,
        sectionNextIndex,
        sectionHasMore,
        sectionLoading,
        searchQuery,
        searchResults,
        searchNextIndex,
        searchHasMore,
        searchLoading,
        errorMessage,
        offline,
      ];
}
