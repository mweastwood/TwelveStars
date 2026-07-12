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
      // Verify that the retrieved instance is healthy and not in a corrupted/tableless state
      existing.prayers.getAll([0]);
      return existing;
    } catch (_) {
      // Instance has not been opened yet, or it is in a corrupted state.
      // Try closing the existing instance first to release locks before we reopen/delete
      try {
        final existing = Isar.get(schemas: [PrayerSchema, UserSettingsSchema]);
        existing.close();
      } catch (_) {}
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
        name: kIsWeb
            ? 'default_${DateTime.now().millisecondsSinceEpoch}'
            : Isar.defaultName,
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      final isAlreadyOpenError =
          errorStr.contains('already opened') ||
          errorStr.contains('already open');
      if (!kIsWeb && directory != null && !isAlreadyOpenError) {
        try {
          final isarDir = Directory(directory);
          if (isarDir.existsSync()) {
            for (final entity in isarDir.listSync()) {
              if (entity is File &&
                  (entity.path.endsWith('.isar') ||
                      entity.path.endsWith('.sqlite') ||
                      entity.path.contains('isar') ||
                      entity.path.contains('sqlite'))) {
                try {
                  entity.deleteSync();
                } catch (_) {}
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

  static bool _arePrayersIdentical(Prayer a, Prayer b) {
    if (a.prayerId != b.prayerId) return false;
    if (a.defaultTitle != b.defaultTitle) return false;
    if (a.category != b.category) return false;
    if (a.defaultOrder != b.defaultOrder) return false;
    if (a.hasAmen != b.hasAmen) return false;

    final aTrans = a.localizedTranslations ?? [];
    final bTrans = b.localizedTranslations ?? [];
    if (aTrans.length != bTrans.length) return false;

    for (final at in aTrans) {
      final bt = bTrans.firstWhere(
        (element) => element.languageCode == at.languageCode,
        orElse: () => LocalizedTranslations(languageCode: ''),
      );
      if (bt.languageCode.isEmpty) return false;

      final atList = at.list ?? [];
      final btList = bt.list ?? [];
      if (atList.length != btList.length) return false;

      for (int i = 0; i < atList.length; i++) {
        final atItem = atList[i];
        final btItem = btList[i];

        if (atItem.title != btItem.title) return false;
        if (atItem.subtitle != btItem.subtitle) return false;
        if (atItem.text != btItem.text) return false;
        if (atItem.sourceName != btItem.sourceName) return false;
        if (atItem.sourceUrl != btItem.sourceUrl) return false;
        if (atItem.historyAuthor != btItem.historyAuthor) return false;
        if (atItem.historyOrigin != btItem.historyOrigin) return false;
        if (atItem.historyDescription != btItem.historyDescription) {
          return false;
        }

        // Compare tokens
        final atTokens = atItem.tokens ?? [];
        final btTokens = btItem.tokens ?? [];
        if (atTokens.length != btTokens.length) return false;
        for (int j = 0; j < atTokens.length; j++) {
          if (atTokens[j].text != btTokens[j].text ||
              atTokens[j].id != btTokens[j].id) {
            return false;
          }
        }

        // Compare Chinese lines
        final atChinese = atItem.chineseLines ?? [];
        final btChinese = btItem.chineseLines ?? [];
        if (atChinese.length != btChinese.length) return false;
        for (int j = 0; j < atChinese.length; j++) {
          final atChars = atChinese[j].chars ?? [];
          final btChars = btChinese[j].chars ?? [];
          if (atChars.length != btChars.length) return false;
          for (int k = 0; k < atChars.length; k++) {
            if (atChars[k].char != btChars[k].char ||
                atChars[k].pinyin != btChars[k].pinyin ||
                atChars[k].phraseId != btChars[k].phraseId) {
              return false;
            }
          }
        }
      }
    }

    return true;
  }

  // Fetch all prayers from the database
  static Future<List<Prayer>> loadPrayers() async {
    if (mockPrayers != null) {
      return mockPrayers!;
    }

    final isarInstance = await isar;
    final list = isarInstance.prayers.where().sortByDefaultOrder().findAll();
    final compiledPrayers = await _loadPrayersFromWebJson();

    bool needsUpdate = list.length != compiledPrayers.length;
    if (!needsUpdate) {
      for (final p in list) {
        final cp = compiledPrayers.firstWhere(
          (element) => element.prayerId == p.prayerId,
          orElse: () => p,
        );
        if (!_arePrayersIdentical(p, cp)) {
          needsUpdate = true;
          break;
        }
      }
    }

    if (needsUpdate) {
      isarInstance.write((isar) {
        isar.prayers.clear();
        for (final prayer in compiledPrayers) {
          prayer.isarId = isar.prayers.autoIncrement();
        }
        isar.prayers.putAll(compiledPrayers);
      });
      compiledPrayers.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
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

      final hasAmen = pMap['has_amen'] as bool? ?? false;

      prayers.add(
        Prayer(
          prayerId: prayerId,
          defaultTitle: defaultTitle,
          category: category,
          defaultOrder: defaultOrder,
          hasAmen: hasAmen,
          localizedTranslations: localizedTranslations,
        ),
      );
    }

    return prayers;
  }
}
