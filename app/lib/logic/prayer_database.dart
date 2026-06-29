import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:twelve_stars/logic/prayers.dart';

class PrayerDatabase {
  static List<Prayer>? mockPrayers;
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, "prayers.db");

    // Copy from assets on first run or when the database needs update
    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(p.dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(p.join("assets", "prayers.db"));
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  // Fetch all prayers from the database
  static Future<List<Prayer>> loadPrayers() async {
    if (mockPrayers != null) {
      return mockPrayers!;
    }
    final db = await database;

    final List<Map<String, dynamic>> prayerMaps = await db.query(
      'prayers',
      orderBy: 'default_order ASC',
    );

    final List<Prayer> prayers = [];

    for (final pMap in prayerMaps) {
      final prayerId = pMap['id'] as String;
      final defaultTitle = pMap['default_title'] as String;

      // Fetch all translations for this prayer
      final List<Map<String, dynamic>> tMaps = await db.query(
        'translations',
        where: 'prayer_id = ?',
        whereArgs: [prayerId],
      );

      final Map<PrayerLanguage, List<PrayerTranslation>> translations = {};

      for (final tMap in tMaps) {
        final langStr = tMap['language'] as String;

        // Find matching PrayerLanguage enum
        final language = PrayerLanguage.values.firstWhere(
          (e) => e.toString().split('.').last == langStr,
          orElse: () => PrayerLanguage.english,
        );

        final title = tMap['title'] as String;
        final subtitle = tMap['subtitle'] as String? ?? '';
        final text = tMap['text'] as String;
        final sourceName = tMap['source_name'] as String? ?? '';
        final sourceUrl = tMap['source_url'] as String? ?? '';
        final chineseLinesJson = tMap['chinese_lines'] as String?;

        List<List<ChineseChar>>? chineseLines;
        if (chineseLinesJson != null) {
          final List<dynamic> outer = jsonDecode(chineseLinesJson);
          chineseLines = outer.map((line) {
            final List<dynamic> charList = line;
            return charList.map((item) {
              final map = item as Map<String, dynamic>;
              return ChineseChar(
                map['char'] as String? ?? '',
                map['pinyin'] as String? ?? '',
              );
            }).toList();
          }).toList();
        }

        final translation = PrayerTranslation(
          title: title,
          subtitle: subtitle,
          text: text,
          sourceName: sourceName,
          sourceUrl: sourceUrl,
          chineseLines: chineseLines,
        );

        if (!translations.containsKey(language)) {
          translations[language] = [];
        }
        translations[language]!.add(translation);
      }

      prayers.add(
        Prayer(
          id: prayerId,
          defaultTitle: defaultTitle,
          translations: translations,
        ),
      );
    }

    return prayers;
  }
}
