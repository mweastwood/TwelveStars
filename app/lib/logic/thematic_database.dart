import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/thematic_models.dart';

export 'package:twelve_stars/logic/thematic_models.dart';

class ThematicHelper {
  static List<ThematicPassage>? _cachedPassages;
  static List<ThematicPassage>? mockPassages;
  static Random? mockRandom;
  static const String assetPath = 'assets/catechism/thematic_index.json';

  @visibleForTesting
  static void clearCache() {
    _cachedPassages = null;
  }

  static const List<ThematicCategoryGroup> categoryGroups =
      ThematicTaxonomyData.categoryGroups;

  static Map<String, String> get allThemes => ThematicTaxonomyData.allThemes;

  static String getThemeTitle(String themeId) =>
      ThematicTaxonomyData.getThemeTitle(themeId);

  static Future<List<ThematicPassage>> loadAllPassages({
    bool forceReload = false,
  }) async {
    if (mockPassages != null) {
      return mockPassages!;
    }

    if (_cachedPassages != null && !forceReload) {
      return _cachedPassages!;
    }

    try {
      final raw = await rootBundle.loadString(assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final passagesRaw = data['passages'] as List<dynamic>? ?? [];

      _cachedPassages = passagesRaw.map((p) {
        final map = p as Map<String, dynamic>;
        final bookId = map['bookId'] as String? ?? '';
        final saintId = LibraryCatalog.resolveAuthorSaintId(bookId);
        return ThematicPassage.fromJson(map, authorSaintId: saintId);
      }).toList();

      return _cachedPassages!;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, int>> getThemeCounts() async {
    final passages = await loadAllPassages();
    final counts = <String, int>{};
    for (final p in passages) {
      counts[p.primaryTheme] = (counts[p.primaryTheme] ?? 0) + 1;
      for (final s in p.secondaryThemes) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    return counts;
  }

  static Future<List<ThematicPassage>> getPassagesForTheme(
    String themeId, {
    bool shuffle = true,
  }) async {
    final passages = await loadAllPassages();
    final filtered = passages
        .where(
          (p) =>
              p.primaryTheme == themeId || p.secondaryThemes.contains(themeId),
        )
        .toList();

    if (shuffle && filtered.isNotEmpty) {
      filtered.shuffle(mockRandom ?? Random());
    }
    return filtered;
  }
}
