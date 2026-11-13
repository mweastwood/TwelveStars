import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/prayer_text_parser.dart';
import 'package:twelve_stars/logic/prayers.dart';

/// Builds [InlineSpan] trees for tokenized and plain-text prayers, handling
/// inline italics, liturgical congregational response bolding, phrase selection
/// highlights, gesture recognizer registration, and [CompositedTransformTarget]
/// anchoring for the floating AI translation explainer button.
class PrayerRichTextSpanBuilder {
  final ThemeData theme;
  final double fontSize;
  final bool isDualMode;
  final String? selectedPhraseId;
  final LayerLink? layerLink;
  final Key? targetKey;
  final Map<String, TapGestureRecognizer>? recognizers;
  final Set<String>? activeRecognizerKeys;
  final ValueChanged<String?>? onPhraseSelected;

  const PrayerRichTextSpanBuilder({
    required this.theme,
    this.fontSize = 16.0,
    this.isDualMode = false,
    this.selectedPhraseId,
    this.layerLink,
    this.targetKey,
    this.recognizers,
    this.activeRecognizerKeys,
    this.onPhraseSelected,
  });

  /// Parses inline markdown italics (`*text*`) into [TextSpan]s,
  /// applying [FontStyle.italic] to matched segments while preserving [style]
  /// and [recognizer].
  static List<InlineSpan> parseItalicsSpans(
    String text,
    TextStyle? style, {
    GestureRecognizer? recognizer,
  }) {
    final spans = <InlineSpan>[];
    int lastMatchEnd = 0;

    for (final match in PrayerTextParser.italicsRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: style,
            recognizer: recognizer,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: style?.copyWith(fontStyle: FontStyle.italic),
          recognizer: recognizer,
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: style,
          recognizer: recognizer,
        ),
      );
    }

    return spans;
  }

  /// Builds an [InlineSpan] for a single [PrayerToken] at [index].
  ///
  /// Handles single vs. dual mode styling, selected/unselected phrase styles,
  /// liturgical response bolding ([isResponse]), gesture recognizer registration,
  /// and [CompositedTransformTarget] attachment when [attachLayerLink] is true.
  InlineSpan buildTokenSpan(
    PrayerToken token,
    int index, {
    bool isTarget = false,
    bool attachLayerLink = false,
    bool isResponse = false,
  }) {
    final fontWeight = isResponse ? FontWeight.bold : null;
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.6,
      fontSize: fontSize,
      letterSpacing: 0.2,
      fontWeight: fontWeight,
    );

    if (token.id == null || !isDualMode) {
      final style = baseStyle?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
      );
      return TextSpan(children: parseItalicsSpans(token.text, style));
    }

    final recognizerKey =
        '${isTarget ? 'target' : 'primary'}_${index}_${token.id}';
    activeRecognizerKeys?.add(recognizerKey);

    TapGestureRecognizer? recognizer;
    if (recognizers != null) {
      recognizer = recognizers!.putIfAbsent(
        recognizerKey,
        () => TapGestureRecognizer(),
      );
    } else if (onPhraseSelected != null) {
      recognizer = TapGestureRecognizer();
    }

    if (recognizer != null) {
      recognizer.onTap = () {
        onPhraseSelected?.call(selectedPhraseId == token.id ? null : token.id);
      };
    }

    final isSelected = token.id == selectedPhraseId;

    if (isSelected) {
      final selectedStyle = baseStyle?.copyWith(
        color: theme.colorScheme.onPrimaryContainer,
        backgroundColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.8,
        ),
      );

      final textSpan = TextSpan(
        children: parseItalicsSpans(
          token.text,
          selectedStyle,
          recognizer: recognizer,
        ),
      );

      if (attachLayerLink) {
        return TextSpan(
          children: [
            textSpan,
            WidgetSpan(
              child: CompositedTransformTarget(
                key: targetKey,
                link: layerLink ?? LayerLink(),
                child: const SizedBox(width: 0, height: 0),
              ),
            ),
          ],
        );
      }

      return textSpan;
    }

    final unselectedStyle = baseStyle?.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dashed,
      decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
      color: theme.colorScheme.onSurface,
    );

    return TextSpan(
      children: parseItalicsSpans(
        token.text,
        unselectedStyle,
        recognizer: recognizer,
      ),
    );
  }

  /// Builds the list of [InlineSpan]s for a tokenized prayer translation.
  ///
  /// Resolves the last matching target token for [selectedPhraseId] when
  /// [isTargetColumn] is true in dual mode, detects liturgical response lines
  /// via [PrayerTextParser], and splits unaligned newline-containing tokens
  /// across line boundaries so response bolding applies per line.
  List<InlineSpan> buildTokenizedSpans(
    List<PrayerToken> tokens, {
    bool isTargetColumn = false,
  }) {
    final fullText = tokens.map((t) => t.text).join('');
    final hasResponses = PrayerTextParser.hasResponses(fullText);

    int? targetTokenIndex;
    if (isDualMode && isTargetColumn && selectedPhraseId != null) {
      for (var i = 0; i < tokens.length; i++) {
        if (tokens[i].id == selectedPhraseId) {
          targetTokenIndex = i;
        }
      }
    }

    final spans = <InlineSpan>[];

    if (!hasResponses) {
      for (var i = 0; i < tokens.length; i++) {
        spans.add(
          buildTokenSpan(
            tokens[i],
            i,
            isTarget: isTargetColumn,
            attachLayerLink: i == targetTokenIndex,
            isResponse: false,
          ),
        );
      }
    } else {
      final lines = fullText.split('\n');
      final isResponseLineList = lines
          .map(PrayerTextParser.isResponseLine)
          .toList();
      final lineStartIndices = PrayerTextParser.computeLineStartOffsets(lines);

      int charOffset = 0;

      for (var i = 0; i < tokens.length; i++) {
        final token = tokens[i];
        final tokenStart = charOffset;
        final tokenEnd = charOffset + token.text.length;
        charOffset = tokenEnd;

        if (token.id != null) {
          final lineIdx = PrayerTextParser.getLineIndexAt(
            lineStartIndices,
            tokenStart,
          );
          final isResponse =
              lineIdx < isResponseLineList.length &&
              isResponseLineList[lineIdx];
          spans.add(
            buildTokenSpan(
              token,
              i,
              isTarget: isTargetColumn,
              attachLayerLink: i == targetTokenIndex,
              isResponse: isResponse,
            ),
          );
        } else {
          if (!token.text.contains('\n')) {
            final lineIdx = PrayerTextParser.getLineIndexAt(
              lineStartIndices,
              tokenStart,
            );
            final isResponse =
                lineIdx < isResponseLineList.length &&
                isResponseLineList[lineIdx];
            spans.add(
              buildTokenSpan(
                token,
                i,
                isTarget: isTargetColumn,
                isResponse: isResponse,
              ),
            );
          } else {
            final parts = token.text.split('\n');
            int subOffset = tokenStart;
            for (var p = 0; p < parts.length; p++) {
              if (p > 0) {
                spans.add(const TextSpan(text: '\n'));
                subOffset += 1;
              }
              final partText = parts[p];
              if (partText.isNotEmpty) {
                final lineIdx = PrayerTextParser.getLineIndexAt(
                  lineStartIndices,
                  subOffset,
                );
                final isResponse =
                    lineIdx < isResponseLineList.length &&
                    isResponseLineList[lineIdx];
                final partToken = PrayerToken(partText, null);
                spans.add(
                  buildTokenSpan(
                    partToken,
                    i,
                    isTarget: isTargetColumn,
                    isResponse: isResponse,
                  ),
                );
                subOffset += partText.length;
              }
            }
          }
        }
      }
    }

    return spans;
  }

  /// Builds the list of [InlineSpan]s for a plain-text (non-tokenized) prayer,
  /// applying inline italics and liturgical response line bolding.
  List<InlineSpan> buildPlainTextSpans(String text) {
    final hasResponses = PrayerTextParser.hasResponses(text);
    if (!hasResponses) {
      final fallbackStyle = theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
        fontSize: fontSize,
        letterSpacing: 0.2,
      );
      return parseItalicsSpans(text, fallbackStyle);
    }

    final lines = text.split('\n');
    final spans = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        spans.add(const TextSpan(text: '\n'));
      }
      final line = lines[i];
      if (line.isNotEmpty) {
        final isResponse = PrayerTextParser.isResponseLine(line);
        final lineStyle = theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
          fontSize: fontSize,
          letterSpacing: 0.2,
          fontWeight: isResponse ? FontWeight.bold : null,
        );
        spans.addAll(parseItalicsSpans(line, lineStyle));
      }
    }
    return spans;
  }
}
