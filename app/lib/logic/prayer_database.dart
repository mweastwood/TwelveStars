import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twelve_stars/logic/prayers.dart';

import 'dart:io';

class PrayerDatabase {
  static List<Prayer>? mockPrayers;
  static Isar? _isar;

  static Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    _isar = await _initIsar();
    return _isar!;
  }

  static Future<Isar> _initIsar() async {
    try {
      final existing = Isar.get(schemas: [PrayerSchema, UserSettingsSchema]);
      existing.close();
    } catch (_) {
      // Instance has not been opened yet, proceed with normal initialization
    }
    if (kIsWeb) {
      await Isar.initialize();
    }
    String? directory;
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      directory = dir.path;
    }
    try {
      return Isar.open(
        schemas: [PrayerSchema, UserSettingsSchema],
        directory: kIsWeb ? Isar.sqliteInMemory : (directory ?? ''),
        engine: kIsWeb ? IsarEngine.sqlite : IsarEngine.isar,
      );
    } catch (e) {
      if (!kIsWeb && directory != null) {
        try {
          final isarDir = Directory(directory);
          if (await isarDir.exists()) {
            await for (final entity in isarDir.list()) {
              if (entity is File &&
                  (entity.path.endsWith('.isar') ||
                      entity.path.endsWith('.sqlite') ||
                      entity.path.contains('isar') ||
                      entity.path.contains('sqlite'))) {
                await entity.delete();
              }
            }
          }
        } catch (_) {}
        // Retry opening database
        return Isar.open(
          schemas: [PrayerSchema, UserSettingsSchema],
          directory: directory,
          engine: IsarEngine.isar,
        );
      }
      rethrow;
    }
  }

  // Fetch all prayers from the database
  static Future<List<Prayer>> loadPrayers() async {
    if (mockPrayers != null) {
      return mockPrayers!;
    }

    final isarInstance = await isar;
    final list = isarInstance.prayers.where().sortByDefaultOrder().findAll();
    final compiledPrayers = await _loadPrayersFromWebJson();

    if (list.length != compiledPrayers.length) {
      isarInstance.write((isar) {
        isar.prayers.clear();
        for (final prayer in compiledPrayers) {
          prayer.isarId = isar.prayers.autoIncrement();
        }
        isar.prayers.putAll(compiledPrayers);
      });
      return compiledPrayers;
    }

    return list;
  }

  static UserSettings? mockSettings;

  static Future<UserSettings> loadSettings() async {
    if (mockSettings != null) {
      return mockSettings!;
    }
    if (mockPrayers != null) {
      return UserSettings();
    }
    final isarInstance = await isar;
    var settings = isarInstance.userSettings.get(1);
    if (settings == null) {
      settings = UserSettings();
      isarInstance.write((isar) {
        isar.userSettings.put(settings!);
      });
    }
    return settings;
  }

  static Future<void> saveSettings(UserSettings settings) async {
    if (mockSettings != null) {
      mockSettings = settings;
      return;
    }
    if (mockPrayers != null) return;
    final isarInstance = await isar;
    isarInstance.write((isar) {
      isar.userSettings.put(settings);
    });
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

      prayers.add(
        Prayer(
          prayerId: prayerId,
          defaultTitle: defaultTitle,
          category: category,
          defaultOrder: defaultOrder,
          localizedTranslations: localizedTranslations,
        ),
      );
    }

    return prayers;
  }
}
