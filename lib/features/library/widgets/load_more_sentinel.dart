import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LoadMoreSentinel extends StatelessWidget {
  const LoadMoreSentinel({
    super.key,
    required this.sectionLetter,
    required this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
  });

  final String sectionLetter;
  final VoidCallback onLoadMore;
  final bool isLoading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();

    return VisibilityDetector(
      key: Key('load_more_$sectionLetter'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.2 && !isLoading) onLoadMore();
      },
      child: SizedBox(
        height: 56,
        child: Center(
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
