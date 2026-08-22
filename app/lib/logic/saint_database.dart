import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/prayer_database.dart';

class SaintDatabase {
  static List<Saint>? mockSaints;
  static List<Saint>? _cachedSaints;

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

  /// Filters saints according to search query keywords, doctor status, and gender.
  static List<Saint> searchSaints(
    List<Saint> saints, {
    String query = '',
    bool doctorsOnly = false,
    String? gender,
  }) {
    final trimmed = query.trim().toLowerCase();
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return saints.where((saint) {
      if (doctorsOnly && !saint.isDoctor) {
        return false;
      }
      if (gender != null && gender.isNotEmpty && saint.gender != gender) {
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
            dates.contains(word);
      });
    }).toList();
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
      final parts = saint.feastDay!.split(RegExp(r'[/,;&]'));
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
      final parts = saint.feastDay!.split(RegExp(r'[/,;&]'));
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
