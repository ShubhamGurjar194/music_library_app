part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Load first page of tracks for a section (letter a-z, 0-9).
class LibraryLoadSection extends LibraryEvent {
  const LibraryLoadSection(this.letter);
  final String letter;

  @override
  List<Object?> get props => [letter];
}

/// Load next page for a section (infinite scroll).
class LibraryLoadMoreSection extends LibraryEvent {
  const LibraryLoadMoreSection(this.letter);
  final String letter;

  @override
  List<Object?> get props => [letter];
}

/// User scrolled and a section header became visible — trigger load if needed.
class LibrarySectionVisibilityChanged extends LibraryEvent {
  const LibrarySectionVisibilityChanged(this.letter);
  final String letter;

  @override
  List<Object?> get props => [letter];
}

/// Search with query (debounced in UI).
class LibrarySearch extends LibraryEvent {
  const LibrarySearch(this.query);
  final String? query;

  @override
  List<Object?> get props => [query];
}

/// Load more search results (infinite scroll in search mode).
class LibrarySearchLoadMore extends LibraryEvent {
  const LibrarySearchLoadMore();
}

/// Clear search and show sectioned list again.
class LibraryClearSearch extends LibraryEvent {
  const LibraryClearSearch();
}
