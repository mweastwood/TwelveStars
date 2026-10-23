import 'package:flutter/material.dart';

/// Controller managing the animation and scroll-offset compensation for a
/// collapsible top selector bar (such as the language or Bible translation bar).
class CollapsibleSelectorController {
  final double topSpacerHeight;
  final ScrollController? Function() activeScrollController;
  final VoidCallback? onStatusSettled;

  late final AnimationController animationController;
  late final CurvedAnimation animation;

  bool _isExpanded;
  bool _wasScrolledDown = false;
  double _initialScrollOffset = 0.0;

  CollapsibleSelectorController({
    required TickerProvider vsync,
    required this.topSpacerHeight,
    required this.activeScrollController,
    bool initiallyExpanded = false,
    Duration duration = const Duration(milliseconds: 300),
    this.onStatusSettled,
  }) : _isExpanded = initiallyExpanded {
    animationController = AnimationController(
      vsync: vsync,
      duration: duration,
      value: initiallyExpanded ? 1.0 : 0.0,
    );
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    animationController.addListener(_onAnimationTick);
    if (onStatusSettled != null) {
      animationController.addStatusListener((status) {
        if (status == AnimationStatus.dismissed ||
            status == AnimationStatus.completed) {
          onStatusSettled!();
        }
      });
    }
  }

  bool get isExpanded => _isExpanded;

  bool get isVisibleOrAnimating => _isExpanded || animationController.value > 0;

  /// Updates the expanded state immediately without animating (e.g. when
  /// loading persisted settings).
  void syncExpanded(bool expanded) {
    _isExpanded = expanded;
    animationController.value = expanded ? 1.0 : 0.0;
  }

  /// Toggles the selector bar open or closed while compensating the active
  /// scroll controller's offset if the user is scrolled down.
  bool toggle() {
    final controller = activeScrollController();
    final offset = controller != null && controller.hasClients
        ? controller.offset
        : 0.0;
    _wasScrolledDown = offset > 5.0;
    _initialScrollOffset = offset - (topSpacerHeight * animation.value);

    _isExpanded = !_isExpanded;
    if (_isExpanded) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
    return _isExpanded;
  }

  void _onAnimationTick() {
    final controller = activeScrollController();
    if (!_wasScrolledDown || controller == null || !controller.hasClients) {
      return;
    }

    final targetOffset =
        _initialScrollOffset + (topSpacerHeight * animation.value);
    final maxExtent = controller.position.maxScrollExtent + topSpacerHeight;
    controller.jumpTo(targetOffset.clamp(0.0, maxExtent));
  }

  void dispose() {
    animationController.removeListener(_onAnimationTick);
    animation.dispose();
    animationController.dispose();
  }
}

/// Animated top selector bar wrapper using [SizeTransition] and [FadeTransition].
class CollapsibleSelectorBar extends StatelessWidget {
  final Animation<double> animation;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const CollapsibleSelectorBar({
    super.key,
    required this.animation,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: animation,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
