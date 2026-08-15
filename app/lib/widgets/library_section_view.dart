import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';

class LibrarySectionView extends StatelessWidget {
  final BookSection section;
  final double fontSize;
  final String verseSystem;
  final ValueChanged<int> onShowCrossRefModal;
  final ValueChanged<BibleCitation> onShowScriptureModal;
  final Map<int, GlobalKey>? questionKeys;

  const LibrarySectionView({
    super.key,
    required this.section,
    required this.fontSize,
    required this.verseSystem,
    required this.onShowCrossRefModal,
    required this.onShowScriptureModal,
    this.questionKeys,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
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
          const SizedBox(height: 16),

          // Content Items
          ...section.content.map((item) {
            if (item.type == 'heading') {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
                child: Text(
                  item.text ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    height: 1.4,
                  ),
                ),
              );
            } else if (item.type == 'qa') {
              final qPrefix =
                  (item.questionNumber != null && item.questionNumber! > 0)
                  ? 'Q. ${item.questionNumber}. '
                  : 'Q. ';
              return Padding(
                key: (item.questionNumber != null && questionKeys != null)
                    ? questionKeys![item.questionNumber!]
                    : null,
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                    if (item.explanation != null &&
                        item.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 4,
                            ),
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
                            _buildExplanationContent(
                              item.explanation!,
                              theme,
                              fontSize,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildInteractiveTextWithCitations(
                  item.text ?? '',
                  theme,
                  fontSize: fontSize,
                  height: 1.6,
                ),
              );
            }
          }),
          const SizedBox(height: 40),
        ],
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

    return SelectableText.rich(
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
