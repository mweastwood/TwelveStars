import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/lectionary_responses.dart';
import 'package:twelve_stars/logic/prayers.dart';

/// Produces a concise single-line preview of the Responsorial Psalm refrain
/// for compact `R.` cues between stanzas.
///
/// Short refrains (up to [maxChars] characters) are returned intact; longer
/// refrains are truncated cleanly at a word boundary with an ellipsis.
String formatCompactRefrainPreview(String text, {int maxChars = 60}) {
  final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxChars) {
    return normalized;
  }
  final slice = normalized.substring(0, maxChars);
  final lastSpace = slice.lastIndexOf(' ');
  final cut = lastSpace >= (maxChars * 0.5).floor()
      ? slice.substring(0, lastSpace)
      : slice;
  final cleaned = cut.replaceFirst(RegExp(r'[,;:\-–—]+$'), '').trimRight();
  return '$cleaned…';
}

/// Highlighted banner displayed at the top of a Responsorial Psalm card,
/// presenting the congregational Response (`R.`), its scripture citation,
/// and any optional Eastertide `"or: Alleluia"` acclamation.
class MassPsalmResponseBanner extends StatelessWidget {
  final String responseText;
  final String? responseCitation;
  final bool isAlleluia;
  final bool showEasterAlleluiaOption;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final double fontSize;

  const MassPsalmResponseBanner({
    super.key,
    required this.responseText,
    this.responseCitation,
    this.isAlleluia = false,
    this.showEasterAlleluiaOption = false,
    this.primaryLanguage = PrayerLanguage.english,
    this.compareLanguage,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compareFontSize = (fontSize * 0.92).clamp(12.0, 28.0);
    final primaryText = isAlleluia
        ? LectionaryResponses.getAlleluia(primaryLanguage)
        : responseText;
    final compareAlleluia =
        compareLanguage != null && compareLanguage != primaryLanguage
        ? LectionaryResponses.getAlleluia(compareLanguage!)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'R. ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: fontSize,
                      ),
                    ),
                    TextSpan(
                      text: primaryText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: fontSize,
                        height: 1.45,
                      ),
                    ),
                    if (isAlleluia && compareAlleluia != null) ...[
                      TextSpan(
                        text: '\nR. ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: compareFontSize,
                        ),
                      ),
                      TextSpan(
                        text: compareAlleluia,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: compareFontSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (responseCitation != null && responseCitation!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  responseCitation!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (!isAlleluia && showEasterAlleluiaOption) ...[
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${LectionaryResponses.getOrLabel(primaryLanguage)}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: compareFontSize,
                        ),
                      ),
                      TextSpan(
                        text: LectionaryResponses.getAlleluia(primaryLanguage),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: compareFontSize,
                        ),
                      ),
                      if (compareLanguage != null &&
                          compareLanguage != primaryLanguage) ...[
                        TextSpan(
                          text:
                              '  •  ${LectionaryResponses.getOrLabel(compareLanguage!)}: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                            fontSize: (compareFontSize * 0.92).clamp(
                              11.0,
                              24.0,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: LectionaryResponses.getAlleluia(
                            compareLanguage!,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.85),
                            fontSize: (compareFontSize * 0.92).clamp(
                              11.0,
                              24.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact repeated `R.` refrain cue displayed after each psalm stanza.
class MassPsalmRefrainCue extends StatelessWidget {
  final String responseText;
  final bool isAlleluia;
  final PrayerLanguage primaryLanguage;
  final double fontSize;
  final bool isLast;

  const MassPsalmRefrainCue({
    super.key,
    required this.responseText,
    this.isAlleluia = false,
    this.primaryLanguage = PrayerLanguage.english,
    this.fontSize = 16.0,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cueFontSize = (fontSize * 0.88).clamp(12.0, 24.0);
    final preview = isAlleluia
        ? LectionaryResponses.getAlleluia(primaryLanguage)
        : formatCompactRefrainPreview(responseText);

    return Padding(
      padding: EdgeInsets.only(
        left: 28.0,
        right: 8.0,
        top: 4.0,
        bottom: isLast ? 4.0 : 12.0,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'R. ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
                fontSize: cueFontSize,
              ),
            ),
            TextSpan(
              text: preview,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: cueFontSize,
                height: 1.35,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
