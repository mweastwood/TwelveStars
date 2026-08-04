import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';

class ReaderParallelView extends StatelessWidget {
  final List<ReaderContentNode> nodes;
  final double fontSize;
  final Set<String> selectedNodeIds;
  final ValueChanged<String>? onNodeLongPress;
  final ValueChanged<String>? onNodeTap;

  const ReaderParallelView({
    super.key,
    required this.nodes,
    this.fontSize = 16.0,
    this.selectedNodeIds = const <String>{},
    this.onNodeLongPress,
    this.onNodeTap,
  });

  Widget _buildPrimaryContent(ReaderContentNode node, ThemeData theme) {
    if (node.nodeType == ReaderNodeType.heading) {
      return Text(
        node.primaryText ?? '',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      );
    } else if (node.nodeType == ReaderNodeType.qa) {
      final qNum = node.questionNumber != null
          ? 'Q. ${node.questionNumber}. '
          : 'Q. ';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: fontSize,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: qNum,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextSpan(
                  text: node.question ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (node.answer != null) ...[
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: fontSize,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: 'A. ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  TextSpan(text: node.answer!),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      final vNum = node.questionNumber != null ? '${node.questionNumber} ' : '';
      return RichText(
        text: TextSpan(
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: fontSize,
            height: 1.55,
            color: theme.colorScheme.onSurface,
          ),
          children: [
            if (vNum.isNotEmpty)
              TextSpan(
                text: vNum,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize * 0.85,
                  color: theme.colorScheme.primary,
                ),
              ),
            TextSpan(text: node.primaryText ?? ''),
          ],
        ),
      );
    }
  }

  Widget _buildSecondaryContent(ReaderContentNode node, ThemeData theme) {
    if (node.secondaryText == null || node.secondaryText!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      node.secondaryText!,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: fontSize,
        height: 1.55,
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: nodes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final node = nodes[index];
        final isSelected = selectedNodeIds.contains(node.id);
        final hasSecondary =
            node.secondaryText != null && node.secondaryText!.isNotEmpty;

        return InkWell(
          onTap: onNodeTap != null ? () => onNodeTap!(node.id) : null,
          onLongPress: onNodeLongPress != null
              ? () => onNodeLongPress!(node.id)
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: hasSecondary
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPrimaryContent(node, theme)),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSecondaryContent(node, theme)),
                    ],
                  )
                : _buildPrimaryContent(node, theme),
          ),
        );
      },
    );
  }
}
