import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';

class RibbonClipper extends CustomClipper<Path> {
  const RibbonClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    const double notchHeight = 8.0;
    const double r = 3.0;

    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - notchHeight);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BibleRibbonsWidget extends StatelessWidget {
  final List<BibleRibbonBookmark>? bookmarks;
  final void Function(int ribbonIndex, BibleRibbonBookmark? bookmark)
  onRibbonTap;
  final void Function(int ribbonIndex) onRibbonLongPress;

  static const List<Color> ribbonColors = [
    AppThemeTokens.liturgicalRed,
    AppThemeTokens.liturgicalGold,
    AppThemeTokens.liturgicalGreen,
    AppThemeTokens.liturgicalPurple,
  ];

  static const List<String> ribbonNames = [
    'Red Ribbon',
    'Gold Ribbon',
    'Green Ribbon',
    'Purple Ribbon',
  ];

  const BibleRibbonsWidget({
    super.key,
    this.bookmarks,
    required this.onRibbonTap,
    required this.onRibbonLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (index) {
          BibleRibbonBookmark? bookmark;
          if (bookmarks != null) {
            for (final b in bookmarks!) {
              if (b.ribbonIndex == index) {
                bookmark = b;
                break;
              }
            }
          }

          final isAssigned = bookmark != null;
          final color = ribbonColors[index];
          final ribbonName = ribbonNames[index];

          final String tooltipMessage;
          if (isAssigned) {
            final book =
                catholicBooksByNumber[bookmark.bookNumber] ??
                catholicBooks.first;
            tooltipMessage =
                '$ribbonName: ${book.bookName} ${bookmark.chapter}';
          } else {
            tooltipMessage =
                'Ribbon ${index + 1}: Unassigned (Long press to set)';
          }

          return Tooltip(
            message: tooltipMessage,
            triggerMode: TooltipTriggerMode.manual,
            child: GestureDetector(
              key: Key('bible_ribbon_$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onRibbonTap(index, bookmark),
              onLongPress: () => onRibbonLongPress(index),
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0.0 : 3.0,
                  right: index == 3 ? 16.0 : 3.0,
                ),
                child: PhysicalShape(
                  clipper: const RibbonClipper(),
                  clipBehavior: Clip.antiAlias,
                  elevation: isAssigned ? 2.0 : 0.0,
                  shadowColor: Colors.black45,
                  color: isAssigned ? color : color.withValues(alpha: 0.35),
                  child: const SizedBox(width: 16.0, height: 38.0),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PageRibbonClipper extends CustomClipper<Path> {
  const PageRibbonClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    const double notchHeight = 8.0;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - notchHeight);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _RibbonPatternCacheKey {
  final int ribbonIndex;
  final double width;
  final double height;

  const _RibbonPatternCacheKey(this.ribbonIndex, this.width, this.height);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RibbonPatternCacheKey &&
          ribbonIndex == other.ribbonIndex &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(ribbonIndex, width, height);
}

class _CachedRibbonPattern {
  final Float32List edgePoints;
  final Float32List stripeLines;
  final Path? vinePath1;
  final Path? vinePath2;

  const _CachedRibbonPattern({
    required this.edgePoints,
    required this.stripeLines,
    this.vinePath1,
    this.vinePath2,
  });
}

class PageRibbonPatternPainter extends CustomPainter {
  final int ribbonIndex;
  final Color stripeColor;
  final Color edgeColor;

  static const int _maxCacheEntries = 16;
  static final Map<_RibbonPatternCacheKey, _CachedRibbonPattern> _patternCache =
      {};

  const PageRibbonPatternPainter({
    this.ribbonIndex = 0,
    this.stripeColor = const Color(0x24FFFFFF),
    this.edgeColor = const Color(0x1A000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || size.height.isInfinite) return;

    final normalizedIndex = (ribbonIndex >= 1 && ribbonIndex <= 3)
        ? ribbonIndex
        : 0;
    final key = _RibbonPatternCacheKey(
      normalizedIndex,
      size.width,
      size.height,
    );

    var cached = _patternCache.remove(key);
    if (cached != null) {
      _patternCache[key] = cached;
    } else {
      cached = _buildPattern(normalizedIndex, size);
      if (_patternCache.length >= _maxCacheEntries) {
        _patternCache.remove(_patternCache.keys.first);
      }
      _patternCache[key] = cached;
    }

    final edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRawPoints(PointMode.lines, cached.edgePoints, edgePaint);

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRawPoints(PointMode.lines, cached.stripeLines, stripePaint);

    if (cached.vinePath1 != null && cached.vinePath2 != null) {
      canvas.drawPath(cached.vinePath1!, stripePaint);
      canvas.drawPath(cached.vinePath2!, stripePaint);
    }
  }

  static _CachedRibbonPattern _buildPattern(int normalizedIndex, Size size) {
    const double edgeInset = 1.5;
    final edgePoints = Float32List(8)
      ..[0] = edgeInset
      ..[1] = 0.0
      ..[2] = edgeInset
      ..[3] = size.height
      ..[4] = size.width - edgeInset
      ..[5] = 0.0
      ..[6] = size.width - edgeInset
      ..[7] = size.height;

    switch (normalizedIndex) {
      case 1:
        return _CachedRibbonPattern(
          edgePoints: edgePoints,
          stripeLines: _buildGoldDiamondBrocadeLines(size),
        );
      case 2:
        return _buildGreenVineWeavePattern(edgePoints, size);
      case 3:
        return _CachedRibbonPattern(
          edgePoints: edgePoints,
          stripeLines: _buildPurpleCrossLatticeLines(size),
        );
      case 0:
      default:
        return _CachedRibbonPattern(
          edgePoints: edgePoints,
          stripeLines: _buildRedChevronTwillLines(size),
        );
    }
  }

  static Float32List _buildRedChevronTwillLines(Size size) {
    const double edgeInset = 1.5;
    final double midX = size.width / 2;
    const double step = 7.0;
    const double chevronHeight = 5.0;

    final int count = ((size.height + 2 * chevronHeight) / step).floor() + 1;
    final points = Float32List(count * 8);
    int i = 0;

    for (
      double y = -chevronHeight;
      y <= size.height + chevronHeight;
      y += step
    ) {
      points[i++] = edgeInset;
      points[i++] = y;
      points[i++] = midX;
      points[i++] = y + chevronHeight;

      points[i++] = size.width - edgeInset;
      points[i++] = y;
      points[i++] = midX;
      points[i++] = y + chevronHeight;
    }

    return i == points.length ? points : Float32List.sublistView(points, 0, i);
  }

  static Float32List _buildGoldDiamondBrocadeLines(Size size) {
    const double edgeInset = 1.5;
    final double midX = size.width / 2;
    const double step = 12.0;

    final int count = ((size.height + 2 * step) / step).floor() + 1;
    final points = Float32List(count * 12);
    int i = 0;

    for (double y = -step; y <= size.height + step; y += step) {
      points[i++] = edgeInset;
      points[i++] = y;
      points[i++] = size.width - edgeInset;
      points[i++] = y + step;

      points[i++] = size.width - edgeInset;
      points[i++] = y;
      points[i++] = edgeInset;
      points[i++] = y + step;

      points[i++] = midX - 1.5;
      points[i++] = y;
      points[i++] = midX + 1.5;
      points[i++] = y;
    }

    return i == points.length ? points : Float32List.sublistView(points, 0, i);
  }

  static _CachedRibbonPattern _buildGreenVineWeavePattern(
    Float32List edgePoints,
    Size size,
  ) {
    const double edgeInset = 1.5;
    final double midX = size.width / 2;
    const double cycle = 16.0;

    final path1 = Path();
    final path2 = Path();

    path1.moveTo(midX - 3.5, -cycle);
    path2.moveTo(midX + 3.5, -cycle);

    final int count = ((size.height + 2 * cycle) / cycle).floor() + 1;
    final leafPoints = Float32List(count * 8);
    int i = 0;

    for (double y = -cycle; y <= size.height + cycle; y += cycle) {
      path1.cubicTo(
        midX - 3.5,
        y + 4.0,
        midX + 3.5,
        y + 4.0,
        midX + 3.5,
        y + 8.0,
      );
      path2.cubicTo(
        midX + 3.5,
        y + 4.0,
        midX - 3.5,
        y + 4.0,
        midX - 3.5,
        y + 8.0,
      );

      path1.cubicTo(
        midX + 3.5,
        y + 12.0,
        midX - 3.5,
        y + 12.0,
        midX - 3.5,
        y + 16.0,
      );
      path2.cubicTo(
        midX - 3.5,
        y + 12.0,
        midX + 3.5,
        y + 12.0,
        midX + 3.5,
        y + 16.0,
      );

      leafPoints[i++] = midX - 3.5;
      leafPoints[i++] = y;
      leafPoints[i++] = edgeInset + 0.5;
      leafPoints[i++] = y - 2.5;

      leafPoints[i++] = midX + 3.5;
      leafPoints[i++] = y + 8.0;
      leafPoints[i++] = size.width - edgeInset - 0.5;
      leafPoints[i++] = y + 8.0 - 2.5;
    }

    return _CachedRibbonPattern(
      edgePoints: edgePoints,
      stripeLines: i == leafPoints.length
          ? leafPoints
          : Float32List.sublistView(leafPoints, 0, i),
      vinePath1: path1,
      vinePath2: path2,
    );
  }

  static Float32List _buildPurpleCrossLatticeLines(Size size) {
    const double edgeInset = 1.5;
    final double midX = size.width / 2;
    const double cycle = 18.0;

    final int count = ((size.height + 2 * cycle) / cycle).floor() + 1;
    final points = Float32List(count * 20);
    int i = 0;

    for (double y = -cycle; y <= size.height + cycle; y += cycle) {
      points[i++] = edgeInset + 1.0;
      points[i++] = y;
      points[i++] = size.width - edgeInset - 1.0;
      points[i++] = y;

      points[i++] = midX;
      points[i++] = y + 2.0;
      points[i++] = midX;
      points[i++] = y + 14.0;

      points[i++] = midX - 4.0;
      points[i++] = y + 6.0;
      points[i++] = midX + 4.0;
      points[i++] = y + 6.0;

      points[i++] = midX - 4.0;
      points[i++] = y + 5.0;
      points[i++] = midX - 4.0;
      points[i++] = y + 7.0;

      points[i++] = midX + 4.0;
      points[i++] = y + 5.0;
      points[i++] = midX + 4.0;
      points[i++] = y + 7.0;
    }

    return i == points.length ? points : Float32List.sublistView(points, 0, i);
  }

  @override
  bool shouldRepaint(covariant PageRibbonPatternPainter oldDelegate) {
    return oldDelegate.ribbonIndex != ribbonIndex ||
        oldDelegate.stripeColor != stripeColor ||
        oldDelegate.edgeColor != edgeColor;
  }
}

class BiblePageRibbon extends StatelessWidget {
  final int ribbonIndex;

  const BiblePageRibbon({super.key, required this.ribbonIndex});

  @override
  Widget build(BuildContext context) {
    final color =
        (ribbonIndex >= 0 &&
            ribbonIndex < BibleRibbonsWidget.ribbonColors.length)
        ? BibleRibbonsWidget.ribbonColors[ribbonIndex]
        : BibleRibbonsWidget.ribbonColors[0];

    return RepaintBoundary(
      child: PhysicalShape(
        key: Key('bible_page_ribbon_$ribbonIndex'),
        clipper: const PageRibbonClipper(),
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        shadowColor: Colors.black38,
        color: color,
        child: SizedBox(
          width: 16.0,
          height: double.infinity,
          child: CustomPaint(
            isComplex: true,
            willChange: false,
            painter: PageRibbonPatternPainter(
              ribbonIndex: ribbonIndex,
              stripeColor: Colors.white.withValues(alpha: 0.14),
              edgeColor: Colors.black.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
    );
  }
}

class BiblePageRibbonsWidget extends StatelessWidget {
  final List<BibleRibbonBookmark>? bookmarks;
  final int bookNumber;
  final int chapter;
  final double top;
  final double bottom;
  final double left;
  final double width;

  static const List<Color> ribbonColors = BibleRibbonsWidget.ribbonColors;

  const BiblePageRibbonsWidget({
    super.key,
    this.bookmarks,
    required this.bookNumber,
    required this.chapter,
    this.top = 0.0,
    this.bottom = 0.0,
    this.left = 4.0,
    this.width = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    BibleRibbonBookmark? matchingBookmark;
    if (bookmarks != null && bookmarks!.isNotEmpty) {
      for (final b in bookmarks!) {
        if (b.bookNumber == bookNumber && b.chapter == chapter) {
          matchingBookmark = b;
          break;
        }
      }
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      width: width,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[...previousChildren, ?currentChild],
            );
          },
          child: matchingBookmark != null
              ? BiblePageRibbon(
                  key: ValueKey<int>(matchingBookmark.ribbonIndex),
                  ribbonIndex: matchingBookmark.ribbonIndex,
                )
              : const SizedBox.shrink(key: ValueKey<String>('empty')),
        ),
      ),
    );
  }
}
