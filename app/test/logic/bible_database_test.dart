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
      },
    );
  });

  group('Library Bookmarks Operations', () {
    test('save, get, and delete library bookmarks in BibleDatabase', () async {
      expect(testDb.schemaVersion, equals(9));

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
  });
}
