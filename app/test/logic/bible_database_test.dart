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
          hapticsEnabled: false,
          appThemeModeCode: 'gothic_dark',
          sundayNotificationsEnabled: false,
        );

        await testDb.saveUserSettings(settings);

        final retrieved = await testDb.getUserSettings();
        expect(retrieved, isNotNull);
        expect(retrieved!.primaryLanguageCode, equals('spanish'));
        expect(retrieved.compareLanguageCode, equals('english'));
        expect(retrieved.primaryBibleTranslation, equals('VUL'));
        expect(retrieved.compareBibleTranslation, equals('CPDV'));
        expect(retrieved.hapticsEnabled, isFalse);
        expect(retrieved.appThemeModeCode, equals('gothic_dark'));
        expect(retrieved.sundayNotificationsEnabled, isFalse);
      },
    );
  });
}
