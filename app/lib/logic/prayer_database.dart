import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/bible_database.dart';

class PrayerDatabase {
  static List<Prayer>? mockPrayers;
  static UserSettings? mockSettings;

  // Fetch all prayers from the database
  static Future<List<Prayer>> loadPrayers() async {
    if (mockPrayers != null) {
      return mockPrayers!;
    }

    final db = BibleDatabaseHelper.db;
    final list = await db.getAllPrayers();
    final compiledPrayers = await _loadPrayersFromWebJson();

    bool needsUpdate = list.length != compiledPrayers.length;
    if (!needsUpdate) {
      for (final p in list) {
        final cp = compiledPrayers.firstWhere(
          (element) => element.prayerId == p.prayerId,
          orElse: () => p,
        );
        if (p.hash != cp.hash) {
          needsUpdate = true;
          break;
        }
      }
    }

    if (needsUpdate) {
      int autoId = 1;
      for (final prayer in compiledPrayers) {
        prayer.isarId = autoId++;
      }
      await db.updatePrayers(compiledPrayers);
      compiledPrayers.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
      return compiledPrayers;
    }

    return list;
  }

  static Future<UserSettings> loadSettings() async {
    if (mockSettings != null) {
      return mockSettings!;
    }
    if (mockPrayers != null) {
      return UserSettings();
    }
    final db = BibleDatabaseHelper.db;
    var settings = await db.getUserSettings();
    if (settings == null) {
      settings = UserSettings();
      await db.saveUserSettings(settings);
    }
    return settings;
  }

  static Future<void> saveSettings(UserSettings settings) async {
    if (mockSettings != null) {
      mockSettings = settings;
      return;
    }
    if (mockPrayers != null) return;
    final db = BibleDatabaseHelper.db;
    await db.saveUserSettings(settings);
  }

  static Future<List<Prayer>> _loadPrayersFromWebJson() async {
    final jsonStr = await rootBundle.loadString('assets/prayers.json');
    final List<dynamic> list = jsonDecode(jsonStr);

    final List<Prayer> prayers = [];

    for (final item in list) {
      final pMap = item as Map<String, dynamic>;
      final prayerId = pMap['id'] as String;
      final defaultTitle = pMap['default_title'] as String;
      final category = pMap['category'] as String;
      final defaultOrder = pMap['default_order'] as int;

      final List<LocalizedTranslations> localizedTranslations = [];

      final transMap = pMap['translations'] as Map<String, dynamic>;
      for (final entry in transMap.entries) {
        final langStr = entry.key;
        final List<dynamic> transList = entry.value;
        final List<PrayerTranslation> translationList = [];

        for (final tItem in transList) {
          final tMap = tItem as Map<String, dynamic>;
          final title = tMap['title'] as String;
          final subtitle = tMap['subtitle'] as String? ?? '';
          final text = tMap['text'] as String;
          final sourceName = tMap['source_name'] as String? ?? '';
          final sourceUrl = tMap['source_url'] as String? ?? '';
          final historyAuthor = tMap['history_author'] as String? ?? '';
          final historyOrigin = tMap['history_origin'] as String? ?? '';
          final historyDescription =
              tMap['history_description'] as String? ?? '';

          final chineseLinesList = tMap['chinese_lines'];
          List<ChineseLine>? chineseLines;
          if (chineseLinesList != null) {
            final List<dynamic> outer = chineseLinesList;
            chineseLines = outer.map((line) {
              final List<dynamic> charList = line;
              final List<ChineseChar> chars = charList.map((c) {
                final map = c as Map<String, dynamic>;
                return ChineseChar(
                  map['char'] as String? ?? '',
                  map['pinyin'] as String? ?? '',
                  map['phraseId'] as String?,
                );
              }).toList();
              return ChineseLine(chars: chars);
            }).toList();
          }

          final tokensList = tMap['tokens'];
          List<PrayerToken>? tokens;
          if (tokensList != null) {
            final List<dynamic> parsedList = tokensList;
            tokens = parsedList.map((tok) {
              final map = tok as Map<String, dynamic>;
              return PrayerToken(
                map['text'] as String? ?? '',
                map['id'] as String?,
              );
            }).toList();
          }

          translationList.add(
            PrayerTranslation(
              title: title,
              subtitle: subtitle,
              text: text,
              sourceName: sourceName,
              sourceUrl: sourceUrl,
              historyAuthor: historyAuthor,
              historyOrigin: historyOrigin,
              historyDescription: historyDescription,
              chineseLines: chineseLines,
              tokens: tokens,
            ),
          );
        }

        localizedTranslations.add(
          LocalizedTranslations(languageCode: langStr, list: translationList),
        );
      }

      final hasAmen = pMap['has_amen'] as bool? ?? false;
      final hash = pMap['hash'] as String? ?? '';

      prayers.add(
        Prayer(
          prayerId: prayerId,
          defaultTitle: defaultTitle,
          category: category,
          defaultOrder: defaultOrder,
          hasAmen: hasAmen,
          hash: hash,
          localizedTranslations: localizedTranslations,
        ),
      );
    }

    return prayers;
  }
}
