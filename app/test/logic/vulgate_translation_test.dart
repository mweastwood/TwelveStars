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

  group('Clementine Latin Vulgate (VUL) Integration Tests', () {
    test('populates and queries Genesis 1 from VUL USFM asset', () async {
      await testDb.ensureBookPopulated(1, 'Genesis', 'GEN', translation: 'VUL');

      final verses = await testDb.getChapterVerses('VUL', 1, 1);
      expect(verses, isNotEmpty);
      expect(verses.first.verseText, contains('In principio creavit Deus'));
      expect(verses.first.translationCode, equals('VUL'));
    });
  });
}
