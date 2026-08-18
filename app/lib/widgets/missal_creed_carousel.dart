import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A horizontal swipeable carousel for displaying the Nicene Creed and
/// Apostles' Creed with viewport-fraction edge peeking and interactive indicator chips.
class MissalCreedCarousel extends StatefulWidget {
  final Widget? niceneCard;
  final Widget? apostlesCard;
  final PageController? controller;
  final ValueChanged<int>? onPageChanged;
  final double viewportFraction;
  final String niceneLabel;
  final String apostlesLabel;

  const MissalCreedCarousel({
    super.key,
    this.niceneCard,
    this.apostlesCard,
    this.controller,
    this.onPageChanged,
    this.viewportFraction = 0.92,
    this.niceneLabel = 'Nicene Creed',
    this.apostlesLabel = "Apostles' Creed",
  });

  @override
  State<MissalCreedCarousel> createState() => _MissalCreedCarouselState();
}

class _MissalCreedCarouselState extends State<MissalCreedCarousel> {
  late PageController _pageController;
  bool _ownsController = false;
  int _currentPage = 0;
  final Map<int, double> _cardHeights = {};

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _pageController = widget.controller!;
      _ownsController = false;
      _currentPage = _pageController.hasClients && _pageController.page != null
          ? _pageController.page!.round()
          : _pageController.initialPage;
    } else {
      _pageController = PageController(
        initialPage: 0,
        viewportFraction: widget.viewportFraction,
      );
      _ownsController = true;
      _currentPage = 0;
    }
  }

  @override
  void didUpdateWidget(covariant MissalCreedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _pageController.dispose();
      }
      _initController();
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

  void _onChipSelected(int index) {
    if (_currentPage == index) return;
    setState(() {
      _currentPage = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    widget.onPageChanged?.call(index);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                key: const Key('nicene_creed_chip'),
                label: Text(widget.niceneLabel),
                selected: _currentPage == 0,
                onSelected: (selected) {
                  if (selected) {
                    _onChipSelected(0);
                  }
                },
              ),
              const SizedBox(width: 8.0),
              ChoiceChip(
                key: const Key('apostles_creed_chip'),
                label: Text(widget.apostlesLabel),
                selected: _currentPage == 1,
                onSelected: (selected) {
                  if (selected) {
                    _onChipSelected(1);
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: calculatedHeight,
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
              widget.onPageChanged?.call(page);
            },
            children: [
              _buildPageItem(0, widget.niceneCard!),
              _buildPageItem(1, widget.apostlesCard!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageItem(int index, Widget card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: _HeightReporter(
          onHeightChanged: (h) => _onHeightMeasured(index, h),
          child: card,
        ),
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
