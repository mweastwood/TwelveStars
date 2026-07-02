import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';

class RosaryBeadChain extends StatefulWidget {
  final List<RosaryStep> steps;
  final int currentStep;
  final ValueChanged<int> onStepSelected;

  const RosaryBeadChain({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepSelected,
  });

  @override
  State<RosaryBeadChain> createState() => _RosaryBeadChainState();
}

class _RosaryBeadChainState extends State<RosaryBeadChain> {
  late final ScrollController _scrollController;

  double _getItemHeight(RosaryBeadType type) {
    switch (type) {
      case RosaryBeadType.crucifix:
        return 96.0; // Spacing to give comfortable gap between the cross and adjacent beads
      case RosaryBeadType.medal:
        return 56.0; // Increased from 48.0 for breathing room around the improved 48px medal
      case RosaryBeadType.large:
        return 36.0; // Spacing for Our Father beads
      case RosaryBeadType.small:
        return 16.0; // Packed tightly for high density
      case RosaryBeadType.chainLink:
        return 24.0; // Spacing on the rope for Glory Be & Fatima transitions
    }
  }

  double _getOffsetToStep(int stepIndex) {
    double offset = 0.0;
    for (int i = 0; i < stepIndex; i++) {
      offset += _getItemHeight(widget.steps[i].beadType);
    }
    return offset;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToActive(animate: false),
    );
  }

  @override
  void didUpdateWidget(RosaryBeadChain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep) {
      _scrollToActive(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive({required bool animate}) {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    final targetOffset =
        _getOffsetToStep(widget.currentStep) -
        (_scrollController.position.viewportDimension / 2) +
        (_getItemHeight(widget.steps[widget.currentStep].beadType) / 2);

    final maxScroll = _scrollController.position.maxScrollExtent;
    final minScroll = _scrollController.position.minScrollExtent;
    final double boundedOffset = targetOffset.clamp(minScroll, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        boundedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(boundedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: 64,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.steps.length,
              clipBehavior: Clip.none, // Prevent clipping of large cross/medal
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              itemBuilder: (context, index) {
                final step = widget.steps[index];
                final isActive = index == widget.currentStep;
                final isFirst = index == 0;
                final isLast = index == widget.steps.length - 1;
                final itemHeight = _getItemHeight(step.beadType);

                final activeColor = theme.colorScheme.primary;
                final inactiveColor = theme.colorScheme.outlineVariant;
                // Highlight the rope ONLY if the step itself is a rope transition (chainLink)
                final ropeColor =
                    (isActive && step.beadType == RosaryBeadType.chainLink)
                    ? activeColor
                    : inactiveColor;
                final ropeWidth =
                    (isActive && step.beadType == RosaryBeadType.chainLink)
                    ? 4.0
                    : 3.0;

                Widget bead = _buildBead(context, step, isActive);
                // Shift the Our Father bead vertically upwards by 12px (ChainLinkHeight / 2) to maintain perfect spacing symmetry
                if (step.beadType == RosaryBeadType.large) {
                  bead = Transform.translate(
                    offset: const Offset(0, -12.0),
                    child: bead,
                  );
                }

                return Center(
                  child: SizedBox(
                    height: itemHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onStepSelected(index),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Rope segment
                          Positioned(
                            top: isFirst ? itemHeight / 2 : 0,
                            bottom: isLast ? itemHeight / 2 : 0,
                            width: ropeWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: ropeColor,
                                boxShadow:
                                    (isActive &&
                                        step.beadType ==
                                            RosaryBeadType.chainLink)
                                    ? [
                                        BoxShadow(
                                          color: ropeColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          // Bead on top
                          Semantics(
                            label: 'Bead ${index + 1}: ${step.title}',
                            selected: isActive,
                            child: bead,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBead(BuildContext context, RosaryStep step, bool isActive) {
    final theme = Theme.of(context);

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.outline;
    final color = isActive ? activeColor : inactiveColor;

    Widget beadWidget;
    switch (step.beadType) {
      case RosaryBeadType.crucifix:
        beadWidget = _RosaryCross(isActive: isActive, color: color);
        break;
      case RosaryBeadType.medal:
        beadWidget = _RosaryMedal(isActive: isActive, color: color);
        break;
      case RosaryBeadType.large:
        beadWidget = Container(
          width: isActive ? 16 : 12,
          height: isActive ? 16 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            border: Border.all(color: color, width: isActive ? 2.5 : 1.5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
        break;
      case RosaryBeadType.small:
        beadWidget = Container(
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.colorScheme.secondary
                : theme.colorScheme.surface,
            border: Border.all(
              color: isActive ? theme.colorScheme.secondary : color,
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
        break;
      case RosaryBeadType.chainLink:
        beadWidget = const SizedBox.shrink();
        break;
    }

    if (isActive && step.beadType != RosaryBeadType.chainLink) {
      return Hero(tag: 'active_bead', child: beadWidget);
    }
    return beadWidget;
  }
}

class _RosaryCross extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _RosaryCross({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    final width = isActive ? 48.0 : 32.0;
    final height = isActive ? 64.0 : 44.0;
    final strokeWidth = isActive ? 10.0 : 7.0;

    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Vertical bar
            Container(
              width: strokeWidth,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3.0),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            // Horizontal bar
            Positioned(
              top: height * 0.28,
              child: Container(
                width: width,
                height: strokeWidth,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3.0),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosaryMedal extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _RosaryMedal({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = isActive ? 48.0 : 34.0;
    final fillColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final starColor = isActive ? theme.colorScheme.onPrimary : color;

    return Semantics(
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: isActive
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: CustomPaint(
          size: Size(size, size),
          painter: _MedalPainter(
            isActive: isActive,
            borderColor: color,
            fillColor: fillColor,
            starColor: starColor,
          ),
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final bool isActive;
  final Color borderColor;
  final Color fillColor;
  final Color starColor;

  _MedalPainter({
    required this.isActive,
    required this.borderColor,
    required this.fillColor,
    required this.starColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final bgPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 2.5 : 1.5;
    canvas.drawCircle(
      center,
      radius - (borderPaint.strokeWidth / 2),
      borderPaint,
    );

    // Draw 12 stars in a circle
    final starPaint = Paint()
      ..color = starColor
      ..style = PaintingStyle.fill;

    final starCircleRadius = isActive ? 15.0 : 10.0;
    final starRadius = isActive ? 3.6 : 2.5;

    for (int i = 0; i < 12; i++) {
      final double angle = i * (2 * math.pi / 12) - (math.pi / 2);
      final double cx = center.dx + starCircleRadius * math.cos(angle);
      final double cy = center.dy + starCircleRadius * math.sin(angle);

      final starPath = _createStarPath(starRadius, Offset(cx, cy));
      canvas.drawPath(starPath, starPaint);
    }
  }

  Path _createStarPath(double outerRadius, Offset starCenter) {
    final path = Path();
    final double angle = math.pi / 5;
    final double innerRadius = outerRadius * 0.4;

    for (int i = 0; i < 10; i++) {
      final double r = (i % 2 == 0) ? outerRadius : innerRadius;
      final double currAngle = i * angle - math.pi / 2;
      final double x = starCenter.dx + r * math.cos(currAngle);
      final double y = starCenter.dy + r * math.sin(currAngle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _MedalPainter oldDelegate) {
    return oldDelegate.isActive != isActive ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.starColor != starColor;
  }
}
