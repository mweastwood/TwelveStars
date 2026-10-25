import 'package:flutter/material.dart';

/// Centered italicized scripture quote and attribution footer displayed at the
/// bottom of scrollable lists (e.g., Prayers and Saints).
class ScriptureFooterQuote extends StatelessWidget {
  final String quote;
  final String attribution;
  final EdgeInsetsGeometry padding;

  const ScriptureFooterQuote({
    super.key,
    required this.quote,
    required this.attribution,
    this.padding = const EdgeInsets.symmetric(vertical: 24.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        children: [
          Text(
            quote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            attribution,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
