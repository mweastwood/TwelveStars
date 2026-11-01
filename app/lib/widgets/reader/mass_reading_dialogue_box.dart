import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/lectionary_responses.dart';
import 'package:twelve_stars/logic/prayers.dart';

/// Renders a single liturgical minister/people dialogue exchange with optional
/// side-by-side bilingual comparison text.
class MassReadingDialogueBox extends StatelessWidget {
  final LiturgicalDialogue primary;
  final LiturgicalDialogue? compare;
  final double fontSize;

  const MassReadingDialogueBox({
    super.key,
    required this.primary,
    this.compare,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compareFontSize = (fontSize * 0.95).clamp(12.0, 30.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minister line
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${primary.ministerCue}: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: fontSize,
                  ),
                ),
                TextSpan(
                  text: primary.ministerText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: fontSize,
                  ),
                ),
                if (compare != null) ...[
                  TextSpan(
                    text: '\n${compare!.ministerCue}: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                      fontSize: compareFontSize,
                    ),
                  ),
                  TextSpan(
                    text: compare!.ministerText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: compareFontSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          // People line
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${primary.peopleCue}: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: fontSize,
                  ),
                ),
                TextSpan(
                  text: primary.peopleText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: fontSize,
                  ),
                ),
                if (compare != null) ...[
                  TextSpan(
                    text: '\n${compare!.peopleCue}: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                      fontSize: compareFontSize,
                    ),
                  ),
                  TextSpan(
                    text: compare!.peopleText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: compareFontSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the introductory Gospel greeting and announcement dialogue box.
class MassReadingIntroDialogue extends StatelessWidget {
  final LectionaryReading reading;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final double fontSize;

  const MassReadingIntroDialogue({
    super.key,
    required this.reading,
    required this.primaryLanguage,
    this.compareLanguage,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evangelist =
        Evangelist.fromBookNumber(reading.bookNumber) ??
        Evangelist.fromBookName(reading.bookName);

    final primaryGreeting = LectionaryResponses.getGospelIntroGreeting(
      primaryLanguage,
    );
    final compareGreeting = compareLanguage != null
        ? LectionaryResponses.getGospelIntroGreeting(compareLanguage!)
        : null;

    final primaryAnnouncement = LectionaryResponses.getGospelIntroAnnouncement(
      primaryLanguage,
      evangelist,
    );
    final compareAnnouncement = compareLanguage != null
        ? LectionaryResponses.getGospelIntroAnnouncement(
            compareLanguage!,
            evangelist,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MassReadingDialogueBox(
            primary: primaryGreeting,
            compare: compareGreeting,
            fontSize: fontSize,
          ),
          const SizedBox(height: 6),
          MassReadingDialogueBox(
            primary: primaryAnnouncement,
            compare: compareAnnouncement,
            fontSize: fontSize,
          ),
        ],
      ),
    );
  }
}

/// Renders the concluding liturgical acclamation ("The word of the Lord" or
/// "The Gospel of the Lord") for non-Psalm readings.
class MassReadingConcludingDialogue extends StatelessWidget {
  final LectionaryReading reading;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final double fontSize;

  const MassReadingConcludingDialogue({
    super.key,
    required this.reading,
    required this.primaryLanguage,
    this.compareLanguage,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final readingType = reading.readingType.toLowerCase();
    if (readingType == 'psalm') {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isGospel = readingType == 'gospel';
    final primary = isGospel
        ? LectionaryResponses.getGospelConcludingDialogue(primaryLanguage)
        : LectionaryResponses.getReadingConcludingDialogue(primaryLanguage);
    final compare = compareLanguage != null
        ? (isGospel
              ? LectionaryResponses.getGospelConcludingDialogue(
                  compareLanguage!,
                )
              : LectionaryResponses.getReadingConcludingDialogue(
                  compareLanguage!,
                ))
        : null;

    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: MassReadingDialogueBox(
        primary: primary,
        compare: compare,
        fontSize: fontSize,
      ),
    );
  }
}
