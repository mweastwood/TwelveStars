import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';
import 'bible_metadata.dart' show catholicBookAbbrevs;
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
  BoolColumn get missalReadingsOnly =>
      boolean().withDefault(const Constant(false))();
  TextColumn get missalHiddenPrayers => text()
      .map(NullAwareTypeConverter.wrap(const StringListConverter()))
      .nullable()();
  BoolColumn get angelusReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get angelusMorningEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get angelusMiddayEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get angelusEveningEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get rosaryReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get rosaryReminderHour =>
      integer().withDefault(const Constant(20))();
  IntColumn get rosaryReminderMinute =>
      integer().withDefault(const Constant(0))();
  BoolColumn get morningPrayerReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get morningPrayerReminderHour =>
      integer().withDefault(const Constant(7))();
  IntColumn get morningPrayerReminderMinute =>
      integer().withDefault(const Constant(0))();
  BoolColumn get nightPrayerReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get nightPrayerReminderHour =>
      integer().withDefault(const Constant(21))();
  IntColumn get nightPrayerReminderMinute =>
      integer().withDefault(const Constant(30))();
  TextColumn get bibleRibbons => text()
      .map(NullAwareTypeConverter.wrap(const BibleRibbonsConverter()))
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
  int get schemaVersion => 19;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      Future<void> createTableIfNotExists(TableInfo table) async {
        final tableCheck = await customSelect(
          "SELECT count(*) AS cnt FROM sqlite_master WHERE type = 'table' AND name = '${table.actualTableName}'",
        ).getSingle();
        if ((tableCheck.data['cnt'] as num? ?? 0) == 0) {
          await m.createTable(table);
        }
      }

      Future<void> addColumnIfNotExists(
        TableInfo table,
        GeneratedColumn column,
      ) async {
        final cols = await customSelect(
          "PRAGMA table_info('${table.actualTableName}')",
        ).get();
        final colNames = cols.map((r) => r.data['name'] as String).toSet();
        if (!colNames.contains(column.$name)) {
          await m.addColumn(table, column);
        }
      }

      Future<void> createIndexIfNotExists(
        String tableName,
        String statement,
      ) async {
        final tableCheck = await customSelect(
          "SELECT count(*) AS cnt FROM sqlite_master WHERE type = 'table' AND name = '$tableName'",
        ).getSingle();
        if ((tableCheck.data['cnt'] as num? ?? 0) > 0) {
          await customStatement(statement);
        }
      }

      if (from < 2) {
        await createTableIfNotExists(favoritePassages);
        // Clear bible_verses to force re-population with the corrected UsfmParser
        await delete(bibleVerses).go();
      }
      if (from < 3) {
        await createTableIfNotExists(prayers);
        await createTableIfNotExists(userSettingsTable);
      }
      if (from < 4) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.hapticsEnabled,
        );
      }
      if (from < 5) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.appThemeModeCode,
        );
      }
      if (from < 6) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.sundayNotificationsEnabled,
        );
      }
      if (from < 7) {
        await createTableIfNotExists(userComments);
      }
      if (from < 8) {
        await createTableIfNotExists(libraryBookmarks);
      }
      if (from < 9) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.showBibleTranslationSelectors,
        );
      }
      if (from < 10) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.bibleNumberingSystemCode,
        );
      }
      if (from < 11) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.prayerCatalogVersion,
        );
      }
      if (from < 12) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.lastBibleBookNumber,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.lastBibleChapter,
        );
        await createTableIfNotExists(bookReadingPositions);
      }
      if (from < 13) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.missalReadingsOnly,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.missalHiddenPrayers,
        );
      }
      if (from < 14) {
        await createTableIfNotExists(lectionaryReadings);
      }
      if (from < 15) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.angelusReminderEnabled,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.angelusMorningEnabled,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.angelusMiddayEnabled,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.angelusEveningEnabled,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.rosaryReminderEnabled,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.rosaryReminderHour,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.rosaryReminderMinute,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.morningPrayerReminderEnabled,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.morningPrayerReminderHour,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.morningPrayerReminderMinute,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.nightPrayerReminderEnabled,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.nightPrayerReminderHour,
        );
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.nightPrayerReminderMinute,
        );
      }
      if (from < 16) {
        await addColumnIfNotExists(
          userSettingsTable,
          userSettingsTable.bibleRibbons,
        );
      }
      if (from < 17) {
        // Clear bible_verses to force clean re-population with repaired CPDV 2009 and CPDV 2025
        await delete(bibleVerses).go();
      }
      if (from < 18) {
        await createIndexIfNotExists(
          'bible_verses',
          'CREATE INDEX IF NOT EXISTS idx_bible_verses_lookup ON bible_verses(translation_code, book_number, chapter);',
        );
        await createIndexIfNotExists(
          'lectionary_readings',
          'CREATE INDEX IF NOT EXISTS idx_lectionary_key ON lectionary_readings(reading_key);',
        );
        await createIndexIfNotExists(
          'user_comments',
          'CREATE INDEX IF NOT EXISTS idx_user_comments_doc_node ON user_comments(document_id, node_id);',
        );
        await createIndexIfNotExists(
          'favorite_passages',
          'CREATE INDEX IF NOT EXISTS idx_favorite_passages_book_ch ON favorite_passages(book_number, chapter);',
        );
      }
      if (from < 19) {
        // Clear all translations' cached verses in bible_verses to force clean re-population (including repaired CPDV 2025 Psalms)
        await delete(bibleVerses).go();
      }
    },
    beforeOpen: (details) async {
      if (details.hadUpgrade) {
        scheduleMicrotask(() {
          _ensureLectionaryPopulated().catchError((e) {
            debugPrint(
              'Could not immediately seed lectionary during migration beforeOpen: $e',
            );
          });
        });
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
    if (translation == 'LXX' && bookNumber > 46) {
      debugPrint(
        'LXX translation contains only Old Testament books (1–46). Skipping book $bookNumber ($bookName).',
      );
      return Future<void>.value();
    }

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
        final firstVerse = existingCheck.first.verseText;
        if (firstVerse.contains('|strong=') ||
            (bookNumber == 21 && firstVerse == 'Blessed')) {
          debugPrint(
            'Detected corrupted verse in $bookName ($translation). Re-populating...',
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
        // Default: CPDV (2025 Edition)
        assetPath =
            'assets/bible/cpdv/usfm/$numStr-$abbrev-ENG[B]CPDV2025[pd].usfm';
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

  static List<dynamic>? _cachedLectionaryJson;

  Future<void> _ensureLectionaryPopulatedImpl() async {
    try {
      final countExp = lectionaryReadings.id.count();
      final countQuery = selectOnly(lectionaryReadings)..addColumns([countExp]);
      final existingCount =
          await countQuery.map((row) => row.read(countExp)).getSingle() ?? 0;

      final List<dynamic> decoded;
      if (_cachedLectionaryJson != null) {
        decoded = _cachedLectionaryJson!;
      } else {
        final jsonContent = await rootBundle.loadString(
          'assets/bible/lectionary.json',
        );
        decoded = jsonDecode(jsonContent) as List<dynamic>;
        _cachedLectionaryJson = decoded;
      }

      if (existingCount >= decoded.length) {
        return; // Already populated with current dataset
      }

      if (existingCount > 0) {
        await delete(lectionaryReadings).go();
      }

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
  Future<List<UserComment>> getComments({
    String? documentId,
    String? nodeId,
    int? sectionIndex,
  }) {
    final query = select(userComments);
    final conditions = <Expression<bool>>[];

    if (documentId != null) {
      conditions.add(userComments.documentId.equals(documentId));
    }
    if (nodeId != null) {
      conditions.add(userComments.nodeId.equals(nodeId));
    }
    if (sectionIndex != null) {
      conditions.add(userComments.sectionIndex.equals(sectionIndex));
    }

    if (conditions.isNotEmpty) {
      query.where((t) => conditions.reduce((a, b) => a & b));
    }

    return query.get();
  }

  /// Queries only comments associated with canonical Catholic Bible books
  /// directly in SQL without loading non-Bible comments into memory.
  Future<List<UserComment>> getBibleComments() {
    return (select(
      userComments,
    )..where((t) => t.documentId.upper().isIn(catholicBookAbbrevs))).get();
  }

  /// Queries only comments associated with Library books (non-Bible documents)
  /// directly in SQL without loading Bible comments into memory.
  Future<List<UserComment>> getLibraryComments() {
    return (select(
      userComments,
    )..where((t) => t.documentId.upper().isNotIn(catholicBookAbbrevs))).get();
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
        missalReadingsOnly: Value(settings.missalReadingsOnly),
        missalHiddenPrayers: Value(settings.missalHiddenPrayers),
        angelusReminderEnabled: Value(settings.angelusReminderEnabled),
        angelusMorningEnabled: Value(settings.angelusMorningEnabled),
        angelusMiddayEnabled: Value(settings.angelusMiddayEnabled),
        angelusEveningEnabled: Value(settings.angelusEveningEnabled),
        rosaryReminderEnabled: Value(settings.rosaryReminderEnabled),
        rosaryReminderHour: Value(settings.rosaryReminderHour),
        rosaryReminderMinute: Value(settings.rosaryReminderMinute),
        morningPrayerReminderEnabled: Value(
          settings.morningPrayerReminderEnabled,
        ),
        morningPrayerReminderHour: Value(settings.morningPrayerReminderHour),
        morningPrayerReminderMinute: Value(
          settings.morningPrayerReminderMinute,
        ),
        nightPrayerReminderEnabled: Value(settings.nightPrayerReminderEnabled),
        nightPrayerReminderHour: Value(settings.nightPrayerReminderHour),
        nightPrayerReminderMinute: Value(settings.nightPrayerReminderMinute),
        bibleRibbons: Value(settings.bibleRibbons),
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

  Future<BookReadingPosition?> getLatestBookReadingPosition() {
    return (select(bookReadingPositions)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ])
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
  static final RegExp _footnoteRegex = RegExp(r'\\f\s+.*?\\f\*');
  static final RegExp _crossRefRegex = RegExp(r'\\x\s+.*?\\x\*');
  static final RegExp _qsRegex = RegExp(r'\\qs\s*.*?\s*\\qs\*');
  static final RegExp _tagRegex = RegExp(r'\\[a-zA-Z0-9]+(?:\*|\s)?');
  static final RegExp _attributeRegex = RegExp(
    r'\|[a-zA-Z0-9_]+="[^"]*"(?:\s+[a-zA-Z0-9_]+="[^"]*")*',
  );
  static final RegExp _multiSpaceRegex = RegExp(r'\s+');
  static final RegExp _chapterRegex = RegExp(r'^\\c\s+(\d+)');
  static final RegExp _verseRegex = RegExp(r'\\v\s+(\d+)\s*');
  static final RegExp _ignoredLineTagRegex = RegExp(
    r'^\\(?:id|h|toc\d*|mt\d*|cl|ca|qa|s\d*|sd\d*|cd|rem|ip)\b',
  );

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
        text = text.replaceAll(_footnoteRegex, '');
        text = text.replaceAll(_crossRefRegex, '');
        text = text.replaceAll(_qsRegex, '');
        text = text.replaceAll(_tagRegex, '');
        text = text.replaceAll(_attributeRegex, '');
        text = text.trim();
        // Remove multiple consecutive spaces
        text = text.replaceAll(_multiSpaceRegex, ' ');

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

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final chapterMatch = _chapterRegex.firstMatch(line);
      if (chapterMatch != null) {
        saveCurrentVerse();
        currentChapter = int.parse(chapterMatch.group(1)!);
        currentVerseNumber = 0;
        currentVerseText = '';
        continue;
      }

      final verseMatches = _verseRegex.allMatches(line).toList();
      if (verseMatches.isNotEmpty) {
        for (int i = 0; i < verseMatches.length; i++) {
          final m = verseMatches[i];
          final textEnd = (i + 1 < verseMatches.length)
              ? verseMatches[i + 1].start
              : line.length;
          final chunk = line.substring(m.end, textEnd);

          if (i == 0) {
            final prefix = line.substring(0, m.start).trim();
            if (prefix.isNotEmpty &&
                currentChapter > 0 &&
                currentVerseNumber > 0) {
              currentVerseText += ' $prefix';
            }
          }

          saveCurrentVerse();
          currentVerseNumber = int.parse(m.group(1)!);
          currentVerseText = chunk;
        }
        continue;
      }

      if (currentChapter > 0 && currentVerseNumber > 0) {
        if (_ignoredLineTagRegex.hasMatch(line)) {
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
  static set db(BibleDatabase? database) {
    _db = database;
  }
}
