import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/saint_models.dart';

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

  /// Filters saints according to search query keywords and doctor status.
  static List<Saint> searchSaints(
    List<Saint> saints, {
    String query = '',
    bool doctorsOnly = false,
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

      return words.every((word) {
        return name.contains(word) ||
            nationality.contains(word) ||
            profession.contains(word) ||
            patronage.contains(word) ||
            summary.contains(word) ||
            feastDay.contains(word) ||
            dates.contains(word);
      });
    }).toList();
  }
}
