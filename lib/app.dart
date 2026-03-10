import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/track_repository.dart';
import 'features/library/bloc/library_bloc.dart';
import 'features/library/screens/library_screen.dart';

class MusicLibraryApp extends StatelessWidget {
  const MusicLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<TrackRepository>(
      create: (_) => TrackRepository(),
      child: BlocProvider(
        create: (context) => LibraryBloc(context.read<TrackRepository>()),
        child: MaterialApp(
          title: 'Music Library',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: const LibraryScreen(),
        ),
      ),
    );
  }
}
