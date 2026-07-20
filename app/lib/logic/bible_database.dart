import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';
import 'prayers.dart';

part 'bible_database.g.dart';

class LocalizedTranslationsConverter
    extends TypeConverter<List<LocalizedTranslations>, String> {
  const LocalizedTranslationsConverter();

  @override
  List<LocalizedTranslations> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(fromDb);
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final langStr = map['languageCode'] as String? ?? 'english';
        final List<dynamic>? transList = map['list'];
        final List<PrayerTranslation>? translationList = transList?.map((
          tItem,
        ) {
          final tMap = tItem as Map<String, dynamic>;

          final chineseLinesList = tMap['chineseLines'];
          List<ChineseLine>? chineseLines;
          if (chineseLinesList != null) {
            final List<dynamic> outer = chineseLinesList;
            chineseLines = outer.map((line) {
              final List<dynamic>? charList = line['chars'];
              final List<ChineseChar> chars =
                  charList?.map((c) {
                    final map = c as Map<String, dynamic>;
                    return ChineseChar(
                      map['char'] as String? ?? '',
                      map['pinyin'] as String? ?? '',
                      map['phraseId'] as String?,
                    );
                  }).toList() ??
                  [];
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

          return PrayerTranslation(
            title: tMap['title'] as String? ?? '',
            subtitle: tMap['subtitle'] as String? ?? '',
            text: tMap['text'] as String? ?? '',
            sourceName: tMap['sourceName'] as String? ?? '',
            sourceUrl: tMap['sourceUrl'] as String? ?? '',
            historyAuthor: tMap['historyAuthor'] as String? ?? '',
            historyOrigin: tMap['historyOrigin'] as String? ?? '',
            historyDescription: tMap['historyDescription'] as String? ?? '',
            copyright: tMap['copyright'] as String? ?? '',
            chineseLines: chineseLines,
            tokens: tokens,
          );
        }).toList();

        return LocalizedTranslations(
          languageCode: langStr,
          list: translationList,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<LocalizedTranslations> value) {
    try {
      final List<Map<String, dynamic>> list = value.map((item) {
        return {
          'languageCode': item.languageCode,
          'list': item.list?.map((trans) {
            return {
              'title': trans.title,
              'subtitle': trans.subtitle,
              'text': trans.text,
              'sourceName': trans.sourceName,
              'sourceUrl': trans.sourceUrl,
              'historyAuthor': trans.historyAuthor,
              'historyOrigin': trans.historyOrigin,
              'historyDescription': trans.historyDescription,
              'copyright': trans.copyright,
              'chineseLines': trans.chineseLines?.map((line) {
                return {
                  'chars': line.chars?.map((c) {
                    return {
                      'char': c.char,
                      'pinyin': c.pinyin,
                      'phraseId': c.phraseId,
                    };
                  }).toList(),
                };
              }).toList(),
              'tokens': trans.tokens?.map((tok) {
                return {'text': tok.text, 'id': tok.id};
              }).toList(),
            };
          }).toList(),
        };
      }).toList();
      return jsonEncode(list);
    } catch (_) {
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
      final List<dynamic> list = jsonDecode(fromDb);
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return PrayerVersionPreference(
          map['key'] as String? ?? '',
          map['versionIndex'] as int? ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<PrayerVersionPreference> value) {
    try {
      final List<Map<String, dynamic>> list = value.map((item) {
        return {'key': item.key, 'versionIndex': item.versionIndex};
      }).toList();
      return jsonEncode(list);
    } catch (_) {
      return '';
    }
  }
}

@UseRowClass(Prayer)
class Prayers extends Table {
  IntColumn get isarId => integer().autoIncrement()();
  TextColumn get prayerId => text().unique()();
  TextColumn get defaultTitle => text()();
  TextColumn get category => text()();
  IntColumn get defaultOrder => integer()();
  BoolColumn get hasAmen => boolean()();
  TextColumn get hash => text()();
  TextColumn get localizedTranslations => text()
      .map(NullAwareTypeConverter.wrap(const LocalizedTranslationsConverter()))
      .nullable()();
}

@UseRowClass(UserSettings)
class UserSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get primaryLanguageCode => text()();
  TextColumn get compareLanguageCode => text()();
  TextColumn get primaryBibleTranslation => text()();
  TextColumn get compareBibleTranslation => text()();
  TextColumn get preferredVersions => text()
      .map(NullAwareTypeConverter.wrap(const PreferredVersionsConverter()))
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'user_settings';
}

@DriftDatabase(tables: [Prayers, UserSettingsTable], include: {'bible.drift'})
class BibleDatabase extends _$BibleDatabase {
  BibleDatabase([QueryExecutor? executor])
    : super(executor ?? openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(favoritePassages);
        // Clear bible_verses to force re-population with the corrected UsfmParser
        await delete(bibleVerses).go();
      }
      if (from < 3) {
        await m.createTable(prayers);
        await m.createTable(userSettingsTable);
      }
    },
  );

  // Retrieve verses for a specific chapter
  Future<List<BibleVerse>> getChapterVerses(
    String translation,
    int bookNum,
    int chapterNum,
  ) {
    return (select(bibleVerses)
          ..where(
            (t) =>
                t.translationCode.equals(translation) &
                t.bookNumber.equals(bookNum) &
                t.chapter.equals(chapterNum),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.verseNumber)]))
        .get();
  }

  // Populate a specific book if not already populated
  Future<void> ensureBookPopulated(
    int bookNumber,
    String bookName,
    String abbrev, {
    String translation = 'CPDV',
  }) async {
    final existingCheck =
        await (select(bibleVerses)
              ..where(
                (t) =>
                    t.bookNumber.equals(bookNumber) &
                    t.translationCode.equals(translation),
              )
              ..limit(1))
            .get();
    if (existingCheck.isNotEmpty) {
      if (existingCheck.first.verseText.contains('|strong=')) {
        debugPrint(
          'Detected strong tags in populated $bookName ($translation). Re-populating...',
        );
        await (delete(bibleVerses)..where(
              (t) =>
                  t.bookNumber.equals(bookNumber) &
                  t.translationCode.equals(translation),
            ))
            .go();
      } else {
        return; // Already populated and clean
      }
    }

    try {
      final numStr = bookNumber.toString().padLeft(2, '0');
      final String assetPath;
      if (translation == 'DRC') {
        assetPath =
            'assets/bible/drc/usfm/$numStr-$abbrev-ENG[B]DRC1899[pd].usfm';
      } else if (translation == 'JUN') {
        assetPath =
            'assets/bible/jun/usfm/$numStr-$abbrev-SPA[B]JUN1928[pd].usfm';
      } else if (translation == 'TAM') {
        assetPath =
            'assets/bible/tam/usfm/$numStr-$abbrev-SPA[B]TAM1836[pd].usfm';
      } else {
        assetPath =
            'assets/bible/cpdv/usfm/$numStr-$abbrev-ENG[B]CPDV2009[pd].p.sfm';
      }

      final usfmContent = await rootBundle.loadString(assetPath);
      final parsedVerses = UsfmParser.parse(
        usfmContent,
        translation,
        bookNumber,
        bookName,
      );

      await batch((batch) {
        batch.insertAll(
          bibleVerses,
          parsedVerses.map(
            (v) => BibleVersesCompanion.insert(
              bookNumber: v['bookNumber'] as int,
              bookName: v['bookName'] as String,
              chapter: v['chapter'] as int,
              verseNumber: v['verseNumber'] as int,
              verseText: v['verseText'] as String,
              translationCode: v['translationCode'] as String,
            ),
          ),
        );
      });
      debugPrint(
        'Successfully populated Bible database ($translation) with $bookName',
      );
    } catch (e) {
      debugPrint(
        'Error populating book $bookName ($bookNumber) for $translation: $e',
      );
    }
  }

  // Populate translation if empty (default to Genesis for compatibility)
  Future<void> ensurePopulated() async {
    await ensureBookPopulated(1, 'Genesis', 'GEN');
    await _ensureLectionaryPopulated();
  }

  // Retrieve readings for a specific liturgical day key
  Future<List<LectionaryReading>> getReadings(String key) async {
    await _ensureLectionaryPopulated();
    return (select(lectionaryReadings)
          ..where((t) => t.readingKey.equals(key))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
  }

  // Populate lectionary if empty
  Future<void> _ensureLectionaryPopulated() async {
    final countCheck = await (select(lectionaryReadings)..limit(1)).get();
    if (countCheck.isNotEmpty) {
      return; // Already populated
    }

    try {
      final jsonContent = await rootBundle.loadString(
        'assets/bible/lectionary.json',
      );
      final List<dynamic> decoded = jsonDecode(jsonContent);

      await batch((batch) {
        batch.insertAll(
          lectionaryReadings,
          decoded.map(
            (item) => LectionaryReadingsCompanion.insert(
              readingKey: item['reading_key'] as String,
              readingType: item['reading_type'] as String,
              bookNumber: item['book_number'] as int,
              bookName: item['book_name'] as String,
              chapter: item['chapter'] as int,
              verseRange: item['verse_range'] as String,
              citation: item['citation'] as String,
            ),
          ),
        );
      });
      debugPrint(
        'Successfully seeded lectionary database with ${decoded.length} entries',
      );
    } catch (e) {
      debugPrint('Error seeding lectionary database: $e');
    }
  }

  // Favorites operations
  Future<List<FavoritePassage>> getFavorites() {
    return select(favoritePassages).get();
  }

  Future<int> saveFavorite(FavoritePassagesCompanion companion) {
    return into(favoritePassages).insert(companion);
  }

  Future<int> deleteFavorite(int id) {
    return (delete(favoritePassages)..where((t) => t.id.equals(id))).go();
  }

  // Prayers operations
  Future<List<Prayer>> getAllPrayers() {
    return (select(
      prayers,
    )..orderBy([(t) => OrderingTerm(expression: t.defaultOrder)])).get();
  }

  Future<void> updatePrayers(List<Prayer> newPrayers) async {
    await transaction(() async {
      await delete(prayers).go();
      for (final prayer in newPrayers) {
        await into(prayers).insert(
          PrayersCompanion(
            isarId: Value(prayer.isarId),
            prayerId: Value(prayer.prayerId),
            defaultTitle: Value(prayer.defaultTitle),
            category: Value(prayer.category),
            defaultOrder: Value(prayer.defaultOrder),
            hasAmen: Value(prayer.hasAmen),
            hash: Value(prayer.hash),
            localizedTranslations: Value(prayer.localizedTranslations),
          ),
        );
      }
    });
  }

  // User Settings operations
  Future<UserSettings?> getUserSettings() {
    return (select(userSettingsTable)..limit(1)).getSingleOrNull();
  }

  Future<void> saveUserSettings(UserSettings settings) {
    return into(userSettingsTable).insertOnConflictUpdate(
      UserSettingsTableCompanion(
        id: Value(settings.id),
        primaryLanguageCode: Value(settings.primaryLanguageCode),
        compareLanguageCode: Value(settings.compareLanguageCode),
        primaryBibleTranslation: Value(settings.primaryBibleTranslation),
        compareBibleTranslation: Value(settings.compareBibleTranslation),
        preferredVersions: Value(settings.preferredVersions),
      ),
    );
  }
}

// Simple USFM Parser
class UsfmParser {
  static List<Map<String, dynamic>> parse(
    String usfmContent,
    String translationCode,
    int bookNumber,
    String bookName,
  ) {
    final List<Map<String, dynamic>> verses = [];
    final lines = usfmContent.split('\n');

    int currentChapter = 0;
    int currentVerseNumber = 0;
    String currentVerseText = '';

    void saveCurrentVerse() {
      if (currentChapter > 0 && currentVerseNumber > 0) {
        var text = currentVerseText;
        // Strip inline footnotes and formatting
        text = text.replaceAll(RegExp(r'\\f\s+.*\\f\*'), '');
        text = text.replaceAll(RegExp(r'\\[a-zA-Z0-9]+(?:\*|\s)?'), '');
        text = text.replaceAll(
          RegExp(r'\|[a-zA-Z0-9_]+="[^"]*"(?:\s+[a-zA-Z0-9_]+="[^"]*")*'),
          '',
        );
        text = text.trim();
        // Remove multiple consecutive spaces
        text = text.replaceAll(RegExp(r'\s+'), ' ');

        verses.add({
          'bookNumber': bookNumber,
          'bookName': bookName,
          'chapter': currentChapter,
          'verseNumber': currentVerseNumber,
          'verseText': text,
          'translationCode': translationCode,
        });
      }
    }

    final chapterRegex = RegExp(r'^\\c\s+(\d+)');
    final verseRegex = RegExp(r'\\v\s+(\d+)\s*(.*)');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final chapterMatch = chapterRegex.firstMatch(line);
      if (chapterMatch != null) {
        saveCurrentVerse();
        currentChapter = int.parse(chapterMatch.group(1)!);
        currentVerseNumber = 0;
        currentVerseText = '';
        continue;
      }

      final verseMatch = verseRegex.firstMatch(line);
      if (verseMatch != null) {
        saveCurrentVerse();
        currentVerseNumber = int.parse(verseMatch.group(1)!);
        currentVerseText = verseMatch.group(2)!;
        continue;
      }

      if (currentChapter > 0 && currentVerseNumber > 0) {
        if (line.startsWith(r'\id') ||
            line.startsWith(r'\h') ||
            line.startsWith(r'\toc') ||
            line.startsWith(r'\mt') ||
            line.startsWith(r'\cl') ||
            line.startsWith(r'\ca')) {
          continue;
        }
        currentVerseText += ' $line';
      }
    }

    saveCurrentVerse();
    return verses;
  }
}

class BibleDatabaseHelper {
  static BibleDatabase? _db;

  static BibleDatabase get db {
    _db ??= BibleDatabase();
    return _db!;
  }

  @visibleForTesting
  static set db(BibleDatabase database) {
    _db = database;
  }
}
