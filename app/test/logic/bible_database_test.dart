import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';

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
}
