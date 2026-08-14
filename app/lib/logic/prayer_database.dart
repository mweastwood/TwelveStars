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
    return loadPrayersFromJson(jsonStr);
  }

  static List<Prayer> loadPrayersFromJson(String jsonStr) {
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

    final List<Prayer> prayers = [];

    for (final item in decoded) {
      if (item is! Map) continue;
      final pMap = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item);

      final prayerId = pMap['id'] as String? ?? '';
      if (prayerId.isEmpty) continue;

      final defaultTitle = pMap['default_title'] as String? ?? '';
      final category = pMap['category'] as String? ?? '';
      final defaultOrder = pMap['default_order'] as int? ?? 0;

      final List<LocalizedTranslations> localizedTranslations = [];

      final rawTrans = pMap['translations'];
      if (rawTrans is Map) {
        final transMap = rawTrans is Map<String, dynamic>
            ? rawTrans
            : Map<String, dynamic>.from(rawTrans);

        for (final entry in transMap.entries) {
          final langStr = entry.key.toString();
          final rawTransList = entry.value;
          if (rawTransList is! List) continue;

          final List<PrayerTranslation> translationList = [];

          for (final tItem in rawTransList) {
            if (tItem is! Map) continue;
            final tMap = tItem is Map<String, dynamic>
                ? tItem
                : Map<String, dynamic>.from(tItem);

            final title = tMap['title'] as String? ?? '';
            final subtitle = tMap['subtitle'] as String? ?? '';
            final text = tMap['text'] as String? ?? '';
            final sourceName = tMap['source_name'] as String? ?? '';
            final sourceUrl = tMap['source_url'] as String? ?? '';
            final copyright = tMap['copyright'] as String? ?? '';
            final historyAuthor = tMap['history_author'] as String? ?? '';
            final historyOrigin = tMap['history_origin'] as String? ?? '';
            final historyDescription =
                tMap['history_description'] as String? ?? '';

            final rawChineseLines = tMap['chinese_lines'];
            List<ChineseLine>? chineseLines;
            if (rawChineseLines is List) {
              chineseLines = [];
              for (final line in rawChineseLines) {
                if (line is List) {
                  final List<ChineseChar> chars = [];
                  for (final c in line) {
                    if (c is Map) {
                      final cMap = c is Map<String, dynamic>
                          ? c
                          : Map<String, dynamic>.from(c);
                      chars.add(
                        ChineseChar(
                          cMap['char'] as String? ?? '',
                          cMap['pinyin'] as String? ?? '',
                          cMap['phraseId'] as String?,
                        ),
                      );
                    }
                  }
                  chineseLines.add(ChineseLine(chars: chars));
                } else if (line is Map) {
                  final rawChars = line['chars'];
                  if (rawChars is List) {
                    final List<ChineseChar> chars = [];
                    for (final c in rawChars) {
                      if (c is Map) {
                        final cMap = c is Map<String, dynamic>
                            ? c
                            : Map<String, dynamic>.from(c);
                        chars.add(
                          ChineseChar(
                            cMap['char'] as String? ?? '',
                            cMap['pinyin'] as String? ?? '',
                            cMap['phraseId'] as String?,
                          ),
                        );
                      }
                    }
                    chineseLines.add(ChineseLine(chars: chars));
                  }
                }
              }
            }

            final rawTokens = tMap['tokens'];
            List<PrayerToken>? tokens;
            if (rawTokens is List) {
              tokens = [];
              for (final tok in rawTokens) {
                if (tok is Map) {
                  final tokMap = tok is Map<String, dynamic>
                      ? tok
                      : Map<String, dynamic>.from(tok);
                  tokens.add(
                    PrayerToken(
                      tokMap['text'] as String? ?? '',
                      tokMap['id'] as String?,
                    ),
                  );
                }
              }
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
                copyright: copyright,
                chineseLines: chineseLines,
                tokens: tokens,
              ),
            );
          }

          localizedTranslations.add(
            LocalizedTranslations(languageCode: langStr, list: translationList),
          );
        }
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
