import 'package:flutter/material.dart';

/// A two-column sliver list using [SliverCrossAxisGroup] that distributes even
/// indices (`0, 2, 4, ...`) to the left column and odd indices (`1, 3, 5, ...`)
/// to the right column.
class TwoColumnSliverList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double crossAxisSpacing;

  const TwoColumnSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisSpacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverCrossAxisGroup(
      slivers: [
        SliverCrossAxisExpanded(
          flex: 1,
          sliver: SliverList.builder(
            itemCount: (itemCount + 1) ~/ 2,
            itemBuilder: (context, index) => itemBuilder(context, index * 2),
          ),
        ),
        SliverConstrainedCrossAxis(
          maxExtent: crossAxisSpacing,
          sliver: const SliverToBoxAdapter(),
        ),
        SliverCrossAxisExpanded(
          flex: 1,
          sliver: SliverList.builder(
            itemCount: itemCount ~/ 2,
            itemBuilder: (context, index) =>
                itemBuilder(context, index * 2 + 1),
          ),
        ),
      ],
    );
  }
}
