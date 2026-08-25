import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/prayers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
  });

  tearDown(() async {
    await testDb.close();
  });

  group('BibleDatabase Concurrent Population Tests', () {
    test('handles concurrent ensureBookPopulated calls cleanly', () async {
      final futures = Future.wait([
        testDb.ensureBookPopulated(1, 'Genesis', 'GEN', translation: 'VUL'),
        testDb.ensureBookPopulated(1, 'Genesis', 'GEN', translation: 'VUL'),
        testDb.ensureBookPopulated(1, 'Genesis', 'GEN', translation: 'VUL'),
        testDb.ensureBookPopulated(1, 'Genesis', 'GEN', translation: 'VUL'),
      ]);

      await expectLater(futures, completes);

      final verses = await testDb.getChapterVerses('VUL', 1, 1);
      expect(verses, isNotEmpty);
      expect(verses.first.translationCode, equals('VUL'));
      expect(testDb.inFlightBookPopulations, isEmpty);
    });

    test('cleans up in-flight map and propagates exception on error', () async {
      const key = 'INVALID:999';
      expect(testDb.inFlightBookPopulations.containsKey(key), isFalse);

      final future1 = testDb.ensureBookPopulated(
        999,
        'InvalidBook',
        'INV',
        translation: 'INVALID',
      );
      final future2 = testDb.ensureBookPopulated(
        999,
        'InvalidBook',
        'INV',
        translation: 'INVALID',
      );

      // Verify concurrent callers receive identical future instances
      expect(identical(future1, future2), isTrue);

      // Verify exception propagation
      await expectLater(future1, throwsA(isA<Object>()));
      await expectLater(future2, throwsA(isA<Object>()));

      // Verify in-flight map cleanup after error
      expect(testDb.inFlightBookPopulations.containsKey(key), isFalse);
      expect(testDb.inFlightBookPopulations, isEmpty);
    });

    test(
      'handles concurrent getReadings and ensurePopulated calls with in-flight deduplication',
      () async {
        expect(testDb.inFlightLectionaryPopulation, isNull);

        final future1 = testDb.getReadings('feast_all_saints');
        final inFlightFuture = testDb.inFlightLectionaryPopulation;
        expect(inFlightFuture, isNotNull);

        final future2 = testDb.getReadings('feast_all_saints');
        final future3 = testDb.ensurePopulated();

        // While in flight, the same future is referenced
        expect(testDb.inFlightLectionaryPopulation, equals(inFlightFuture));

        final results = await Future.wait([future1, future2]);
        await future3;

        expect(testDb.inFlightLectionaryPopulation, isNull);
        expect(results[0], isNotEmpty);
        expect(results[1], isNotEmpty);
        expect(results[0].length, equals(results[1].length));

        // Subsequent call should succeed and leave inFlightLectionaryPopulation as null
        final subsequent = await testDb.getReadings('feast_all_saints');
        expect(subsequent.length, equals(results[0].length));
        expect(testDb.inFlightLectionaryPopulation, isNull);
      },
    );
  });

  group('UserSettings Operations', () {
    test(
      'saveUserSettings persists all user settings fields including haptics, theme, and notifications',
      () async {
        final settings = UserSettings(
          id: 1,
          primaryLanguageCode: 'spanish',
          compareLanguageCode: 'english',
          primaryBibleTranslation: 'VUL',
          compareBibleTranslation: 'CPDV',
          preferredVersions: [
            PrayerVersionPreference('our_father_english', 1),
            PrayerVersionPreference('hail_mary_latin', 2),
          ],
          hapticsEnabled: false,
          appThemeModeCode: 'gothic_dark',
          sundayNotificationsEnabled: false,
          showBibleTranslationSelectors: true,
          bibleNumberingSystemCode: 'dual',
          prayerCatalogVersion: 1,
          lastBibleBookNumber: 19,
          lastBibleChapter: 23,
          missalReadingsOnly: true,
          missalHiddenPrayers: ['mass_greeting', 'gloria'],
          angelusReminderEnabled: true,
          angelusMorningEnabled: true,
          angelusMiddayEnabled: false,
          angelusEveningEnabled: true,
          rosaryReminderEnabled: true,
          rosaryReminderHour: 19,
          rosaryReminderMinute: 45,
          morningPrayerReminderEnabled: true,
          morningPrayerReminderHour: 6,
          morningPrayerReminderMinute: 15,
          nightPrayerReminderEnabled: true,
          nightPrayerReminderHour: 22,
          nightPrayerReminderMinute: 10,
          bibleRibbons: [
            const BibleRibbonBookmark(
              ribbonIndex: 0,
              bookNumber: 40,
              chapter: 26,
            ),
            const BibleRibbonBookmark(
              ribbonIndex: 1,
              bookNumber: 1,
              chapter: 1,
            ),
          ],
        );

        await testDb.saveUserSettings(settings);

        final retrieved = await testDb.getUserSettings();
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(1));
        expect(retrieved.primaryLanguageCode, equals('spanish'));
        expect(retrieved.compareLanguageCode, equals('english'));
        expect(retrieved.primaryBibleTranslation, equals('VUL'));
        expect(retrieved.compareBibleTranslation, equals('CPDV'));
        expect(retrieved.preferredVersions, isNotNull);
        expect(retrieved.preferredVersions!.length, equals(2));
        expect(
          retrieved.preferredVersions![0].key,
          equals('our_father_english'),
        );
        expect(retrieved.preferredVersions![0].versionIndex, equals(1));
        expect(retrieved.preferredVersions![1].key, equals('hail_mary_latin'));
        expect(retrieved.preferredVersions![1].versionIndex, equals(2));
        expect(retrieved.hapticsEnabled, isFalse);
        expect(retrieved.appThemeModeCode, equals('gothic_dark'));
        expect(retrieved.sundayNotificationsEnabled, isFalse);
        expect(retrieved.showBibleTranslationSelectors, isTrue);
        expect(retrieved.bibleNumberingSystemCode, equals('dual'));
        expect(
          retrieved.bibleNumberingSystem,
          equals(BibleNumberingSystem.dual),
        );
        expect(retrieved.prayerCatalogVersion, equals(1));
        expect(retrieved.lastBibleBookNumber, equals(19));
        expect(retrieved.lastBibleChapter, equals(23));
        expect(retrieved.missalReadingsOnly, isTrue);
        expect(
          retrieved.missalHiddenPrayers,
          equals(['mass_greeting', 'gloria']),
        );
        expect(retrieved.angelusReminderEnabled, isTrue);
        expect(retrieved.angelusMorningEnabled, isTrue);
        expect(retrieved.angelusMiddayEnabled, isFalse);
        expect(retrieved.angelusEveningEnabled, isTrue);
        expect(retrieved.rosaryReminderEnabled, isTrue);
        expect(retrieved.rosaryReminderHour, equals(19));
        expect(retrieved.rosaryReminderMinute, equals(45));
        expect(retrieved.morningPrayerReminderEnabled, isTrue);
        expect(retrieved.morningPrayerReminderHour, equals(6));
        expect(retrieved.morningPrayerReminderMinute, equals(15));
        expect(retrieved.nightPrayerReminderEnabled, isTrue);
        expect(retrieved.nightPrayerReminderHour, equals(22));
        expect(retrieved.nightPrayerReminderMinute, equals(10));
        expect(retrieved.bibleRibbons, isNotNull);
        expect(retrieved.bibleRibbons!.length, equals(2));
        expect(retrieved.bibleRibbons![0].ribbonIndex, equals(0));
        expect(retrieved.bibleRibbons![0].bookNumber, equals(40));
        expect(retrieved.bibleRibbons![0].chapter, equals(26));
        expect(retrieved.bibleRibbons![1].ribbonIndex, equals(1));
        expect(retrieved.bibleRibbons![1].bookNumber, equals(1));
        expect(retrieved.bibleRibbons![1].chapter, equals(1));
      },
    );

    test(
      'BibleRibbonBookmark serialization, deserialization, and equality',
      () {
        const bookmark = BibleRibbonBookmark(
          ribbonIndex: 2,
          bookNumber: 19,
          chapter: 23,
        );
        final json = bookmark.toJson();
        expect(json['ribbonIndex'], equals(2));
        expect(json['bookNumber'], equals(19));
        expect(json['chapter'], equals(23));

        final restored = BibleRibbonBookmark.fromJson(json);
        expect(restored, equals(bookmark));
        expect(restored.hashCode, equals(bookmark.hashCode));

        final fallback = BibleRibbonBookmark.fromJson({});
        expect(fallback.ribbonIndex, equals(0));
        expect(fallback.bookNumber, equals(1));
        expect(fallback.chapter, equals(1));
      },
    );

    test('BibleRibbonsConverter fromSql and toSql handling', () {
      const converter = BibleRibbonsConverter();
      expect(converter.fromSql(''), isEmpty);
      expect(converter.fromSql('not-json'), isEmpty);
      expect(converter.fromSql('{"not": "a list"}'), isEmpty);

      const sample = [
        BibleRibbonBookmark(ribbonIndex: 0, bookNumber: 1, chapter: 1),
        BibleRibbonBookmark(ribbonIndex: 3, bookNumber: 66, chapter: 22),
      ];
      final sql = converter.toSql(sample);
      final list = converter.fromSql(sql);
      expect(list.length, equals(2));
      expect(list[0], equals(sample[0]));
      expect(list[1], equals(sample[1]));
    });
  });

  group('Book Reading Position Operations', () {
    test('save and get book reading positions', () async {
      expect(testDb.schemaVersion, equals(16));

      await testDb.saveBookReadingPosition(
        bookId: 'baltimore_catechism',
        volumeKey: 'baltimore_3',
        sectionIndex: 5,
        sectionId: 'lesson_5',
      );

      final pos = await testDb.getBookReadingPosition('baltimore_catechism');
      expect(pos, isNotNull);
      expect(pos!.bookId, equals('baltimore_catechism'));
      expect(pos.volumeKey, equals('baltimore_3'));
      expect(pos.sectionIndex, equals(5));
      expect(pos.sectionId, equals('lesson_5'));

      // Update position
      await testDb.saveBookReadingPosition(
        bookId: 'baltimore_catechism',
        volumeKey: 'baltimore_3',
        sectionIndex: 6,
        sectionId: 'lesson_6',
      );

      final updatedPos = await testDb.getBookReadingPosition(
        'baltimore_catechism',
      );
      expect(updatedPos, isNotNull);
      expect(updatedPos!.sectionIndex, equals(6));
      expect(updatedPos.sectionId, equals('lesson_6'));
    });
  });

  group('Library Bookmarks Operations', () {
    test('save, get, and delete library bookmarks in BibleDatabase', () async {
      expect(testDb.schemaVersion, equals(16));

      final now = DateTime.now();
      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'baltimore_1',
          sectionIndex: 2,
          nodeId: 'b1-s2-3',
          textPreview: 'What is prayer?',
          createdAt: now,
        ),
      );

      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'council_of_trent',
          sectionIndex: 0,
          nodeId: 'cot-s0-1',
          textPreview: 'The Creed',
          createdAt: now,
        ),
      );

      final allBookmarks = await testDb.getLibraryBookmarks();
      expect(allBookmarks.length, equals(2));

      final baltimoreOnly = await testDb.getLibraryBookmarks(
        documentId: 'baltimore_1',
      );
      expect(baltimoreOnly.length, equals(1));
      expect(baltimoreOnly.first.documentId, equals('baltimore_1'));
      expect(baltimoreOnly.first.textPreview, equals('What is prayer?'));

      await testDb.deleteLibraryBookmark(baltimoreOnly.first.id);
      final remaining = await testDb.getLibraryBookmarks();
      expect(remaining.length, equals(1));
      expect(remaining.first.documentId, equals('council_of_trent'));
    });
  });

  group('User Comments Operations', () {
    test('save, update, get, and delete comments in BibleDatabase', () async {
      final now = DateTime.now();
      final id = await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'Initial comment',
          createdAt: now,
        ),
      );

      final comments = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_1',
      );
      expect(comments.length, equals(1));
      expect(comments.first.commentText, equals('Initial comment'));

      // Update comment text
      final rowsAffected = await testDb.updateComment(
        id,
        'Updated comment text',
      );
      expect(rowsAffected, equals(1));

      final updatedComments = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_1',
      );
      expect(updatedComments.length, equals(1));
      expect(updatedComments.first.commentText, equals('Updated comment text'));

      // Delete comment
      await testDb.deleteComment(id);
      final emptyComments = await testDb.getComments(
        documentId: 'GEN',
        nodeId: '1_1_1',
      );
      expect(emptyComments, isEmpty);
    });
  });

  group('TypeConverters Error Resilience', () {
    const locConverter = LocalizedTranslationsConverter();
    const prefConverter = PreferredVersionsConverter();

    test(
      'LocalizedTranslationsConverter handles empty and malformed JSON safely',
      () {
        expect(locConverter.fromSql(''), isEmpty);
        expect(locConverter.fromSql('not-valid-json'), isEmpty);
        expect(locConverter.fromSql('{"not": "a list"}'), isEmpty);
        expect(locConverter.fromSql('[{"invalid": "structure"}]'), isNotEmpty);
        expect(
          locConverter
              .fromSql(
                '[{"languageCode": "en", "list": [{"title": "P", "text": "T"}]}]',
              )
              .length,
          equals(1),
        );
      },
    );

    test(
      'PreferredVersionsConverter handles empty and malformed JSON safely',
      () {
        expect(prefConverter.fromSql(''), isEmpty);
        expect(prefConverter.fromSql('invalid json string'), isEmpty);
        expect(prefConverter.fromSql('{"key": "test"}'), isEmpty);
        expect(
          prefConverter.fromSql('[{"key": "test", "versionIndex": 2}]').length,
          equals(1),
        );
        expect(prefConverter.toSql([]), equals('[]'));
      },
    );

    test('StringListConverter handles empty and malformed JSON safely', () {
      const stringListConverter = StringListConverter();
      expect(stringListConverter.fromSql(''), isEmpty);
      expect(stringListConverter.fromSql('invalid json string'), isEmpty);
      expect(stringListConverter.fromSql('{"key": "test"}'), isEmpty);
      expect(
        stringListConverter.fromSql('["item1", "item2"]'),
        equals(['item1', 'item2']),
      );
      expect(
        stringListConverter.toSql(['item1', 'item2']),
        equals('["item1","item2"]'),
      );
    });
  });

  group('Database Migration Tests', () {
    test(
      'migrates from schema version 1 to 14 creating lectionary_readings and seeding data',
      () async {
        final rawDb = NativeDatabase.memory(
          setup: (db) {
            db.execute('''
              CREATE TABLE bible_verses (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_number INT NOT NULL,
                verse_text TEXT NOT NULL,
                translation_code TEXT NOT NULL
              );
              PRAGMA user_version = 1;
            ''');
          },
        );
        final migratedDb = BibleDatabase(rawDb);
        addTearDown(migratedDb.close);

        expect(migratedDb.schemaVersion, equals(16));

        final readings = await migratedDb.getReadings('feast_all_saints');
        expect(readings, isNotEmpty);
        expect(readings.first.readingKey, equals('feast_all_saints'));
      },
    );

    test(
      'migrates from schema version 13 to 16 when lectionary_readings table is missing',
      () async {
        final rawDb = NativeDatabase.memory(
          setup: (db) {
            db.execute('''
              CREATE TABLE bible_verses (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_number INT NOT NULL,
                verse_text TEXT NOT NULL,
                translation_code TEXT NOT NULL
              );
              CREATE TABLE favorite_passages (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                start_verse INT NOT NULL,
                end_verse INT NOT NULL,
                text_preview TEXT NOT NULL
              );
              CREATE TABLE prayers (
                isar_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                prayer_id TEXT NOT NULL UNIQUE,
                default_title TEXT NOT NULL,
                category TEXT NOT NULL,
                default_order INT NOT NULL,
                has_amen INTEGER NOT NULL,
                hash TEXT NOT NULL,
                localized_translations TEXT
              );
              CREATE TABLE user_settings (
                id INTEGER NOT NULL DEFAULT 1,
                primary_language_code TEXT NOT NULL,
                compare_language_code TEXT NOT NULL,
                primary_bible_translation TEXT NOT NULL,
                compare_bible_translation TEXT NOT NULL,
                preferred_versions TEXT,
                haptics_enabled INTEGER NOT NULL DEFAULT 1,
                app_theme_mode_code TEXT NOT NULL DEFAULT 'marian_blue',
                sunday_notifications_enabled INTEGER NOT NULL DEFAULT 1,
                show_bible_translation_selectors INTEGER NOT NULL DEFAULT 0,
                bible_numbering_system_code TEXT NOT NULL DEFAULT 'vulgate',
                prayer_catalog_version INT NOT NULL DEFAULT 0,
                last_bible_book_number INT NOT NULL DEFAULT 1,
                last_bible_chapter INT NOT NULL DEFAULT 1,
                missal_readings_only INTEGER NOT NULL DEFAULT 0,
                missal_hidden_prayers TEXT,
                PRIMARY KEY (id)
              );
              CREATE TABLE user_comments (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                document_id TEXT NOT NULL,
                section_index INT NOT NULL,
                node_id TEXT NOT NULL,
                comment_text TEXT NOT NULL,
                text_preview TEXT,
                created_at DATETIME NOT NULL
              );
              CREATE TABLE library_bookmarks (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                document_id TEXT NOT NULL,
                section_index INT NOT NULL,
                node_id TEXT NOT NULL,
                text_preview TEXT NOT NULL,
                created_at DATETIME NOT NULL
              );
              CREATE TABLE book_reading_positions (
                book_id TEXT NOT NULL PRIMARY KEY,
                volume_key TEXT,
                section_index INT NOT NULL DEFAULT 0,
                section_id TEXT,
                updated_at DATETIME NOT NULL
              );
              PRAGMA user_version = 13;
            ''');
          },
        );
        final migratedDb = BibleDatabase(rawDb);
        addTearDown(migratedDb.close);

        expect(migratedDb.schemaVersion, equals(16));

        final readings = await migratedDb.getReadings('feast_all_saints');
        expect(readings, isNotEmpty);
        expect(readings.first.readingKey, equals('feast_all_saints'));
      },
    );

    test(
      'migrates from schema version 13 to 16 when lectionary_readings table already exists',
      () async {
        final rawDb = NativeDatabase.memory(
          setup: (db) {
            db.execute('''
              CREATE TABLE bible_verses (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_number INT NOT NULL,
                verse_text TEXT NOT NULL,
                translation_code TEXT NOT NULL
              );
              CREATE TABLE lectionary_readings (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                reading_key TEXT NOT NULL,
                reading_type TEXT NOT NULL,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_range TEXT NOT NULL,
                citation TEXT NOT NULL
              );
              CREATE TABLE favorite_passages (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                start_verse INT NOT NULL,
                end_verse INT NOT NULL,
                text_preview TEXT NOT NULL
              );
              CREATE TABLE prayers (
                isar_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                prayer_id TEXT NOT NULL UNIQUE,
                default_title TEXT NOT NULL,
                category TEXT NOT NULL,
                default_order INT NOT NULL,
                has_amen INTEGER NOT NULL,
                hash TEXT NOT NULL,
                localized_translations TEXT
              );
              CREATE TABLE user_settings (
                id INTEGER NOT NULL DEFAULT 1,
                primary_language_code TEXT NOT NULL,
                compare_language_code TEXT NOT NULL,
                primary_bible_translation TEXT NOT NULL,
                compare_bible_translation TEXT NOT NULL,
                preferred_versions TEXT,
                haptics_enabled INTEGER NOT NULL DEFAULT 1,
                app_theme_mode_code TEXT NOT NULL DEFAULT 'marian_blue',
                sunday_notifications_enabled INTEGER NOT NULL DEFAULT 1,
                show_bible_translation_selectors INTEGER NOT NULL DEFAULT 0,
                bible_numbering_system_code TEXT NOT NULL DEFAULT 'vulgate',
                prayer_catalog_version INT NOT NULL DEFAULT 0,
                last_bible_book_number INT NOT NULL DEFAULT 1,
                last_bible_chapter INT NOT NULL DEFAULT 1,
                missal_readings_only INTEGER NOT NULL DEFAULT 0,
                missal_hidden_prayers TEXT,
                PRIMARY KEY (id)
              );
              CREATE TABLE user_comments (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                document_id TEXT NOT NULL,
                section_index INT NOT NULL,
                node_id TEXT NOT NULL,
                comment_text TEXT NOT NULL,
                text_preview TEXT,
                created_at DATETIME NOT NULL
              );
              CREATE TABLE library_bookmarks (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                document_id TEXT NOT NULL,
                section_index INT NOT NULL,
                node_id TEXT NOT NULL,
                text_preview TEXT NOT NULL,
                created_at DATETIME NOT NULL
              );
              CREATE TABLE book_reading_positions (
                book_id TEXT NOT NULL PRIMARY KEY,
                volume_key TEXT,
                section_index INT NOT NULL DEFAULT 0,
                section_id TEXT,
                updated_at DATETIME NOT NULL
              );
              PRAGMA user_version = 13;
            ''');
          },
        );
        final migratedDb = BibleDatabase(rawDb);
        addTearDown(migratedDb.close);

        expect(migratedDb.schemaVersion, equals(16));

        final readings = await migratedDb.getReadings('feast_all_saints');
        expect(readings, isNotEmpty);
        expect(readings.first.readingKey, equals('feast_all_saints'));
      },
    );

    test(
      'migrates from schema version 14 to 16 and adds reminder fields and bible_ribbons',
      () async {
        final rawDb = NativeDatabase.memory(
          setup: (db) {
            db.execute('''
              CREATE TABLE bible_verses (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_number INT NOT NULL,
                verse_text TEXT NOT NULL,
                translation_code TEXT NOT NULL
              );
              CREATE TABLE lectionary_readings (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                reading_key TEXT NOT NULL,
                reading_type TEXT NOT NULL,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_range TEXT NOT NULL,
                citation TEXT NOT NULL
              );
              CREATE TABLE favorite_passages (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                start_verse INT NOT NULL,
                end_verse INT NOT NULL,
                text_preview TEXT NOT NULL
              );
              CREATE TABLE prayers (
                isar_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                prayer_id TEXT NOT NULL UNIQUE,
                default_title TEXT NOT NULL,
                category TEXT NOT NULL,
                default_order INT NOT NULL,
                has_amen INTEGER NOT NULL,
                hash TEXT NOT NULL,
                localized_translations TEXT
              );
              CREATE TABLE user_settings (
                id INTEGER NOT NULL DEFAULT 1,
                primary_language_code TEXT NOT NULL,
                compare_language_code TEXT NOT NULL,
                primary_bible_translation TEXT NOT NULL,
                compare_bible_translation TEXT NOT NULL,
                preferred_versions TEXT,
                haptics_enabled INTEGER NOT NULL DEFAULT 1,
                app_theme_mode_code TEXT NOT NULL DEFAULT 'marian_blue',
                sunday_notifications_enabled INTEGER NOT NULL DEFAULT 1,
                show_bible_translation_selectors INTEGER NOT NULL DEFAULT 0,
                bible_numbering_system_code TEXT NOT NULL DEFAULT 'vulgate',
                prayer_catalog_version INT NOT NULL DEFAULT 0,
                last_bible_book_number INT NOT NULL DEFAULT 1,
                last_bible_chapter INT NOT NULL DEFAULT 1,
                missal_readings_only INTEGER NOT NULL DEFAULT 0,
                missal_hidden_prayers TEXT,
                PRIMARY KEY (id)
              );
              CREATE TABLE user_comments (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                document_id TEXT NOT NULL,
                section_index INT NOT NULL,
                node_id TEXT NOT NULL,
                comment_text TEXT NOT NULL,
                text_preview TEXT,
                created_at DATETIME NOT NULL
              );
              CREATE TABLE library_bookmarks (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                document_id TEXT NOT NULL,
                section_index INT NOT NULL,
                node_id TEXT NOT NULL,
                text_preview TEXT NOT NULL,
                created_at DATETIME NOT NULL
              );
              CREATE TABLE book_reading_positions (
                book_id TEXT NOT NULL PRIMARY KEY,
                volume_key TEXT,
                section_index INT NOT NULL DEFAULT 0,
                section_id TEXT,
                updated_at DATETIME NOT NULL
              );
              PRAGMA user_version = 14;
            ''');
          },
        );
        final migratedDb = BibleDatabase(rawDb);
        addTearDown(migratedDb.close);

        expect(migratedDb.schemaVersion, equals(16));

        final initialSettings = UserSettings(
          angelusReminderEnabled: true,
          rosaryReminderEnabled: true,
          rosaryReminderHour: 21,
          rosaryReminderMinute: 15,
          bibleRibbons: [
            const BibleRibbonBookmark(
              ribbonIndex: 0,
              bookNumber: 1,
              chapter: 1,
            ),
          ],
        );
        await migratedDb.saveUserSettings(initialSettings);

        final loaded = await migratedDb.getUserSettings();
        expect(loaded, isNotNull);
        expect(loaded!.angelusReminderEnabled, isTrue);
        expect(loaded.rosaryReminderEnabled, isTrue);
        expect(loaded.rosaryReminderHour, equals(21));
        expect(loaded.rosaryReminderMinute, equals(15));
        expect(loaded.bibleRibbons, isNotNull);
        expect(loaded.bibleRibbons!.length, equals(1));
        expect(loaded.bibleRibbons!.first.ribbonIndex, equals(0));
      },
    );

    test(
      'migrates from schema version 15 to 16 and adds bible_ribbons column',
      () async {
        final rawDb = NativeDatabase.memory(
          setup: (db) {
            db.execute('''
              CREATE TABLE bible_verses (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_number INT NOT NULL,
                verse_text TEXT NOT NULL,
                translation_code TEXT NOT NULL
              );
              CREATE TABLE lectionary_readings (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                reading_key TEXT NOT NULL,
                reading_type TEXT NOT NULL,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                verse_range TEXT NOT NULL,
                citation TEXT NOT NULL
              );
              CREATE TABLE favorite_passages (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                book_number INT NOT NULL,
                book_name TEXT NOT NULL,
                chapter INT NOT NULL,
                start_verse INT NOT NULL,
                end_verse INT NOT NULL,
                text_preview TEXT NOT NULL
              );
              CREATE TABLE prayers (
                isar_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                prayer_id TEXT NOT NULL UNIQUE,
                default_title TEXT NOT NULL,
                category TEXT NOT NULL,
                default_order INT NOT NULL,
                has_amen INTEGER NOT NULL,
                hash TEXT NOT NULL,
                localized_translations TEXT
              );
              CREATE TABLE user_settings (
                id INTEGER NOT NULL DEFAULT 1,
                primary_language_code TEXT NOT NULL,
                compare_language_code TEXT NOT NULL,
                primary_bible_translation TEXT NOT NULL,
                compare_bible_translation TEXT NOT NULL,
                preferred_versions TEXT,
                haptics_enabled INTEGER NOT NULL DEFAULT 1,
                app_theme_mode_code TEXT NOT NULL DEFAULT 'marian_blue',
                sunday_notifications_enabled INTEGER NOT NULL DEFAULT 1,
                show_bible_translation_selectors INTEGER NOT NULL DEFAULT 0,
                bible_numbering_system_code TEXT NOT NULL DEFAULT 'vulgate',
                prayer_catalog_version INT NOT NULL DEFAULT 0,
                last_bible_book_number INT NOT NULL DEFAULT 1,
                last_bible_chapter INT NOT NULL DEFAULT 1,
                missal_readings_only INTEGER NOT NULL DEFAULT 0,
                missal_hidden_prayers TEXT,
                angelus_reminder_enabled INTEGER NOT NULL DEFAULT 0,
                angelus_morning_enabled INTEGER NOT NULL DEFAULT 0,
                angelus_midday_enabled INTEGER NOT NULL DEFAULT 1,
                angelus_evening_enabled INTEGER NOT NULL DEFAULT 0,
                rosary_reminder_enabled INTEGER NOT NULL DEFAULT 0,
                rosary_reminder_hour INT NOT NULL DEFAULT 20,
                rosary_reminder_minute INT NOT NULL DEFAULT 0,
                morning_prayer_reminder_enabled INTEGER NOT NULL DEFAULT 0,
                morning_prayer_reminder_hour INT NOT NULL DEFAULT 7,
                morning_prayer_reminder_minute INT NOT NULL DEFAULT 0,
                night_prayer_reminder_enabled INTEGER NOT NULL DEFAULT 0,
                night_prayer_reminder_hour INT NOT NULL DEFAULT 21,
                night_prayer_reminder_minute INT NOT NULL DEFAULT 30,
                PRIMARY KEY (id)
              );
              PRAGMA user_version = 15;
            ''');
          },
        );
        final migratedDb = BibleDatabase(rawDb);
        addTearDown(migratedDb.close);

        expect(migratedDb.schemaVersion, equals(16));

        final settings = UserSettings(
          bibleRibbons: [
            const BibleRibbonBookmark(
              ribbonIndex: 3,
              bookNumber: 43,
              chapter: 1,
            ),
          ],
        );
        await migratedDb.saveUserSettings(settings);

        final loaded = await migratedDb.getUserSettings();
        expect(loaded, isNotNull);
        expect(loaded!.bibleRibbons, isNotNull);
        expect(loaded.bibleRibbons!.length, equals(1));
        expect(loaded.bibleRibbons!.first.ribbonIndex, equals(3));
        expect(loaded.bibleRibbons!.first.bookNumber, equals(43));
        expect(loaded.bibleRibbons!.first.chapter, equals(1));
      },
    );
  });
}
