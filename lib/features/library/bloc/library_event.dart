part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LibraryLoadSection extends LibraryEvent {
  const LibraryLoadSection(this.letter);
  final String letter;

  @override
  List<Object?> get props => [letter];
}

class LibraryLoadMoreSection extends LibraryEvent {
  const LibraryLoadMoreSection(this.letter);
  final String letter;

  @override
  List<Object?> get props => [letter];
}

class LibrarySectionVisibilityChanged extends LibraryEvent {
  const LibrarySectionVisibilityChanged(this.letter);
  final String letter;

  @override
  List<Object?> get props => [letter];
}

class LibrarySearch extends LibraryEvent {
  const LibrarySearch(this.query);
  final String? query;

  @override
  List<Object?> get props => [query];
}

class LibrarySearchLoadMore extends LibraryEvent {
  const LibrarySearchLoadMore();
}

class LibraryClearSearch extends LibraryEvent {
  const LibraryClearSearch();
}
