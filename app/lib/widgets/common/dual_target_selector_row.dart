import 'package:flutter/material.dart';

class DualTargetSelectorRow extends StatelessWidget {
  final Widget primaryChild;
  final Widget secondaryChild;
  final bool canSwap;
  final VoidCallback onSwap;
  final String swapTooltip;
  final double swapIconSize;

  const DualTargetSelectorRow({
    super.key,
    required this.primaryChild,
    required this.secondaryChild,
    required this.canSwap,
    required this.onSwap,
    this.swapTooltip = 'Swap Primary & Secondary',
    this.swapIconSize = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: primaryChild),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            Icons.swap_horiz,
            color: canSwap
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: swapIconSize,
          ),
          tooltip: swapTooltip,
          onPressed: canSwap ? onSwap : null,
        ),
        const SizedBox(width: 4),
        Expanded(child: secondaryChild),
      ],
    );
  }
}
