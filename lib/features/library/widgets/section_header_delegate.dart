import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Persistent sticky header for a section letter. Triggers [onVisible] when first visible.
class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  SectionHeaderDelegate({
    required this.letter,
    required this.onVisible,
  });

  final String letter;
  final VoidCallback? onVisible;

  static const double headerHeight = 48.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return VisibilityDetector(
      key: Key('header_$letter'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1) onVisible?.call();
      },
      child: Container(
        height: headerHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
        ),
        child: Text(
          letter.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.2,
              ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => headerHeight;

  @override
  double get minExtent => headerHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      oldDelegate is SectionHeaderDelegate && oldDelegate.letter != letter;
}
