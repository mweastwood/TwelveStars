import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A horizontal swipeable carousel for displaying the Nicene Creed and
/// Apostles' Creed with matching full card width.
class MissalCreedCarousel extends StatefulWidget {
  final Widget? niceneCard;
  final Widget? apostlesCard;
  final PageController? controller;
  final ValueChanged<int>? onPageChanged;

  const MissalCreedCarousel({
    super.key,
    this.niceneCard,
    this.apostlesCard,
    this.controller,
    this.onPageChanged,
  });

  @override
  State<MissalCreedCarousel> createState() => _MissalCreedCarouselState();
}

class _MissalCreedCarouselState extends State<MissalCreedCarousel> {
  late final PageController _pageController;
  bool _ownsController = false;
  final Map<int, double> _cardHeights = {};

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _pageController = widget.controller!;
    } else {
      _pageController = PageController(initialPage: 0);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _onHeightMeasured(int index, double height) {
    if ((_cardHeights[index] ?? 0.0) != height) {
      setState(() {
        _cardHeights[index] = height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.niceneCard == null && widget.apostlesCard == null) {
      return const SizedBox.shrink();
    }

    if (widget.niceneCard != null && widget.apostlesCard == null) {
      return widget.niceneCard!;
    }

    if (widget.niceneCard == null && widget.apostlesCard != null) {
      return widget.apostlesCard!;
    }

    final calculatedHeight = _cardHeights.values.isEmpty
        ? 450.0
        : _cardHeights.values.fold<double>(0.0, math.max);

    return SizedBox(
      height: calculatedHeight,
      child: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (page) {
          widget.onPageChanged?.call(page);
        },
        children: [
          _buildPageItem(0, widget.niceneCard!),
          _buildPageItem(1, widget.apostlesCard!),
        ],
      ),
    );
  }

  Widget _buildPageItem(int index, Widget card) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: _HeightReporter(
        onHeightChanged: (h) => _onHeightMeasured(index, h),
        child: card,
      ),
    );
  }
}

class _HeightReporter extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onHeightChanged;

  const _HeightReporter({required this.child, required this.onHeightChanged});

  @override
  State<_HeightReporter> createState() => _HeightReporterState();
}

class _HeightReporterState extends State<_HeightReporter> {
  final GlobalKey _key = GlobalKey();
  double? _lastReportedHeight;

  @override
  void initState() {
    super.initState();
    _reportHeight();
  }

  @override
  void didUpdateWidget(covariant _HeightReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reportHeight();
  }

  void _reportHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final height = renderBox.size.height;
        if (height > 0 && height != _lastReportedHeight) {
          _lastReportedHeight = height;
          widget.onHeightChanged(height);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _key, child: widget.child);
  }
}
