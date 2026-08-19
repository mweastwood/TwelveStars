import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Physics that snaps horizontally to either 0.0 (Page 0 - Nicene Creed)
/// or maxScrollExtent (Page 1 - Apostles' Creed).
class CarouselSnapScrollPhysics extends ScrollPhysics {
  const CarouselSnapScrollPhysics({super.parent});

  @override
  CarouselSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CarouselSnapScrollPhysics(parent: buildParent(ancestor));
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    final maxScroll = position.maxScrollExtent;
    if (velocity < -tolerance.velocity) {
      return 0.0;
    } else if (velocity > tolerance.velocity) {
      return maxScroll;
    }
    if (position.pixels > maxScroll / 2) {
      return maxScroll;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// A horizontal swipeable carousel for displaying the Nicene Creed and
/// Apostles' Creed with edge peeking and tap-to-focus peeking cards.
///
/// When Nicene Creed (page 0) is shown, its left edge aligns with other cards,
/// and Apostles' Creed peeks in from the right edge.
/// When Apostles' Creed (page 1) is shown, its right edge aligns with other cards,
/// and Nicene Creed peeks in from the left edge.
/// Tapping a peeking card immediately brings that card into focus.
class MissalCreedCarousel extends StatefulWidget {
  final Widget? niceneCard;
  final Widget? apostlesCard;
  final ScrollController? controller;
  final ValueChanged<int>? onPageChanged;
  final double peekOffset;
  final double cardGap;
  final double horizontalPadding;
  final int initialPage;

  const MissalCreedCarousel({
    super.key,
    this.niceneCard,
    this.apostlesCard,
    this.controller,
    this.onPageChanged,
    this.peekOffset = 24.0,
    this.cardGap = 8.0,
    this.horizontalPadding = 16.0,
    this.initialPage = 0,
  });

  @override
  State<MissalCreedCarousel> createState() => _MissalCreedCarouselState();
}

class _MissalCreedCarouselState extends State<MissalCreedCarousel> {
  late ScrollController _scrollController;
  bool _ownsController = false;
  int _currentPage = 0;
  bool _isAnimating = false;
  final Map<int, double> _cardHeights = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _scrollController = widget.controller!;
      _ownsController = false;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
  }

  @override
  void didUpdateWidget(covariant MissalCreedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _scrollController.dispose();
      }
      _initController();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _scrollController.dispose();
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

  void _animateToPage(int index, double maxScrollExtent) {
    if (_currentPage == index && _scrollController.hasClients) {
      final currentOffset = _scrollController.offset;
      final target = index == 0 ? 0.0 : maxScrollExtent;
      if ((currentOffset - target).abs() < 1.0) return;
    }
    setState(() {
      _currentPage = index;
    });
    if (_scrollController.hasClients) {
      _isAnimating = true;
      final targetOffset = index == 0 ? 0.0 : maxScrollExtent;
      _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          )
          .then((_) {
            if (mounted) {
              _isAnimating = false;
            }
          });
    }
    widget.onPageChanged?.call(index);
  }

  void _updatePageFromOffset(double offset, double maxScrollExtent) {
    if (_isAnimating || maxScrollExtent <= 0) return;
    final page = (offset / maxScrollExtent).round().clamp(0, 1);
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      widget.onPageChanged?.call(page);
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

    final calculatedHeight =
        _cardHeights[_currentPage] ??
        (_cardHeights.values.isNotEmpty
            ? _cardHeights.values.fold<double>(0.0, math.max)
            : 450.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cardWidth = math.max(
          0.0,
          totalWidth -
              widget.horizontalPadding -
              widget.peekOffset -
              widget.cardGap,
        );
        final maxScrollExtent = math.max(
          0.0,
          totalWidth - 2 * widget.peekOffset - widget.cardGap,
        );
        final peekingTapWidth = widget.peekOffset + widget.cardGap;

        if (_currentPage == 1 &&
            _scrollController.hasClients &&
            !_isAnimating &&
            (_scrollController.offset - maxScrollExtent).abs() > 1.0 &&
            _scrollController.offset == 0.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients && _currentPage == 1) {
              _scrollController.jumpTo(maxScrollExtent);
            }
          });
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          height: calculatedHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    _updatePageFromOffset(
                      notification.metrics.pixels,
                      maxScrollExtent,
                    );
                  } else if (notification is ScrollEndNotification) {
                    _updatePageFromOffset(
                      notification.metrics.pixels,
                      maxScrollExtent,
                    );
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const CarouselSnapScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.horizontalPadding > 0)
                        SizedBox(width: widget.horizontalPadding),
                      // Page 0: Nicene Creed Card
                      SizedBox(
                        key: const Key('nicene_card_wrapper'),
                        width: cardWidth,
                        child: _buildCardItem(0, widget.niceneCard!, cardWidth),
                      ),
                      SizedBox(width: widget.cardGap),
                      // Page 1: Apostles' Creed Card
                      SizedBox(
                        key: const Key('apostles_card_wrapper'),
                        width: cardWidth,
                        child: _buildCardItem(
                          1,
                          widget.apostlesCard!,
                          cardWidth,
                        ),
                      ),
                      if (widget.horizontalPadding > 0)
                        SizedBox(width: widget.horizontalPadding),
                    ],
                  ),
                ),
              ),
              // Peeking tap overlay for Page 0 -> Page 1 (Right edge)
              if (_currentPage == 0)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: peekingTapWidth,
                  child: GestureDetector(
                    key: const Key('apostles_creed_peeking_tap'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _animateToPage(1, maxScrollExtent),
                  ),
                ),
              // Peeking tap overlay for Page 1 -> Page 0 (Left edge)
              if (_currentPage == 1)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: peekingTapWidth,
                  child: GestureDetector(
                    key: const Key('nicene_creed_peeking_tap'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _animateToPage(0, maxScrollExtent),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardItem(int index, Widget card, double cardWidth) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      minWidth: cardWidth,
      maxWidth: cardWidth,
      minHeight: 0.0,
      maxHeight: double.infinity,
      child: _HeightReporter(
        onHeightChanged: (h) => _onHeightMeasured(index, h),
        child: SizedBox(width: cardWidth, child: card),
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
    _scheduleHeightReport();
  }

  @override
  void didUpdateWidget(covariant _HeightReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleHeightReport();
  }

  void _scheduleHeightReport() {
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
    _scheduleHeightReport();
    return Container(key: _key, child: widget.child);
  }
}
