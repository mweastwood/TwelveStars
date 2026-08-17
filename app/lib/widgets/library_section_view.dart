import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';

class LibrarySectionView extends StatelessWidget {
  final BookSection section;
  final double fontSize;
  final String verseSystem;
  final String? volumeKey;
  final ValueChanged<int> onShowCrossRefModal;
  final ValueChanged<BibleCitation> onShowScriptureModal;
  final Map<int, GlobalKey>? questionKeys;
  final Map<int, GlobalKey>? itemKeys;
  final int? selectedStartIndex;
  final int? selectedEndIndex;
  final ValueChanged<int>? onItemLongPress;
  final ValueChanged<int>? onItemTap;
  final Map<String, List<UserComment>>? commentsMap;
  final void Function(
    String nodeId,
    String citation,
    String textPreview,
    List<UserComment> comments,
  )?
  onTapComments;

  const LibrarySectionView({
    super.key,
    required this.section,
    required this.fontSize,
    required this.verseSystem,
    this.volumeKey,
    required this.onShowCrossRefModal,
    required this.onShowScriptureModal,
    this.questionKeys,
    this.itemKeys,
    this.selectedStartIndex,
    this.selectedEndIndex,
    this.onItemLongPress,
    this.onItemTap,
    this.commentsMap,
    this.onTapComments,
  });

  bool _isItemSelected(int index) {
    if (selectedStartIndex != null && selectedEndIndex != null) {
      final start = selectedStartIndex! < selectedEndIndex!
          ? selectedStartIndex!
          : selectedEndIndex!;
      final end = selectedStartIndex! > selectedEndIndex!
          ? selectedStartIndex!
          : selectedEndIndex!;
      return index >= start && index <= end;
    }
    return false;
  }

  String _getItemCitation(ContentItem item, int index) {
    if (item.type == 'qa' &&
        item.questionNumber != null &&
        item.questionNumber! > 0) {
      return '${section.title}, Q. ${item.questionNumber}';
    }
    return section.title;
  }

  String _getItemTextPreview(ContentItem item) {
    if (item.type == 'qa') {
      final q = item.question ?? '';
      final a = item.answer ?? '';
      return 'Q. $q\nA. $a';
    }
    return item.text ?? '';
  }

  Widget _buildCommentBadge({
    required ThemeData theme,
    required String nodeId,
    required String citation,
    required String textPreview,
    required List<UserComment> comments,
  }) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () => onTapComments?.call(nodeId, citation, textPreview, comments),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_rounded,
              size: 13,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '${comments.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            section.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          if (section.subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              section.subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Content Items
          for (int i = 0; i < section.content.length; i++) ...[
            _buildContentItem(context, theme, i, section.content[i]),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContentItem(
    BuildContext context,
    ThemeData theme,
    int index,
    ContentItem item,
  ) {
    final isSelected = _isItemSelected(index);
    final nodeId =
        '${volumeKey != null ? '$volumeKey:' : ''}${section.id}_$index';
    final comments = commentsMap?[nodeId] ?? [];
    final citation = _getItemCitation(item, index);
    final textPreview = _getItemTextPreview(item);

    Key? itemKey;
    if (itemKeys != null && itemKeys!.containsKey(index)) {
      itemKey = itemKeys![index];
    } else if (item.type == 'qa' &&
        item.questionNumber != null &&
        questionKeys != null &&
        questionKeys!.containsKey(item.questionNumber!)) {
      itemKey = questionKeys![item.questionNumber!];
    }

    Widget contentWidget;
    if (item.type == 'heading') {
      contentWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.text ?? '',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  height: 1.4,
                ),
              ),
            ),
            if (comments.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildCommentBadge(
                theme: theme,
                nodeId: nodeId,
                citation: citation,
                textPreview: textPreview,
                comments: comments,
              ),
            ],
          ],
        ),
      );
    } else if (item.type == 'qa') {
      final qPrefix = (item.questionNumber != null && item.questionNumber! > 0)
          ? 'Q. ${item.questionNumber}. '
          : 'Q. ';

      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
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
                            text: qPrefix,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: item.question ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (item.crossRefQNum != null)
                      ActionChip(
                        avatar: Icon(
                          Icons.auto_stories_rounded,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        label: Text('Ref: #${item.crossRefQNum}'),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        mouseCursor: SystemMouseCursors.click,
                        onPressed: () =>
                            onShowCrossRefModal(item.crossRefQNum!),
                      ),
                  ],
                ),
              ),
              if (comments.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildCommentBadge(
                  theme: theme,
                  nodeId: nodeId,
                  citation: citation,
                  textPreview: textPreview,
                  comments: comments,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
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
                TextSpan(text: item.answer ?? ''),
              ],
            ),
          ),
          if (item.explanation != null && item.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(
                  alpha: 0.6,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'EXPLANATION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildExplanationContent(item.explanation!, theme, fontSize),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      contentWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInteractiveTextWithCitations(
              item.text ?? '',
              theme,
              fontSize: fontSize,
              height: 1.6,
            ),
          ),
          if (comments.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildCommentBadge(
              theme: theme,
              nodeId: nodeId,
              citation: citation,
              textPreview: textPreview,
              comments: comments,
            ),
          ],
        ],
      );
    }

    return KeyedSubtree(
      key: itemKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onItemLongPress != null
            ? () => onItemLongPress!(index)
            : null,
        onTap: onItemTap != null ? () => onItemTap!(index) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: contentWidget,
        ),
      ),
    );
  }

  Widget _buildExplanationContent(
    String rawExplanation,
    ThemeData theme,
    double fontSize,
  ) {
    final paragraphs = rawExplanation
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildInteractiveTextWithCitations(
            paragraphs[i],
            theme,
            fontSize: fontSize,
            height: 1.55,
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveTextWithCitations(
    String text,
    ThemeData theme, {
    required double fontSize,
    required double height,
    Color? color,
  }) {
    final segments = BibleCitationParser.parse(text, verseSystem: verseSystem);

    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: fontSize,
          height: height,
          color: color ?? theme.colorScheme.onSurface,
        ),
        children: [
          for (final seg in segments)
            if (seg.isCitation)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => onShowScriptureModal(seg.citation!),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            seg.citation?.displayLabel ?? '',
                            style: TextStyle(
                              fontSize: fontSize * 0.85,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              TextSpan(text: seg.text ?? ''),
        ],
      ),
    );
  }
}
