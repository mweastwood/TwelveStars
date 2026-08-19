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
      final dynamic decoded = jsonDecode(fromDb);
      if (decoded is! List) return [];
      final List<LocalizedTranslations> results = [];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        final langStr = map['languageCode'] as String? ?? 'english';
        final rawTransList = map['list'];
        List<PrayerTranslation>? translationList;
        if (rawTransList is List) {
          translationList = [];
          for (final tItem in rawTransList) {
            if (tItem is! Map) continue;
            final tMap = tItem is Map<String, dynamic>
                ? tItem
                : Map<String, dynamic>.from(tItem);

            final chineseLinesList = tMap['chineseLines'];
            List<ChineseLine>? chineseLines;
            if (chineseLinesList is List) {
              chineseLines = [];
              for (final line in chineseLinesList) {
                if (line is Map) {
                  final lineMap = line is Map<String, dynamic>
                      ? line
                      : Map<String, dynamic>.from(line);
                  final charList = lineMap['chars'];
                  final List<ChineseChar> chars = [];
                  if (charList is List) {
                    for (final c in charList) {
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
                  }
                  chineseLines.add(ChineseLine(chars: chars));
                }
              }
            }

            final tokensList = tMap['tokens'];
            List<PrayerToken>? tokens;
            if (tokensList is List) {
              tokens = [];
              for (final tok in tokensList) {
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
              ),
            );
          }
        }

        results.add(
          LocalizedTranslations(languageCode: langStr, list: translationList),
        );
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
        results.add(
          PrayerVersionPreference(
            map['key'] as String? ?? '',
            map['versionIndex'] as int? ?? 0,
          ),
        );
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
      final List<Map<String, dynamic>> list = value.map((item) {
        return {'key': item.key, 'versionIndex': item.versionIndex};
      }).toList();
      return jsonEncode(list);
    } catch (e, stack) {
      debugPrint('PreferredVersionsConverter.toSql error: $e\n$stack');
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
  BoolColumn get hapticsEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get appThemeModeCode =>
      text().withDefault(const Constant('marian_blue'))();
  BoolColumn get sundayNotificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showBibleTranslationSelectors =>
      boolean().withDefault(const Constant(false))();
  TextColumn get bibleNumberingSystemCode =>
      text().withDefault(const Constant('vulgate'))();
  IntColumn get prayerCatalogVersion =>
      integer().withDefault(const Constant(0))();
  IntColumn get lastBibleBookNumber =>
      integer().withDefault(const Constant(1))();
  IntColumn get lastBibleChapter => integer().withDefault(const Constant(1))();

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
  int get schemaVersion => 12;

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
      if (from < 4) {
        await m.addColumn(userSettingsTable, userSettingsTable.hapticsEnabled);
      }
      if (from < 5) {
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.appThemeModeCode,
        );
      }
      if (from < 6) {
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.sundayNotificationsEnabled,
        );
      }
      if (from < 7) {
        await m.createTable(userComments);
      }
      if (from < 8) {
        await m.createTable(libraryBookmarks);
      }
      if (from < 9) {
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.showBibleTranslationSelectors,
        );
      }
      if (from < 10) {
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.bibleNumberingSystemCode,
        );
      }
      if (from < 11) {
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.prayerCatalogVersion,
        );
      }
      if (from < 12) {
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.lastBibleBookNumber,
        );
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.lastBibleChapter,
        );
        await m.createTable(bookReadingPositions);
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

  final Map<String, Future<void>> _inFlightBookPopulations = {};

  @visibleForTesting
  Map<String, Future<void>> get inFlightBookPopulations =>
      _inFlightBookPopulations;

  // Populate a specific book if not already populated
  Future<void> ensureBookPopulated(
    int bookNumber,
    String bookName,
    String abbrev, {
    String translation = 'CPDV',
  }) {
    final key = '$translation:$bookNumber';
    final inFlight = _inFlightBookPopulations[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _ensureBookPopulatedImpl(
      bookNumber,
      bookName,
      abbrev,
      key: key,
      translation: translation,
    );
    _inFlightBookPopulations[key] = future;
    return future;
  }

  Future<void> _ensureBookPopulatedImpl(
    int bookNumber,
    String bookName,
    String abbrev, {
    required String key,
    String translation = 'CPDV',
  }) async {
    try {
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
      } else if (translation == 'VUL') {
        assetPath =
            'assets/bible/vul/usfm/$numStr-$abbrev-LAT[B]VUL1592[pd].usfm';
      } else if (translation == 'LXX') {
        assetPath = 'assets/bible/lxx/usfm/$numStr-$abbrev-GRC[B]LXX[pd].usfm';
      } else if (translation == 'ORIG') {
        assetPath = 'assets/bible/orig/usfm/$numStr-$abbrev-ORIG[pd].usfm';
      } else {
        assetPath =
            'assets/bible/cpdv/usfm/$numStr-$abbrev-ENG[B]CPDV2009[pd].p.sfm';
      }

      final usfmContent = await rootBundle.loadString(assetPath);
      final parsedVerses = await compute(
        UsfmParser.parseInBackground,
        UsfmParseParams(
          usfmContent: usfmContent,
          translationCode: translation,
          bookNumber: bookNumber,
          bookName: bookName,
        ),
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
      rethrow;
    } finally {
      _inFlightBookPopulations.remove(key);
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

  Future<void>? _inFlightLectionaryPopulation;

  @visibleForTesting
  Future<void>? get inFlightLectionaryPopulation =>
      _inFlightLectionaryPopulation;

  // Populate lectionary if empty
  Future<void> _ensureLectionaryPopulated() {
    if (_inFlightLectionaryPopulation != null) {
      return _inFlightLectionaryPopulation!;
    }

    final future = _ensureLectionaryPopulatedImpl();
    _inFlightLectionaryPopulation = future;
    return future;
  }

  Future<void> _ensureLectionaryPopulatedImpl() async {
    try {
      final countCheck = await (select(lectionaryReadings)..limit(1)).get();
      if (countCheck.isNotEmpty) {
        return; // Already populated
      }

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
      rethrow;
    } finally {
      _inFlightLectionaryPopulation = null;
    }
  }

  // Favorites operations
  Future<List<FavoritePassage>> getFavorites() {
    return select(favoritePassages).get();
  }

  Future<List<FavoritePassage>> getFavoritesForChapter(
    int bookNumber,
    int chapter,
  ) {
    return (select(favoritePassages)..where(
          (t) => t.bookNumber.equals(bookNumber) & t.chapter.equals(chapter),
        ))
        .get();
  }

  Future<int> saveFavorite(FavoritePassagesCompanion companion) {
    return into(favoritePassages).insert(companion);
  }

  Future<int> deleteFavorite(int id) {
    return (delete(favoritePassages)..where((t) => t.id.equals(id))).go();
  }

  // User Comments operations
  Future<List<UserComment>> getComments({String? documentId, String? nodeId}) {
    final query = select(userComments);
    if (documentId != null && nodeId != null) {
      query.where(
        (t) => t.documentId.equals(documentId) & t.nodeId.equals(nodeId),
      );
    } else if (documentId != null) {
      query.where((t) => t.documentId.equals(documentId));
    } else if (nodeId != null) {
      query.where((t) => t.nodeId.equals(nodeId));
    }
    return query.get();
  }

  Future<int> saveComment(UserCommentsCompanion companion) {
    return into(userComments).insert(companion);
  }

  Future<int> updateComment(int id, String newText) {
    return (update(userComments)..where((t) => t.id.equals(id))).write(
      UserCommentsCompanion(commentText: Value(newText)),
    );
  }

  Future<int> deleteComment(int id) {
    return (delete(userComments)..where((t) => t.id.equals(id))).go();
  }

  // Library Bookmarks operations
  Future<List<LibraryBookmark>> getLibraryBookmarks({String? documentId}) {
    final query = select(libraryBookmarks);
    if (documentId != null) {
      query.where((t) => t.documentId.equals(documentId));
    }
    return query.get();
  }

  Future<int> saveLibraryBookmark(LibraryBookmarksCompanion companion) {
    return into(libraryBookmarks).insert(companion);
  }

  Future<int> deleteLibraryBookmark(int id) {
    return (delete(libraryBookmarks)..where((t) => t.id.equals(id))).go();
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
        hapticsEnabled: Value(settings.hapticsEnabled),
        appThemeModeCode: Value(settings.appThemeModeCode),
        sundayNotificationsEnabled: Value(settings.sundayNotificationsEnabled),
        showBibleTranslationSelectors: Value(
          settings.showBibleTranslationSelectors,
        ),
        bibleNumberingSystemCode: Value(settings.bibleNumberingSystemCode),
        prayerCatalogVersion: Value(settings.prayerCatalogVersion),
        lastBibleBookNumber: Value(settings.lastBibleBookNumber),
        lastBibleChapter: Value(settings.lastBibleChapter),
      ),
    );
  }

  // Book Reading Position operations
  Future<BookReadingPosition?> getBookReadingPosition(String bookId) {
    return (select(bookReadingPositions)
          ..where((t) => t.bookId.equals(bookId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> saveBookReadingPosition({
    required String bookId,
    String? volumeKey,
    required int sectionIndex,
    String? sectionId,
  }) {
    return into(bookReadingPositions).insertOnConflictUpdate(
      BookReadingPositionsCompanion(
        bookId: Value(bookId),
        volumeKey: Value(volumeKey),
        sectionIndex: Value(sectionIndex),
        sectionId: Value(sectionId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

class UsfmParseParams {
  final String usfmContent;
  final String translationCode;
  final int bookNumber;
  final String bookName;

  const UsfmParseParams({
    required this.usfmContent,
    required this.translationCode,
    required this.bookNumber,
    required this.bookName,
  });
}

// Simple USFM Parser
class UsfmParser {
  static List<Map<String, dynamic>> parseInBackground(UsfmParseParams params) {
    return parse(
      params.usfmContent,
      params.translationCode,
      params.bookNumber,
      params.bookName,
    );
  }

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
        text = text.replaceAll(RegExp(r'\\f\s+.*?\\f\*'), '');
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
