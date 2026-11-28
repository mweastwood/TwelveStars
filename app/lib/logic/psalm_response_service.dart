import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'bible_numbering_mapper.dart';
import 'lectionary_resolver.dart';

/// Describes how to resolve the Responsorial Psalm's congregational refrain (`R.`)
/// from the user's active Bible translation (and/or localized Eastertide "Alleluia").
@immutable
class PsalmResponseSpec {
  /// Target Bible book number when the response comes from a different book
  /// than the psalm itself (e.g., `1 Cor 10:16` on Holy Thursday or `John 6:68`).
  /// Null means use the psalm reading's own [LectionaryReading.bookNumber].
  final int? bookNumber;

  /// Target chapter in Modern/Lectionary numbering when the response comes from
  /// a different chapter than the psalm itself. Null means use the psalm's own chapter.
  final int? chapter;

  /// Modern/Lectionary verse reference (e.g., `"8"`, `"1"`, `"8, 9"`).
  final String? verseRef;

  /// Whether the Roman Lectionary allows `"or: Alleluia"` (Eastertide).
  final bool allowAlleluia;

  /// Whether the primary refrain itself is `"Alleluia"` (e.g., Easter Vigil Ps 118).
  final bool isAlleluia;

  const PsalmResponseSpec({
    this.bookNumber,
    this.chapter,
    this.verseRef,
    this.allowAlleluia = false,
    this.isAlleluia = false,
  });

  /// Returns true if this spec can render a refrain (either Alleluia or a verse ref).
  bool get hasRefrain =>
      isAlleluia || (verseRef != null && verseRef!.trim().isNotEmpty);

  /// Target book number resolved against the parent psalm's [defaultBookNumber].
  int targetBookNumber(int defaultBookNumber) =>
      bookNumber ?? defaultBookNumber;

  /// Target Modern/Lectionary chapter resolved against the parent psalm's [defaultChapter].
  int targetChapter(int defaultChapter) => chapter ?? defaultChapter;

  /// Resolves [verseRef] into Vulgate [ChapterVerseRange]s for database lookup.
  List<ChapterVerseRange> resolveVulgateRanges({
    required int defaultBookNumber,
    required int defaultChapter,
  }) {
    if (isAlleluia || verseRef == null || verseRef!.trim().isEmpty) {
      return const [];
    }
    final targetBook = targetBookNumber(defaultBookNumber);
    final targetChap = targetChapter(defaultChapter);
    final rawVerses = parseVerseRange(cleanVerseStr(verseRef!));
    if (rawVerses.isEmpty) return const [];

    final deduped = <int>[];
    for (final v in rawVerses) {
      if (!deduped.contains(v)) {
        deduped.add(v);
      }
    }

    final mapped = BibleVerseResolver.mapLectionaryToVulgateRanges(
      bookNumber: targetBook,
      chapter: targetChap,
      verses: deduped,
    );
    return [
      for (final m in mapped)
        if (m.verses.isNotEmpty)
          ChapterVerseRange(chapter: m.chapter, verses: m.verses),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PsalmResponseSpec &&
          runtimeType == other.runtimeType &&
          bookNumber == other.bookNumber &&
          chapter == other.chapter &&
          verseRef == other.verseRef &&
          allowAlleluia == other.allowAlleluia &&
          isAlleluia == other.isAlleluia;

  @override
  int get hashCode =>
      Object.hash(bookNumber, chapter, verseRef, allowAlleluia, isAlleluia);
}

/// Loads and caches Responsorial Psalm refrain metadata (`response_ref`,
/// `response_book_number`, `response_chapter`, `response_alleluia`,
/// `response_is_alleluia`) directly from `assets/bible/lectionary.json`.
///
/// Loading from the bundled JSON avoids SQLite schema migration churn and ensures
/// existing installations pick up response references immediately without re-seeding.
/// Entries are keyed by `reading_key` (each liturgical day in `lectionary.json`
/// currently defines at most one `reading_type == 'psalm'` entry).
class PsalmResponseService {
  PsalmResponseService._();

  static const String _assetPath = 'assets/bible/lectionary.json';

  static Map<String, PsalmResponseSpec>? _entriesByKey;
  static Future<void>? _inFlightLoad;
  static Zone? _inFlightZone;
  static int _loadGeneration = 0;

  /// Whether the response table has been loaded (or explicitly seeded for testing).
  static bool get isLoaded => _entriesByKey != null;

  /// Loads response specs from `assets/bible/lectionary.json` if not yet loaded.
  static Future<void> ensureLoaded() {
    if (_entriesByKey != null) {
      return Future.value();
    }
    if (_inFlightLoad != null && identical(_inFlightZone, Zone.current)) {
      return _inFlightLoad!;
    }
    final generation = _loadGeneration;
    final zone = Zone.current;
    final future = _loadFromAsset(generation);
    _inFlightLoad = future;
    _inFlightZone = zone;
    return future;
  }

  static Future<void> _loadFromAsset(int generation) async {
    try {
      // Pass cache: false so calling ensureLoaded() inside a widget test's
      // FakeAsync zone cannot poison rootBundle's string cache for other tests.
      final jsonContent = await rootBundle.loadString(_assetPath, cache: false);
      if (generation != _loadGeneration) return;
      final decoded = jsonDecode(jsonContent) as List<dynamic>;
      final map = parseEntriesFromJson(decoded);
      if (generation != _loadGeneration) return;
      _entriesByKey = Map<String, PsalmResponseSpec>.unmodifiable(map);
    } catch (e) {
      debugPrint('Error loading psalm response specs: $e');
    } finally {
      if (generation == _loadGeneration) {
        _inFlightLoad = null;
        _inFlightZone = null;
      }
    }
  }

  /// Parses [PsalmResponseSpec] entries from a decoded `lectionary.json` list.
  @visibleForTesting
  static Map<String, PsalmResponseSpec> parseEntriesFromJson(
    List<dynamic> decoded,
  ) {
    final map = <String, PsalmResponseSpec>{};
    for (final raw in decoded) {
      if (raw is! Map<String, dynamic>) continue;
      if ((raw['reading_type'] as String?)?.toLowerCase() != 'psalm') continue;
      final key = raw['reading_key'] as String?;
      if (key == null || key.isEmpty) continue;

      final responseRef = raw['response_ref'] as String?;
      final responseBook = raw['response_book_number'] as int?;
      final responseChapter = raw['response_chapter'] as int?;
      final allowAlleluia = raw['response_alleluia'] == true;
      final isAlleluia = raw['response_is_alleluia'] == true;

      final spec = PsalmResponseSpec(
        bookNumber: responseBook,
        chapter: responseChapter,
        verseRef: responseRef,
        allowAlleluia: allowAlleluia,
        isAlleluia: isAlleluia,
      );
      if (spec.hasRefrain) {
        map[key] = spec;
      }
    }
    return map;
  }

  /// Looks up the [PsalmResponseSpec] for a given lectionary [readingKey].
  /// Returns null if not loaded yet or if no response spec exists for [readingKey].
  static PsalmResponseSpec? getForReadingKey(String readingKey) {
    return _entriesByKey?[readingKey];
  }

  /// Seeds explicit test entries without touching `rootBundle`.
  @visibleForTesting
  static void setEntriesForTesting(Map<String, PsalmResponseSpec> entries) {
    _loadGeneration++;
    _inFlightLoad = null;
    _inFlightZone = null;
    _entriesByKey = Map<String, PsalmResponseSpec>.unmodifiable(entries);
  }

  /// Marks the service as loaded with an empty table (useful in unrelated tests).
  @visibleForTesting
  static void setEmptyForTesting() {
    setEntriesForTesting(const {});
  }

  /// Resets cached state back to unloaded.
  @visibleForTesting
  static void clear() {
    _loadGeneration++;
    _inFlightLoad = null;
    _inFlightZone = null;
    _entriesByKey = null;
  }
}
