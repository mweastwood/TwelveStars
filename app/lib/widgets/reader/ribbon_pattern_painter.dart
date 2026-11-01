import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

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
  static const double _viewportCullThreshold = 512.0;
  static const double _heightBucketSize = 256.0;
  static final Map<_RibbonPatternCacheKey, _CachedRibbonPattern> _patternCache =
      {};

  const PageRibbonPatternPainter({
    this.ribbonIndex = 0,
    this.stripeColor = const Color(0x24FFFFFF),
    this.edgeColor = const Color(0x1A000000),
  });

  static double _periodForIndex(int normalizedIndex) {
    switch (normalizedIndex) {
      case 1:
        return 12.0;
      case 2:
        return 16.0;
      case 3:
        return 18.0;
      case 0:
      default:
        return 7.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || size.height.isInfinite) return;

    final normalizedIndex = (ribbonIndex >= 1 && ribbonIndex <= 3)
        ? ribbonIndex
        : 0;

    final clipBounds = canvas.getLocalClipBounds();
    final double visibleTop = clipBounds.top.isFinite
        ? clipBounds.top.clamp(0.0, size.height)
        : 0.0;
    final double visibleBottom = clipBounds.bottom.isFinite
        ? clipBounds.bottom.clamp(0.0, size.height)
        : size.height;
    if (visibleBottom <= visibleTop) return;

    double yOffset = 0.0;
    double patternHeight = size.height;
    final visibleSpan = visibleBottom - visibleTop;

    if (size.height > _viewportCullThreshold) {
      if (visibleSpan < size.height) {
        final period = _periodForIndex(normalizedIndex);
        final startCycle = (visibleTop / period).floor();
        if (startCycle > 0) {
          yOffset = startCycle * period;
        }
        final neededHeight = (visibleBottom - yOffset).clamp(
          1.0,
          size.height - yOffset,
        );
        patternHeight =
            ((neededHeight / _heightBucketSize).ceil() * _heightBucketSize)
                .clamp(_heightBucketSize, size.height);
      } else {
        patternHeight =
            (size.height / _heightBucketSize).ceil() * _heightBucketSize;
      }
    }

    final key = _RibbonPatternCacheKey(
      normalizedIndex,
      size.width,
      patternHeight,
    );

    var cached = _patternCache.remove(key);
    if (cached != null) {
      _patternCache[key] = cached;
    } else {
      cached = _buildPattern(normalizedIndex, Size(size.width, patternHeight));
      if (_patternCache.length >= _maxCacheEntries) {
        _patternCache.remove(_patternCache.keys.first);
      }
      _patternCache[key] = cached;
    }

    if (yOffset != 0.0 || patternHeight != size.height) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0.0, visibleTop, size.width, visibleSpan));
      if (yOffset != 0.0) {
        canvas.translate(0.0, yOffset);
      }
      _drawCachedPattern(canvas, cached);
      canvas.restore();
    } else {
      _drawCachedPattern(canvas, cached);
    }
  }

  void _drawCachedPattern(Canvas canvas, _CachedRibbonPattern cached) {
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
