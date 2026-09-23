import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';

/// Renders Chinese character lines with Pinyin annotations and selection highlights.
class PrayerPinyinView extends StatelessWidget {
  final List<ChineseLine> chineseLines;
  final String? selectedPhraseId;
  final bool isDualMode;
  final bool isTargetColumn;
  final double fontSize;
  final LayerLink layerLink;
  final ValueChanged<String?> onPhraseSelected;

  const PrayerPinyinView({
    super.key,
    required this.chineseLines,
    required this.selectedPhraseId,
    required this.isDualMode,
    required this.isTargetColumn,
    required this.fontSize,
    required this.layerLink,
    required this.onPhraseSelected,
  });

  static final RegExp _celebrantPrefixRegex = RegExp(
    r'^\s*(?:(?:Priest|Celebrant|Reader|Lector|Lecteur|Lettore|Sacerdos|Diaconus|Sacerdote|Diácono|Linh\s+mục|Phó\s+tế|Người\s+xướng|Người\s+đọc|Namumuno|領經者|主祭|司鐸|執事|讀經者|主禮|啟)\s*[:：]|℣\.?|V\.|V:)',
    caseSensitive: false,
    multiLine: true,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: chineseLines.map((line) {
        final lineText = (line.chars ?? []).map((c) => c.char).join('');
        final isCelebrant = _celebrantPrefixRegex.hasMatch(lineText);
        final fontWeight = isCelebrant ? FontWeight.normal : FontWeight.bold;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            runSpacing: 4,
            children: (line.chars ?? []).map((charItem) {
              final isPunct = charItem.pinyin.isEmpty;
              final isSelected =
                  charItem.phraseId != null &&
                  charItem.phraseId == selectedPhraseId &&
                  isDualMode;

              final charWidget = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 1.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.8,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      charItem.char,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: fontWeight,
                        fontSize: fontSize * 1.125,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPunct ? '' : charItem.pinyin,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              )
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                      ),
                    ),
                  ],
                ),
              );

              final wrappedChar = (isSelected && isTargetColumn)
                  ? CompositedTransformTarget(
                      link: layerLink,
                      child: charWidget,
                    )
                  : charWidget;

              return GestureDetector(
                onTap: (charItem.phraseId != null && isDualMode)
                    ? () {
                        onPhraseSelected(
                          selectedPhraseId == charItem.phraseId
                              ? null
                              : charItem.phraseId,
                        );
                      }
                    : null,
                child: wrappedChar,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
