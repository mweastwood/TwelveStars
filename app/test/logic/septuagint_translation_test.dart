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

  group('Greek Septuagint (LXX) Integration Tests', () {
    test('populates and queries Genesis 1 from LXX USFM asset', () async {
      await testDb.ensureBookPopulated(1, 'Genesis', 'GEN', translation: 'LXX');

      final verses = await testDb.getChapterVerses('LXX', 1, 1);
      expect(verses, isNotEmpty);
      expect(verses.first.verseText, contains('ἘΝ ἀρχῇ ἐποίησεν ὁ Θεὸς'));
      expect(verses.first.translationCode, equals('LXX'));
    });
  });
}
