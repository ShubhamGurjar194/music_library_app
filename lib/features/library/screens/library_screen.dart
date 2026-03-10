import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/track.dart';
import '../../../data/repositories/track_repository.dart';
import '../bloc/library_bloc.dart';
import '../widgets/load_more_sentinel.dart';
import '../widgets/section_header_delegate.dart';
import '../widgets/track_tile.dart';
import '../../track_details/screens/track_details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {}); // Rebuild so suffixIcon (clear button) updates.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (context.mounted) {
        context.read<LibraryBloc>().add(
              LibrarySearch(_searchController.text.trim()),
            );
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openTrackDetails(Track track) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrackDetailsScreen(
          track: track,
          repository: context.read<TrackRepository>(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding(context));
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.library_music, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 10),
            const Text('Music Library'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'Search tracks, artists…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context.read<LibraryBloc>().add(const LibraryClearSearch());
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                context.read<LibraryBloc>().add(LibrarySearch(value.trim()));
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        buildWhen: (a, b) =>
            a.sectionTracks != b.sectionTracks ||
            a.sectionLoading != b.sectionLoading ||
            a.sectionHasMore != b.sectionHasMore ||
            a.searchQuery != b.searchQuery ||
            a.searchResults != b.searchResults ||
            a.searchLoading != b.searchLoading ||
            a.searchHasMore != b.searchHasMore ||
            a.errorMessage != b.errorMessage ||
            a.offline != b.offline,
        builder: (context, state) {
          if (state.offline && state.errorMessage != null) {
            return _OfflineBanner(message: state.errorMessage!);
          }

          if (state.isSearchMode) {
            return _SearchResultsView(
              state: state,
              onTrackTap: _openTrackDetails,
            );
          }

          return _SectionedLibraryView(
            state: state,
            onTrackTap: _openTrackDetails,
          );
        },
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context).copyWith(
      left: AppTheme.horizontalPadding(context) + 24,
      right: AppTheme.horizontalPadding(context) + 24,
    );
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.state,
    required this.onTrackTap,
  });

  final LibraryState state;
  final void Function(Track) onTrackTap;

  @override
  Widget build(BuildContext context) {
    if (state.searchLoading && state.searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchQuery.isNotEmpty && state.searchResults.isEmpty && !state.searchLoading) {
      return Center(
        child: Text(
          'No results for "${state.searchQuery}"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final horizontalPadding = AppTheme.horizontalPadding(context);
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      itemCount: state.searchResults.length + (state.searchHasMore || state.searchLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.searchResults.length) {
          if (state.searchHasMore && !state.searchLoading) {
            context.read<LibraryBloc>().add(const LibrarySearchLoadMore());
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final track = state.searchResults[index];
        return TrackTile(
          track: track,
          onTap: () => onTrackTap(track),
        );
      },
    );
  }
}

class _SectionedLibraryView extends StatelessWidget {
  const _SectionedLibraryView({
    required this.state,
    required this.onTrackTap,
  });

  final LibraryState state;
  final void Function(Track) onTrackTap;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppTheme.horizontalPadding(context);
    return CustomScrollView(
      slivers: [
        if (state.errorMessage != null && !state.offline)
          SliverToBoxAdapter(
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.onErrorContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverMainAxisGroup(
            slivers: [
              for (final letter in sectionOrder) ..._sectionSlivers(context, letter),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _sectionSlivers(BuildContext context, String letter) {
    final bloc = context.read<LibraryBloc>();
    final tracks = state.sectionTracks[letter] ?? [];
    final hasMore = state.sectionHasMore[letter] ?? true;
    final loading = state.sectionLoading[letter] ?? false;

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: SectionHeaderDelegate(
          letter: letter,
          onVisible: () => bloc.add(LibraryLoadSection(letter)),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == tracks.length) {
              return LoadMoreSentinel(
                sectionLetter: letter,
                hasMore: hasMore,
                isLoading: loading,
                onLoadMore: () => bloc.add(LibraryLoadMoreSection(letter)),
              );
            }
            final track = tracks[index];
            return TrackTile(
              track: track,
              onTap: () => onTrackTap(track),
            );
          },
          childCount: tracks.length + (hasMore || loading ? 1 : 0),
        ),
      ),
    ];
  }
}
