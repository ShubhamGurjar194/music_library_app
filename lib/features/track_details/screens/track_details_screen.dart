import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/track.dart';
import '../../../data/models/track_details.dart';
import '../../../data/repositories/track_repository.dart';
import '../bloc/track_details_bloc.dart';

class TrackDetailsScreen extends StatelessWidget {
  const TrackDetailsScreen({
    super.key,
    required this.track,
    this.repository,
  });

  final Track track;
  final TrackRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? context.read<TrackRepository>();

    return BlocProvider(
      create: (_) => TrackDetailsBloc(repo)
        ..add(TrackDetailsLoadRequested(trackId: track.trackId, track: track)),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.library_music_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Track Details'),
            ],
          ),
        ),
        body: BlocBuilder<TrackDetailsBloc, TrackDetailsState>(
          builder: (context, state) {
            switch (state.status) {
              case TrackDetailsStatus.initial:
              case TrackDetailsStatus.loading:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading track details…',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              case TrackDetailsStatus.error:
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding(context) + 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage ?? 'Something went wrong',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (state.errorMessage == 'NO INTERNET CONNECTION') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Please check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              case TrackDetailsStatus.loaded:
                return _DetailsContent(details: state.details!);
            }
          },
        ),
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.details});

  final TrackDetails details;

  static double _coverSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppTheme.breakpointDesktop) return 280;
    if (width >= AppTheme.breakpointTablet) return 240;
    return 200;
  }

  @override
  Widget build(BuildContext context) {
    final d = details;
    final theme = Theme.of(context);
    final padding = AppTheme.horizontalPadding(context);
    final coverSize = _coverSize(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (d.coverUrl != null && d.coverUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    d.coverUrl!,
                    width: coverSize,
                    height: coverSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PlaceholderArt(size: coverSize),
                  ),
                )
              else
                _PlaceholderArt(size: coverSize),
              SizedBox(height: coverSize * 0.12),
              Text(
                d.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.artistName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Track ID', value: d.trackId, mono: true),
                    if (d.albumTitle != null && d.albumTitle!.isNotEmpty)
                      _DetailRow(label: 'Album', value: d.albumTitle!),
                    if (d.durationSeconds != null)
                      _DetailRow(
                        label: 'Duration',
                        value: '${d.durationSeconds! ~/ 60}:${(d.durationSeconds! % 60).toString().padLeft(2, '0')}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lyrics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: d.lyrics != null && d.lyrics!.isNotEmpty
                    ? SelectableText(
                        d.lyrics!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      )
                    : Text(
                        'Lyrics not available for this track.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderArt extends StatelessWidget {
  const _PlaceholderArt({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.album_rounded,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}
