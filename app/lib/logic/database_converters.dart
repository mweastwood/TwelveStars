import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'prayers.dart';

class LocalizedTranslationsConverter
    extends TypeConverter<List<LocalizedTranslations>, String> {
  const LocalizedTranslationsConverter();

  @override
  List<LocalizedTranslations> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final dynamic decoded = jsonDecode(fromDb);
      if (decoded is! List) return [];
      final List<LocalizedTranslations> results = [];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        results.add(LocalizedTranslations.fromJson(map));
      }
      return results;
    } catch (e, stack) {
      debugPrint('LocalizedTranslationsConverter.fromSql error: $e\n$stack');
      return [];
    }
  }

  @override
  String toSql(List<LocalizedTranslations> value) {
    try {
      return jsonEncode(value.map((item) => item.toJson()).toList());
    } catch (e, stack) {
      debugPrint('LocalizedTranslationsConverter.toSql error: $e\n$stack');
      return '';
    }
  }
}

class PreferredVersionsConverter
    extends TypeConverter<List<PrayerVersionPreference>, String> {
  const PreferredVersionsConverter();

  @override
  List<PrayerVersionPreference> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final dynamic decoded = jsonDecode(fromDb);
      if (decoded is! List) return [];
      final List<PrayerVersionPreference> results = [];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        results.add(PrayerVersionPreference.fromJson(map));
      }
      return results;
    } catch (e, stack) {
      debugPrint('PreferredVersionsConverter.fromSql error: $e\n$stack');
      return [];
    }
  }

  @override
  String toSql(List<PrayerVersionPreference> value) {
    try {
      return jsonEncode(value.map((item) => item.toJson()).toList());
    } catch (e, stack) {
      debugPrint('PreferredVersionsConverter.toSql error: $e\n$stack');
      return '';
    }
  }
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final dynamic decoded = jsonDecode(fromDb);
      if (decoded is! List) return [];
      return decoded.map((e) => e.toString()).toList();
    } catch (e, stack) {
      debugPrint('StringListConverter.fromSql error: $e\n$stack');
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    try {
      return jsonEncode(value);
    } catch (e, stack) {
      debugPrint('StringListConverter.toSql error: $e\n$stack');
      return '[]';
    }
  }
}

class BibleRibbonsConverter
    extends TypeConverter<List<BibleRibbonBookmark>, String> {
  const BibleRibbonsConverter();

  @override
  List<BibleRibbonBookmark> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final dynamic decoded = jsonDecode(fromDb);
      if (decoded is! List) return [];
      final List<BibleRibbonBookmark> results = [];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        results.add(BibleRibbonBookmark.fromJson(map));
      }
      return results;
    } catch (e, stack) {
      debugPrint('BibleRibbonsConverter.fromSql error: $e\n$stack');
      return [];
    }
  }

  @override
  String toSql(List<BibleRibbonBookmark> value) {
    try {
      final List<Map<String, dynamic>> list = value
          .map((item) => item.toJson())
          .toList();
      return jsonEncode(list);
    } catch (e, stack) {
      debugPrint('BibleRibbonsConverter.toSql error: $e\n$stack');
      return '[]';
    }
  }
}
