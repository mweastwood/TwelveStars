import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/prayer_database.dart';

/// Representation of a lectionary reading prepared for homily reflection.
class HomilyReadingData {
  final String readingType;
  final String citation;
  final String text;

  const HomilyReadingData({
    required this.readingType,
    required this.citation,
    required this.text,
  });

  String get typeHeader {
    switch (readingType.toLowerCase()) {
      case 'first':
        return 'First Reading';
      case 'second':
        return 'Second Reading';
      case 'psalm':
        return 'Responsorial Psalm';
      case 'gospel':
        return 'Gospel';
      default:
        return 'Reading';
    }
  }
}

/// Service to handle fetching readings text, prompt assembly,
/// token budgeting/compression, and invoking on-device AI for homily reflections.
class HomilyService {
  /// Default token ceiling for on-device Gemini Nano input prompts.
  static const int defaultTokenCeiling = 2048;

  /// Fetches the Bible verse texts for the provided list of lectionary readings.
  static Future<List<HomilyReadingData>> fetchReadingsData(
    List<LectionaryReading> readings, {
    String? translation,
  }) async {
    final settings = await PrayerDatabase.loadSettings();
    final activeTranslation = translation ?? settings.primaryBibleTranslation;
    final db = BibleDatabaseHelper.db;

    final List<HomilyReadingData> results = [];

    for (final reading in readings) {
      try {
        final bookMeta = catholicBooks.firstWhere(
          (b) => b.bookNumber == reading.bookNumber,
          orElse: () =>
              throw Exception('Book ${reading.bookName} not found in metadata'),
        );

        await db.ensureBookPopulated(
          bookMeta.bookNumber,
          bookMeta.bookName,
          bookMeta.abbrev,
          translation: activeTranslation,
        );

        final ranges = resolveReadingRanges(
          bookNumber: reading.bookNumber,
          defaultChapter: reading.chapter,
          defaultVerseRange: reading.verseRange,
          citation: reading.citation,
        );

        Expression<bool> predicate = const Constant(false);
        for (final range in ranges) {
          Expression<bool> rangePredicate = db.bibleVerses.chapter.equals(
            range.chapter,
          );

          if (range.verses != null) {
            if (range.startVerseLimit != null) {
              rangePredicate =
                  rangePredicate &
                  (db.bibleVerses.verseNumber.isIn(range.verses!) |
                      db.bibleVerses.verseNumber.isBiggerOrEqualValue(
                        range.startVerseLimit!,
                      ));
            } else {
              rangePredicate =
                  rangePredicate &
                  db.bibleVerses.verseNumber.isIn(range.verses!);
            }
          } else if (range.startVerseLimit != null) {
            rangePredicate =
                rangePredicate &
                db.bibleVerses.verseNumber.isBiggerOrEqualValue(
                  range.startVerseLimit!,
                );
          } else if (range.endVerseLimit != null) {
            rangePredicate =
                rangePredicate &
                db.bibleVerses.verseNumber.isSmallerOrEqualValue(
                  range.endVerseLimit!,
                );
          }

          predicate = predicate | rangePredicate;
        }

        final verses =
            await (db.select(db.bibleVerses)
                  ..where(
                    (t) =>
                        t.translationCode.equals(activeTranslation) &
                        t.bookNumber.equals(reading.bookNumber) &
                        predicate,
                  )
                  ..orderBy([
                    (t) => OrderingTerm(expression: t.chapter),
                    (t) => OrderingTerm(expression: t.verseNumber),
                  ]))
                .get();

        final verseTexts = verses
            .map((v) => v.verseText.trim())
            .where((t) => t.isNotEmpty)
            .join(' ');

        results.add(
          HomilyReadingData(
            readingType: reading.readingType,
            citation: reading.citation,
            text: verseTexts,
          ),
        );
      } catch (e) {
        debugPrint('Error fetching text for reading ${reading.citation}: $e');
        // Fall back to empty text rather than failing entire prompt
        results.add(
          HomilyReadingData(
            readingType: reading.readingType,
            citation: reading.citation,
            text: '',
          ),
        );
      }
    }

    return results;
  }

  /// Builds the structured pastoral homily reflection prompt from readings data.
  static String buildPrompt(
    List<HomilyReadingData> readings, {
    bool compressPsalm = false,
    bool compressSecondReading = false,
    int? maxCharsPerReading,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      "You are a Catholic pastor and theologian delivering a brief homily reflection for the day's Mass readings.",
    );
    buffer.writeln();
    buffer.writeln('Readings:');

    // Sort in liturgical sequence: First Reading, Psalm, Second Reading, Gospel
    final sorted = List<HomilyReadingData>.from(readings);
    sorted.sort((a, b) {
      const order = {'first': 0, 'psalm': 1, 'second': 2, 'gospel': 3};
      final indexA = order[a.readingType.toLowerCase()] ?? 99;
      final indexB = order[b.readingType.toLowerCase()] ?? 99;
      return indexA.compareTo(indexB);
    });

    for (final item in sorted) {
      String processedText = item.text.trim();
      final type = item.readingType.toLowerCase();

      if (type == 'psalm' && compressPsalm && processedText.isNotEmpty) {
        // Compress psalm to key refrain / first portion (~250 chars)
        if (processedText.length > 250) {
          processedText =
              '${processedText.substring(0, 250).trim()}... [excerpt]';
        }
      } else if (type == 'second' &&
          compressSecondReading &&
          processedText.isNotEmpty) {
        // Compress second reading (~300 chars)
        if (processedText.length > 300) {
          processedText =
              '${processedText.substring(0, 300).trim()}... [excerpt]';
        }
      } else if (maxCharsPerReading != null &&
          processedText.length > maxCharsPerReading) {
        processedText =
            '${processedText.substring(0, maxCharsPerReading).trim()}... [excerpt]';
      }

      buffer.writeln('[${item.typeHeader}]: ${item.citation} - $processedText');
    }

    buffer.writeln();
    buffer.writeln(
      'Provide a thoughtful 1-2 paragraph homily reflection that:',
    );
    buffer.writeln(
      '1. Draws out the Catholic theological and typological connections between the readings (especially how the Old Testament/Psalm connects with the Gospel).',
    );
    buffer.writeln(
      '2. Offers a practical application for Catholic Christian daily spiritual life.',
    );
    buffer.write('Keep the tone reverent, orthodox, and accessible.');

    return buffer.toString();
  }

  static Future<int> _countTokens(AiService ai, String prompt) async {
    try {
      final count = await ai.countTokens(prompt: prompt);
      if (count > 0) {
        return count;
      }
    } catch (_) {
      // Fall back to heuristic estimation on error
    }
    return (prompt.length / 4).ceil();
  }

  /// Calculates token count and applies prioritized compression if token budget is exceeded.
  static Future<String> preparePromptWithTokenBudget(
    List<HomilyReadingData> readings, {
    AiService? aiService,
    int tokenCeiling = defaultTokenCeiling,
  }) async {
    final ai = aiService ?? LocalAgentHelper.instance;

    // 1. Initial uncompressed prompt
    String prompt = buildPrompt(readings);
    int tokens = await _countTokens(ai, prompt);

    if (tokens <= tokenCeiling) {
      return prompt;
    }

    // 2. If exceeded, compress Psalm first
    final hasPsalm = readings.any(
      (r) => r.readingType.toLowerCase() == 'psalm',
    );
    if (hasPsalm) {
      prompt = buildPrompt(readings, compressPsalm: true);
      tokens = await _countTokens(ai, prompt);
      if (tokens <= tokenCeiling) {
        return prompt;
      }
    }

    // 3. If still exceeded, compress Second Reading
    final hasSecond = readings.any(
      (r) => r.readingType.toLowerCase() == 'second',
    );
    if (hasSecond) {
      prompt = buildPrompt(
        readings,
        compressPsalm: true,
        compressSecondReading: true,
      );
      tokens = await _countTokens(ai, prompt);
      if (tokens <= tokenCeiling) {
        return prompt;
      }
    }

    // 4. If still exceeded, apply global reading char ceiling
    if (tokens > tokenCeiling) {
      prompt = buildPrompt(
        readings,
        compressPsalm: true,
        compressSecondReading: true,
        maxCharsPerReading: 400,
      );
    }

    return prompt;
  }

  /// Runs the full reflection generation flow.
  static Future<String?> generateReflection(
    List<HomilyReadingData> readings, {
    AiService? aiService,
    int tokenCeiling = defaultTokenCeiling,
  }) async {
    final ai = aiService ?? LocalAgentHelper.instance;
    final prompt = await preparePromptWithTokenBudget(
      readings,
      aiService: ai,
      tokenCeiling: tokenCeiling,
    );

    return await ai.generateContentWithContinuation(
      prompt: prompt,
      maxOutputTokens: 512,
      autoContinueLimit: 2,
    );
  }
}
