import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/liturgical_calendar_core.dart';

/// Liturgical precedence tier used to order lectionary occurrences for a verse.
enum LectionaryRank {
  solemnityOrTriduum,
  sunday,
  weekday;

  String get label {
    switch (this) {
      case LectionaryRank.solemnityOrTriduum:
        return 'Solemnity / Feast';
      case LectionaryRank.sunday:
        return 'Sunday';
      case LectionaryRank.weekday:
        return 'Weekday';
    }
  }
}

/// Role of a Scripture passage within the Mass Liturgy of the Word.
enum LectionaryReadingRole {
  first,
  psalm,
  second,
  gospel;

  String get label {
    switch (this) {
      case LectionaryReadingRole.first:
        return '1st Reading';
      case LectionaryReadingRole.psalm:
        return 'Responsorial Psalm';
      case LectionaryReadingRole.second:
        return '2nd Reading';
      case LectionaryReadingRole.gospel:
        return 'Gospel';
    }
  }

  /// Display priority when tie-breaking two readings on the same date.
  int get sortOrder {
    switch (this) {
      case LectionaryReadingRole.gospel:
        return 0;
      case LectionaryReadingRole.first:
        return 1;
      case LectionaryReadingRole.second:
        return 2;
      case LectionaryReadingRole.psalm:
        return 3;
    }
  }

  static LectionaryReadingRole parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'first':
        return LectionaryReadingRole.first;
      case 'psalm':
        return LectionaryReadingRole.psalm;
      case 'second':
        return LectionaryReadingRole.second;
      case 'gospel':
      default:
        return LectionaryReadingRole.gospel;
    }
  }
}

/// A Mass lectionary passage starting at a specific Bible verse.
class LectionaryOccurrence {
  final String readingKey;
  final List<String> readingKeys;
  final String title;
  final LectionaryReadingRole role;
  final LectionaryRank rank;
  final LiturgicalColor liturgicalColor;
  final int bookNumber;
  final String bookName;
  final int startChapter;
  final int startVerse;
  final String citation;
  final String verseRange;

  const LectionaryOccurrence({
    required this.readingKey,
    required this.readingKeys,
    required this.title,
    required this.role,
    required this.rank,
    required this.liturgicalColor,
    required this.bookNumber,
    required this.bookName,
    required this.startChapter,
    required this.startVerse,
    required this.citation,
    required this.verseRange,
  });
}

/// Pairs a [LectionaryOccurrence] with its next upcoming calendar date.
class LectionaryOccurrenceWithDate {
  final LectionaryOccurrence occurrence;
  final DateTime? nextDate;

  const LectionaryOccurrenceWithDate({
    required this.occurrence,
    required this.nextDate,
  });
}

class _ParsedKeyMetadata {
  final String title;
  final LectionaryRank rank;
  final LiturgicalColor color;
  final bool isFallback;

  const _ParsedKeyMetadata({
    required this.title,
    required this.rank,
    required this.color,
    this.isFallback = false,
  });
}

class _RawOccurrence {
  final String readingKey;
  final LectionaryReadingRole role;
  final int bookNumber;
  final String bookName;
  final int startChapter;
  final int startVerse;
  final String citation;
  final String verseRange;

  const _RawOccurrence({
    required this.readingKey,
    required this.role,
    required this.bookNumber,
    required this.bookName,
    required this.startChapter,
    required this.startVerse,
    required this.citation,
    required this.verseRange,
  });
}

/// In-memory reverse index mapping `(bookNumber, chapter, startVerse)` in
/// Vulgate numbering to the Mass lectionary readings that begin at that verse.
class LectionaryReverseIndex {
  static const String _assetPath = 'assets/bible/lectionary.json';

  /// Fast upfront scan window (~4 years) covering standard Sunday cycles A/B/C
  /// and Weekday cycles I/II.
  static const int _initialCalendarScanDays = 1465;

  /// Extended on-demand scan ceiling (~40 years) used lazily only when an
  /// occurrence in an opened modal has rare Easter/weekday alignment beyond
  /// [_initialCalendarScanDays] (e.g. Advent 4 Saturday or rare OT week 6–9
  /// cycle intersections).
  static const int _extendedCalendarScanDays = 14610;

  /// Unreachable legacy duplicate keys in `lectionary.json` that are never
  /// emitted by [LiturgicalCalendar.computeDay] and whose contents duplicate
  /// Pentecost, 2nd Sunday of Easter, or 2nd Sunday in Ordinary Time.
  static const Set<String> _ignoredOrphanKeys = {
    'season_easter_1_sunday_a',
    'season_easter_1_sunday_b',
    'season_easter_1_sunday_c',
    'season_ordinary_time_1_sunday_a',
    'season_ordinary_time_1_sunday_b',
  };

  static final Map<int, Map<int, Map<int, List<LectionaryOccurrence>>>>
  _verseIndex = {};
  static bool _isLoaded = false;
  static Future<void>? _inFlightLoad;
  static int _loadGeneration = 0;

  static int? _cachedDateKey;
  static int _cachedScannedDays = 0;
  static Map<String, DateTime>? _cachedNextDatesByKey;

  static final RegExp _ordinaryWeekdayRegex = RegExp(
    r'^season_ordinary_time_(\d+)_(monday|tuesday|wednesday|thursday|friday|saturday)_([12])$',
  );
  static final RegExp _sundayRegex = RegExp(
    r'^season_(advent|lent|easter|ordinary_time)_(\d+)_sunday_([abc])$',
  );
  static final RegExp _seasonWeekdayRegex = RegExp(
    r'^season_(advent|lent|easter)_(\d+)_(monday|tuesday|wednesday|thursday|friday|saturday)$',
  );
  static final RegExp _christmasDateRegex = RegExp(
    r'^season_christmas_(\d+)_(\d+)$',
  );
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// Whether the bundled lectionary reverse index has been loaded.
  static bool get isLoaded => _isLoaded;

  /// Clears all cached index and calendar date state. Intended for tests.
  static void resetForTesting() {
    _loadGeneration++;
    _verseIndex.clear();
    _isLoaded = false;
    _inFlightLoad = null;
    _cachedDateKey = null;
    _cachedScannedDays = 0;
    _cachedNextDatesByKey = null;
  }

  /// Marks the index as loaded with zero entries so unrelated widget/golden
  /// tests do not race with async `assets/bible/lectionary.json` loading.
  @visibleForTesting
  static void setEmptyForTesting() {
    _loadGeneration++;
    _verseIndex.clear();
    _isLoaded = true;
    _inFlightLoad = null;
    _cachedDateKey = null;
    _cachedScannedDays = 0;
    _cachedNextDatesByKey = null;
  }

  /// Returns all indexed occurrences across the entire loaded index.
  @visibleForTesting
  static List<LectionaryOccurrence> get allIndexedOccurrencesForTesting => [
    for (final bookMap in _verseIndex.values)
      for (final chapterMap in bookMap.values)
        for (final list in chapterMap.values) ...list,
  ];

  /// Returns whether [key] matches an explicit liturgical rule (not fallback).
  @visibleForTesting
  static bool isRecognizedKey(String key) => !_parseKeyMetadata(key).isFallback;

  /// Ensures `assets/bible/lectionary.json` is loaded and indexed once.
  static Future<void> ensureLoaded() {
    if (_isLoaded) return Future.value();
    if (_inFlightLoad != null) return _inFlightLoad!;

    final gen = _loadGeneration;
    final future = _loadFromAsset(gen);
    _inFlightLoad = future;
    return future.whenComplete(() {
      if (identical(_inFlightLoad, future)) {
        _inFlightLoad = null;
      }
    });
  }

  static Future<void> _loadFromAsset(int generation) async {
    final rawJson = await rootBundle.loadString(_assetPath);
    if (generation != _loadGeneration) return;
    _loadFromJsonStringInternal(rawJson);
  }

  /// Builds the reverse index directly from a JSON string (used internally and
  /// in unit tests).
  static void loadFromJsonString(String rawJson) {
    _loadGeneration++;
    _inFlightLoad = null;
    _loadFromJsonStringInternal(rawJson);
  }

  static void _loadFromJsonStringInternal(String rawJson) {
    _verseIndex.clear();
    final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
    final rawEntries = <_RawOccurrence>[];

    for (final dynamic item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final readingKey = item['reading_key'] as String?;
      final readingType = item['reading_type'] as String?;
      final bookNumber = (item['book_number'] as num?)?.toInt();
      final bookName = item['book_name'] as String?;
      final chapter = (item['chapter'] as num?)?.toInt();
      final verseRange = item['verse_range'] as String? ?? '';
      final citation = item['citation'] as String? ?? '';

      if (readingKey == null ||
          _ignoredOrphanKeys.contains(readingKey) ||
          readingType == null ||
          bookNumber == null ||
          bookName == null ||
          chapter == null) {
        continue;
      }

      final ranges = resolveReadingRanges(
        bookNumber: bookNumber,
        defaultChapter: chapter,
        defaultVerseRange: verseRange,
        citation: citation,
      );
      if (ranges.isEmpty) continue;

      final firstRange = ranges.first;
      final startChapter = firstRange.chapter;
      final startVerse =
          (firstRange.verses != null && firstRange.verses!.isNotEmpty)
          ? firstRange.verses!.first
          : (firstRange.startVerseLimit ?? 1);

      rawEntries.add(
        _RawOccurrence(
          readingKey: readingKey,
          role: LectionaryReadingRole.parse(readingType),
          bookNumber: bookNumber,
          bookName: bookName,
          startChapter: startChapter,
          startVerse: startVerse,
          citation: citation.trim(),
          verseRange: verseRange.trim(),
        ),
      );
    }

    // Group identical Ordinary Time weekday Year I & II entries into a single
    // occurrence (e.g. weekday Gospels that are identical across Years I & II).
    final Map<String, List<_RawOccurrence>> grouped = {};
    final List<String> insertionOrder = [];

    for (final entry in rawEntries) {
      final dedupKey = _dedupGroupKey(entry);
      final bucket = grouped[dedupKey];
      if (bucket == null) {
        grouped[dedupKey] = [entry];
        insertionOrder.add(dedupKey);
      } else {
        bucket.add(entry);
      }
    }

    for (final groupKey in insertionOrder) {
      final bucket = grouped[groupKey]!;
      final occurrence = _buildOccurrenceFromBucket(bucket);
      final bookMap = _verseIndex.putIfAbsent(occurrence.bookNumber, () => {});
      final chapterMap = bookMap.putIfAbsent(occurrence.startChapter, () => {});
      final verseList = chapterMap.putIfAbsent(occurrence.startVerse, () => []);
      verseList.add(occurrence);
    }

    // Pre-sort each verse bucket deterministically by liturgical rank, role,
    // and title so lookup order is stable even before date resolution.
    for (final bookMap in _verseIndex.values) {
      for (final chapterMap in bookMap.values) {
        for (final verseList in chapterMap.values) {
          verseList.sort((a, b) {
            final rankCmp = a.rank.index.compareTo(b.rank.index);
            if (rankCmp != 0) return rankCmp;
            final roleCmp = a.role.sortOrder.compareTo(b.role.sortOrder);
            if (roleCmp != 0) return roleCmp;
            return a.title.compareTo(b.title);
          });
        }
      }
    }

    _isLoaded = true;
  }

  static String _dedupGroupKey(_RawOccurrence entry) {
    final weekdayMatch = _ordinaryWeekdayRegex.firstMatch(entry.readingKey);
    if (weekdayMatch != null) {
      final week = weekdayMatch.group(1)!;
      final day = weekdayMatch.group(2)!;
      final normRange = entry.verseRange
          .toLowerCase()
          .replaceAll('–', '-')
          .replaceAll('—', '-')
          .replaceAll(_whitespaceRegex, '');
      return 'ot_${week}_${day}_${entry.role.name}_${entry.bookNumber}_${entry.startChapter}_${entry.startVerse}_$normRange';
    }
    return '${entry.readingKey}_${entry.role.name}_${entry.bookNumber}_${entry.startChapter}_${entry.startVerse}_${entry.citation}';
  }

  static LectionaryOccurrence _buildOccurrenceFromBucket(
    List<_RawOccurrence> bucket,
  ) {
    // Prefer the entry with the fuller (longer) citation string (e.g.
    // "Matthew 5:27-32" over "Mt 5:27-32").
    bucket.sort((a, b) => a.readingKey.compareTo(b.readingKey));
    final primary = bucket.reduce(
      (a, b) => b.citation.length > a.citation.length ? b : a,
    );
    final keys = bucket.map((e) => e.readingKey).toSet().toList()..sort();

    final isMergedWeekdayPair =
        keys.length >= 2 &&
        keys.every((k) => _ordinaryWeekdayRegex.hasMatch(k));

    final meta = isMergedWeekdayPair
        ? _parseMergedOrdinaryWeekday(keys.first)
        : _parseKeyMetadata(primary.readingKey);

    return LectionaryOccurrence(
      readingKey: keys.first,
      readingKeys: List.unmodifiable(keys),
      title: meta.title,
      role: primary.role,
      rank: meta.rank,
      liturgicalColor: meta.color,
      bookNumber: primary.bookNumber,
      bookName: primary.bookName,
      startChapter: primary.startChapter,
      startVerse: primary.startVerse,
      citation: primary.citation,
      verseRange: primary.verseRange,
    );
  }

  /// Returns all Mass lectionary readings starting at the given Vulgate
  /// [bookNumber], [chapter], and [verse]. Returns an empty list if none start
  /// there or if the index is not loaded yet.
  static List<LectionaryOccurrence> getVerseOccurrences(
    int bookNumber,
    int chapter,
    int verse,
  ) {
    if (!_isLoaded) return const [];
    final list = _verseIndex[bookNumber]?[chapter]?[verse];
    if (list == null || list.isEmpty) return const [];
    return List.unmodifiable(list);
  }

  /// Resolves each occurrence's next upcoming calendar date relative to
  /// [referenceDate] (defaults to today) and sorts by liturgical rank first
  /// (Solemnities & Triduum → Sundays → Weekdays), then chronologically by
  /// upcoming date within each rank group.
  static List<LectionaryOccurrenceWithDate> resolveOccurrencesWithDates(
    List<LectionaryOccurrence> occurrences, {
    DateTime? referenceDate,
  }) {
    if (occurrences.isEmpty) return const [];
    final now = referenceDate ?? DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    final nextDatesByKey = _getNextDatesByKey(dateOnly);

    // If any requested occurrence has no key resolved within the initial 4-year
    // window (rare Easter/weekday intersections), extend the cached scan lazily
    // only until all requested occurrences have at least one resolved key.
    final unresolvedOccurrences = occurrences
        .where((occ) => !occ.readingKeys.any(nextDatesByKey.containsKey))
        .toList();
    if (unresolvedOccurrences.isNotEmpty &&
        _cachedScannedDays < _extendedCalendarScanDays) {
      _extendNextDatesScan(dateOnly, nextDatesByKey, unresolvedOccurrences);
    }

    final resolved = occurrences.map((occ) {
      DateTime? earliest;
      for (final key in occ.readingKeys) {
        final candidate = nextDatesByKey[key];
        if (candidate != null &&
            (earliest == null || candidate.isBefore(earliest))) {
          earliest = candidate;
        }
      }
      return LectionaryOccurrenceWithDate(occurrence: occ, nextDate: earliest);
    }).toList();

    resolved.sort((a, b) {
      final rankCmp = a.occurrence.rank.index.compareTo(
        b.occurrence.rank.index,
      );
      if (rankCmp != 0) return rankCmp;

      final aDate = a.nextDate;
      final bDate = b.nextDate;
      if (aDate != null && bDate != null) {
        final dateCmp = aDate.compareTo(bDate);
        if (dateCmp != 0) return dateCmp;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }

      final roleCmp = a.occurrence.role.sortOrder.compareTo(
        b.occurrence.role.sortOrder,
      );
      if (roleCmp != 0) return roleCmp;
      return a.occurrence.title.compareTo(b.occurrence.title);
    });

    return resolved;
  }

  static Map<String, DateTime> _getNextDatesByKey(DateTime dateOnly) {
    final dateKey = dateOnly.year * 10000 + dateOnly.month * 100 + dateOnly.day;
    if (_cachedDateKey == dateKey && _cachedNextDatesByKey != null) {
      return _cachedNextDatesByKey!;
    }

    final map = <String, DateTime>{};
    for (int offset = 0; offset < _initialCalendarScanDays; offset++) {
      final d = DateTime(dateOnly.year, dateOnly.month, dateOnly.day + offset);
      final litDay = LiturgicalCalendar.computeDay(d);
      map.putIfAbsent(litDay.lectionaryKey, () => d);
    }

    _cachedDateKey = dateKey;
    _cachedScannedDays = _initialCalendarScanDays;
    _cachedNextDatesByKey = map;
    return map;
  }

  static void _extendNextDatesScan(
    DateTime dateOnly,
    Map<String, DateTime> map,
    List<LectionaryOccurrence> unresolvedOccurrences,
  ) {
    final remaining = List<LectionaryOccurrence>.of(unresolvedOccurrences);
    for (
      int offset = _cachedScannedDays;
      offset < _extendedCalendarScanDays;
      offset++
    ) {
      final d = DateTime(dateOnly.year, dateOnly.month, dateOnly.day + offset);
      final litDay = LiturgicalCalendar.computeDay(d);
      final key = litDay.lectionaryKey;
      map.putIfAbsent(key, () => d);
      _cachedScannedDays = offset + 1;

      remaining.removeWhere((occ) => occ.readingKeys.contains(key));
      if (remaining.isEmpty) {
        break;
      }
    }
  }

  static _ParsedKeyMetadata _parseMergedOrdinaryWeekday(String key) {
    final m = _ordinaryWeekdayRegex.firstMatch(key)!;
    final week = int.parse(m.group(1)!);
    final day = _capitalize(m.group(2)!);
    return _ParsedKeyMetadata(
      title:
          '$day of the ${_ordinal(week)} Week in Ordinary Time (Years I & II)',
      rank: LectionaryRank.weekday,
      color: LiturgicalColor.green,
    );
  }

  static _ParsedKeyMetadata _parseKeyMetadata(String key) {
    const fixedFeasts = <String, _ParsedKeyMetadata>{
      'feast_all_saints': _ParsedKeyMetadata(
        title: 'All Saints',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_annunciation': _ParsedKeyMetadata(
        title: 'The Annunciation of the Lord',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_assumption': _ParsedKeyMetadata(
        title: 'The Assumption of the Blessed Virgin Mary',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_baptism_of_the_lord': _ParsedKeyMetadata(
        title: 'The Baptism of the Lord',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_corpus_christi': _ParsedKeyMetadata(
        title: 'The Most Holy Body and Blood of Christ (Corpus Christi)',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_epiphany': _ParsedKeyMetadata(
        title: 'The Epiphany of the Lord',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_holy_family': _ParsedKeyMetadata(
        title: 'The Holy Family of Jesus, Mary and Joseph',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_holy_trinity': _ParsedKeyMetadata(
        title: 'The Most Holy Trinity',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_immaculate_conception': _ParsedKeyMetadata(
        title: 'The Immaculate Conception of the Blessed Virgin Mary',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_sacred_heart': _ParsedKeyMetadata(
        title: 'The Most Sacred Heart of Jesus',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_st_john_baptist': _ParsedKeyMetadata(
        title: 'The Nativity of St. John the Baptist',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_st_joseph': _ParsedKeyMetadata(
        title: 'St. Joseph, Spouse of the Blessed Virgin Mary',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'feast_st_peter_paul': _ParsedKeyMetadata(
        title: 'Sts. Peter and Paul, Apostles',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.red,
      ),
      'triduum_holy_thursday': _ParsedKeyMetadata(
        title: "Holy Thursday (Mass of the Lord's Supper)",
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'triduum_good_friday': _ParsedKeyMetadata(
        title: "Good Friday of the Lord's Passion",
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.red,
      ),
      'triduum_holy_saturday': _ParsedKeyMetadata(
        title: 'The Easter Vigil in the Holy Night',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'season_easter_sunday': _ParsedKeyMetadata(
        title: 'Easter Sunday of the Resurrection of the Lord',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'season_lent_ash_wednesday': _ParsedKeyMetadata(
        title: 'Ash Wednesday',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.purple,
      ),
      'season_christmas_12_25': _ParsedKeyMetadata(
        title: 'The Nativity of the Lord (Christmas)',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'season_christmas_1_1': _ParsedKeyMetadata(
        title: 'Solemnity of Mary, the Holy Mother of God',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'season_christmas_12_26': _ParsedKeyMetadata(
        title: 'St. Stephen, First Martyr (Dec 26)',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.red,
      ),
      'season_christmas_12_27': _ParsedKeyMetadata(
        title: 'St. John, Apostle and Evangelist (Dec 27)',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.white,
      ),
      'season_christmas_12_28': _ParsedKeyMetadata(
        title: 'The Holy Innocents, Martyrs (Dec 28)',
        rank: LectionaryRank.solemnityOrTriduum,
        color: LiturgicalColor.red,
      ),
    };

    final fixed = fixedFeasts[key];
    if (fixed != null) return fixed;

    final sundayMatch = _sundayRegex.firstMatch(key);
    if (sundayMatch != null) {
      final season = sundayMatch.group(1)!;
      final week = int.parse(sundayMatch.group(2)!);
      final cycle = sundayMatch.group(3)!.toUpperCase();

      if (season == 'lent' && week == 6) {
        return _ParsedKeyMetadata(
          title: 'Palm Sunday of the Passion of the Lord (Year $cycle)',
          rank: LectionaryRank.solemnityOrTriduum,
          color: LiturgicalColor.red,
        );
      }
      if (season == 'easter' && week == 8) {
        return _ParsedKeyMetadata(
          title: 'Pentecost Sunday (Year $cycle)',
          rank: LectionaryRank.solemnityOrTriduum,
          color: LiturgicalColor.red,
        );
      }
      if (season == 'ordinary_time' && week == 34) {
        return _ParsedKeyMetadata(
          title: 'Our Lord Jesus Christ, King of the Universe (Year $cycle)',
          rank: LectionaryRank.solemnityOrTriduum,
          color: LiturgicalColor.white,
        );
      }

      switch (season) {
        case 'advent':
          return _ParsedKeyMetadata(
            title: '${_ordinal(week)} Sunday of Advent (Year $cycle)',
            rank: LectionaryRank.sunday,
            color: week == 3 ? LiturgicalColor.rose : LiturgicalColor.purple,
          );
        case 'lent':
          return _ParsedKeyMetadata(
            title: '${_ordinal(week)} Sunday of Lent (Year $cycle)',
            rank: LectionaryRank.sunday,
            color: week == 4 ? LiturgicalColor.rose : LiturgicalColor.purple,
          );
        case 'easter':
          return _ParsedKeyMetadata(
            title: '${_ordinal(week)} Sunday of Easter (Year $cycle)',
            rank: LectionaryRank.sunday,
            color: LiturgicalColor.white,
          );
        case 'ordinary_time':
        default:
          return _ParsedKeyMetadata(
            title: '${_ordinal(week)} Sunday in Ordinary Time (Year $cycle)',
            rank: LectionaryRank.sunday,
            color: LiturgicalColor.green,
          );
      }
    }

    final otWeekdayMatch = _ordinaryWeekdayRegex.firstMatch(key);
    if (otWeekdayMatch != null) {
      final week = int.parse(otWeekdayMatch.group(1)!);
      final day = _capitalize(otWeekdayMatch.group(2)!);
      final yearRoman = otWeekdayMatch.group(3) == '2' ? 'II' : 'I';
      return _ParsedKeyMetadata(
        title:
            '$day of the ${_ordinal(week)} Week in Ordinary Time (Year $yearRoman)',
        rank: LectionaryRank.weekday,
        color: LiturgicalColor.green,
      );
    }

    final seasonWeekdayMatch = _seasonWeekdayRegex.firstMatch(key);
    if (seasonWeekdayMatch != null) {
      final season = seasonWeekdayMatch.group(1)!;
      final week = int.parse(seasonWeekdayMatch.group(2)!);
      final day = _capitalize(seasonWeekdayMatch.group(3)!);

      switch (season) {
        case 'advent':
          return _ParsedKeyMetadata(
            title: '$day of the ${_ordinal(week)} Week of Advent',
            rank: LectionaryRank.weekday,
            color: LiturgicalColor.purple,
          );
        case 'lent':
          if (week == 0) {
            return _ParsedKeyMetadata(
              title: '$day after Ash Wednesday',
              rank: LectionaryRank.weekday,
              color: LiturgicalColor.purple,
            );
          }
          if (week == 6) {
            return _ParsedKeyMetadata(
              title: '$day of Holy Week',
              rank: LectionaryRank.weekday,
              color: LiturgicalColor.purple,
            );
          }
          return _ParsedKeyMetadata(
            title: '$day of the ${_ordinal(week)} Week of Lent',
            rank: LectionaryRank.weekday,
            color: LiturgicalColor.purple,
          );
        case 'easter':
        default:
          if (week == 1) {
            return _ParsedKeyMetadata(
              title: '$day within the Octave of Easter',
              rank: LectionaryRank.weekday,
              color: LiturgicalColor.white,
            );
          }
          return _ParsedKeyMetadata(
            title: '$day of the ${_ordinal(week)} Week of Easter',
            rank: LectionaryRank.weekday,
            color: LiturgicalColor.white,
          );
      }
    }

    final christmasMatch = _christmasDateRegex.firstMatch(key);
    if (christmasMatch != null) {
      final month = int.parse(christmasMatch.group(1)!);
      final day = int.parse(christmasMatch.group(2)!);
      if (month == 12) {
        return _ParsedKeyMetadata(
          title: 'Christmas Octave (Dec $day)',
          rank: LectionaryRank.weekday,
          color: LiturgicalColor.white,
        );
      }
      return _ParsedKeyMetadata(
        title: 'Christmas Weekday (Jan $day)',
        rank: LectionaryRank.weekday,
        color: LiturgicalColor.white,
      );
    }

    // Fallback for any unexpected key format.
    final fallbackTitle = key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(_capitalize)
        .join(' ');
    return _ParsedKeyMetadata(
      title: fallbackTitle,
      rank: LectionaryRank.weekday,
      color: LiturgicalColor.green,
      isFallback: true,
    );
  }

  static String _capitalize(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }

  static String _ordinal(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
