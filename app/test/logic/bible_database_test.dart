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
    test('handles concurrent ensureBookPopulated calls cleanly without duplicate constraint errors', () async {
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
    });
  });
}
