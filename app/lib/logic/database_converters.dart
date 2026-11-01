import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'prayers.dart';

class JsonModelListConverter<T> extends TypeConverter<List<T>, String> {
  final T Function(Map<String, dynamic> json)? fromJson;
  final Map<String, dynamic> Function(T item)? toJson;
  final String errorFallbackSql;

  const JsonModelListConverter({
    this.fromJson,
    this.toJson,
    this.errorFallbackSql = '[]',
  });

  @protected
  T itemFromJson(Map<String, dynamic> json) => fromJson!(json);

  @protected
  Map<String, dynamic> itemToJson(T item) => toJson!(item);

  @override
  List<T> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final dynamic decoded = jsonDecode(fromDb);
      if (decoded is! List) return [];
      final List<T> results = [];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        results.add(itemFromJson(map));
      }
      return results;
    } catch (e, stack) {
      debugPrint('$runtimeType.fromSql error: $e\n$stack');
      return [];
    }
  }

  @override
  String toSql(List<T> value) {
    try {
      return jsonEncode(value.map(itemToJson).toList());
    } catch (e, stack) {
      debugPrint('$runtimeType.toSql error: $e\n$stack');
      return errorFallbackSql;
    }
  }
}

class LocalizedTranslationsConverter
    extends JsonModelListConverter<LocalizedTranslations> {
  const LocalizedTranslationsConverter() : super(errorFallbackSql: '');

  @override
  LocalizedTranslations itemFromJson(Map<String, dynamic> json) =>
      LocalizedTranslations.fromJson(json);

  @override
  Map<String, dynamic> itemToJson(LocalizedTranslations item) => item.toJson();
}

class PreferredVersionsConverter
    extends JsonModelListConverter<PrayerVersionPreference> {
  const PreferredVersionsConverter() : super(errorFallbackSql: '');

  @override
  PrayerVersionPreference itemFromJson(Map<String, dynamic> json) =>
      PrayerVersionPreference.fromJson(json);

  @override
  Map<String, dynamic> itemToJson(PrayerVersionPreference item) =>
      item.toJson();
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
    extends JsonModelListConverter<BibleRibbonBookmark> {
  const BibleRibbonsConverter() : super(errorFallbackSql: '[]');

  @override
  BibleRibbonBookmark itemFromJson(Map<String, dynamic> json) =>
      BibleRibbonBookmark.fromJson(json);

  @override
  Map<String, dynamic> itemToJson(BibleRibbonBookmark item) => item.toJson();
}
