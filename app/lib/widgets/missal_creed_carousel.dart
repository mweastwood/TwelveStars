import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A horizontal swipeable carousel for displaying the Nicene Creed and
/// Apostles' Creed with subtle edge-peeking and animated transitions.
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
  int _currentPage = 0;
  final Map<int, double> _cardHeights = {};

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _pageController = widget.controller!;
    } else {
      _pageController = PageController(initialPage: 0, viewportFraction: 0.92);
      _ownsController = true;
    }
    _currentPage = _pageController.initialPage;
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

  void _animateToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
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

    final theme = Theme.of(context);
    final calculatedHeight = _cardHeights.values.isEmpty
        ? 450.0
        : _cardHeights.values.fold<double>(0.0, math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Indicator selector chips
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIndicatorChip(
                  theme: theme,
                  index: 0,
                  label: 'Nicene Creed',
                  isSelected: _currentPage == 0,
                ),
                const SizedBox(width: 8),
                _buildIndicatorChip(
                  theme: theme,
                  index: 1,
                  label: 'Apostles\' Creed',
                  isSelected: _currentPage == 1,
                ),
              ],
            ),
          ),
        ),

        // Carousel PageView with edge peeking
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

  Widget _buildIndicatorChip({
    required ThemeData theme,
    required int index,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _animateToPage(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.secondary
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
