import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/prayer_database.dart';

class SaintDatabase {
  static List<Saint>? mockSaints;
  static List<Saint>? _cachedSaints;

  static final RegExp _whitespaceSplitRegex = RegExp(r'\s+');
  static final RegExp _feastDaySplitRegex = RegExp(r'[/,;&]');

  @visibleForTesting
  static void resetCache() {
    _cachedSaints = null;
  }

  /// Loads saints from assets or returns in-memory cached/mock data.
  static Future<List<Saint>> loadSaints() async {
    if (mockSaints != null) {
      return mockSaints!;
    }
    if (PrayerDatabase.mockPrayers != null) {
      return const [];
    }
    if (_cachedSaints != null) {
      return _cachedSaints!;
    }

    final jsonStr = await rootBundle.loadString('assets/saints.json');
    final saints = loadSaintsFromJson(jsonStr);
    _cachedSaints = saints;
    return saints;
  }

  /// Looks up a Saint by [id].
  static Future<Saint?> getSaintById(String id) async {
    final saints = await loadSaints();
    try {
      return saints.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Parses JSON string into a list of Saint objects.
  static List<Saint> loadSaintsFromJson(String jsonStr) {
    if (jsonStr.isEmpty) return [];

    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (_) {
      return [];
    }

    if (decoded is! List) {
      return [];
    }

    final List<Saint> saints = [];
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item);
      saints.add(Saint.fromJson(map));
    }

    return saints;
  }

  /// Filters and sorts saints according to search query keywords, doctor status,
  /// gender, role category, historical era, feast month, and sorting criteria.
  static List<Saint> searchSaints(
    List<Saint> saints, {
    String query = '',
    bool doctorsOnly = false,
    String? gender,
    SaintCategory? category,
    SaintEra era = SaintEra.all,
    int? feastMonth,
    SaintSortOption sortBy = SaintSortOption.nameAsc,
  }) {
    final trimmed = query.trim().toLowerCase();
    final words = trimmed
        .split(_whitespaceSplitRegex)
        .where((w) => w.isNotEmpty)
        .toList();

    final filtered = saints.where((saint) {
      if (doctorsOnly && !saint.isDoctor) {
        return false;
      }
      if (gender != null && gender.isNotEmpty && saint.gender != gender) {
        return false;
      }
      if (category != null && !saint.categories.contains(category)) {
        return false;
      }
      if (era != SaintEra.all && saint.era != era) {
        return false;
      }
      if (feastMonth != null && saint.feastMonth != feastMonth) {
        return false;
      }
      if (words.isEmpty) {
        return true;
      }

      final name = saint.name.toLowerCase();
      final nationality = saint.nationality.toLowerCase();
      final profession = saint.profession.toLowerCase();
      final patronage = (saint.patronage ?? '').toLowerCase();
      final summary = (saint.summary ?? '').toLowerCase();
      final feastDay = (saint.feastDay ?? '').toLowerCase();
      final dates = saint.dateRange.toLowerCase();
      final saintGender = (saint.gender ?? '').toLowerCase();
      final categoryLabels = saint.categories
          .map((c) => c.label.toLowerCase())
          .toList();
      final eraLabel = saint.era.label.toLowerCase();

      return words.every((word) {
        final matchesGenderWord =
            (saintGender == 'male' &&
                (word == 'male' || word == 'men' || word == 'man')) ||
            (saintGender == 'female' &&
                (word == 'female' || word == 'women' || word == 'woman')) ||
            (saintGender == 'group' &&
                (word == 'group' || word == 'groups' || word == 'companions'));

        return matchesGenderWord ||
            name.contains(word) ||
            nationality.contains(word) ||
            profession.contains(word) ||
            patronage.contains(word) ||
            summary.contains(word) ||
            feastDay.contains(word) ||
            dates.contains(word) ||
            eraLabel.contains(word) ||
            categoryLabels.any((label) => label.contains(word));
      });
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      switch (sortBy) {
        case SaintSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SaintSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case SaintSortOption.feastDay:
          final aMonth = a.feastMonth ?? 99;
          final bMonth = b.feastMonth ?? 99;
          if (aMonth != bMonth) return aMonth.compareTo(bMonth);
          final aDay = a.feastDayOfMonth ?? 99;
          final bDay = b.feastDayOfMonth ?? 99;
          if (aDay != bDay) return aDay.compareTo(bDay);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SaintSortOption.chronologicalAsc:
          final aYear = a.approximateYear ?? 9999;
          final bYear = b.approximateYear ?? 9999;
          if (aYear != bYear) return aYear.compareTo(bYear);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SaintSortOption.chronologicalDesc:
          final aYear = a.approximateYear ?? -9999;
          final bYear = b.approximateYear ?? -9999;
          if (aYear != bYear) return bYear.compareTo(aYear);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SaintSortOption.doctorsFirst:
          if (a.isDoctor != b.isDoctor) {
            return a.isDoctor ? -1 : 1;
          }
          final aIsSpecial =
              a.category == SaintCategory.angel ||
              a.category == SaintCategory.holyFamily ||
              a.category == SaintCategory.patriarch ||
              a.category == SaintCategory.prophet ||
              a.category == SaintCategory.judge ||
              a.category == SaintCategory.apostle ||
              a.category == SaintCategory.evangelist;
          final bIsSpecial =
              b.category == SaintCategory.angel ||
              b.category == SaintCategory.holyFamily ||
              b.category == SaintCategory.patriarch ||
              b.category == SaintCategory.prophet ||
              b.category == SaintCategory.judge ||
              b.category == SaintCategory.apostle ||
              b.category == SaintCategory.evangelist;
          if (aIsSpecial != bIsSpecial) {
            return aIsSpecial ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return filtered;
  }

  static final RegExp _datePartRegex = RegExp(r'([A-Za-z]+)\s+(\d+)');
  static const Map<String, int> _monthNames = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };

  /// Precomputes a lookup index keyed by "${month}_${day}" (e.g. "1_28")
  /// for O(1) lookup during calendar grid rendering.
  static Map<String, List<Saint>> buildFeastDayMap(List<Saint> saints) {
    final Map<String, List<Saint>> map = {};
    for (final saint in saints) {
      if (saint.feastDay == null || saint.feastDay!.isEmpty) continue;
      final parts = saint.feastDay!.split(_feastDaySplitRegex);
      for (final part in parts) {
        final match = _datePartRegex.firstMatch(part.trim());
        if (match != null) {
          final monthStr = match.group(1)?.toLowerCase();
          final dayStr = match.group(2);
          if (monthStr != null &&
              dayStr != null &&
              _monthNames.containsKey(monthStr)) {
            final month = _monthNames[monthStr]!;
            final day = int.tryParse(dayStr);
            if (day != null && day >= 1 && day <= 31) {
              final key = '${month}_$day';
              final list = map.putIfAbsent(key, () => []);
              if (!list.any((s) => s.id == saint.id)) {
                list.add(saint);
              }
            }
          }
        }
      }
    }
    return map;
  }

  /// Returns saints whose feast day matches [date.month] and [date.day].
  static List<Saint> getSaintsForDate(DateTime date, List<Saint> saints) {
    final List<Saint> matching = [];
    for (final saint in saints) {
      if (saint.feastDay == null || saint.feastDay!.isEmpty) continue;
      final parts = saint.feastDay!.split(_feastDaySplitRegex);
      for (final part in parts) {
        final match = _datePartRegex.firstMatch(part.trim());
        if (match != null) {
          final monthStr = match.group(1)?.toLowerCase();
          final dayStr = match.group(2);
          if (monthStr != null &&
              dayStr != null &&
              _monthNames.containsKey(monthStr)) {
            final month = _monthNames[monthStr]!;
            final day = int.tryParse(dayStr);
            if (month == date.month && day == date.day) {
              matching.add(saint);
              break;
            }
          }
        }
      }
    }
    return matching;
  }
}
