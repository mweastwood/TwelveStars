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

  group('Original Languages (ORIG) Integration Tests', () {
    test(
      'populates Hebrew Old Testament Genesis 1 from ORIG USFM asset',
      () async {
        await testDb.ensureBookPopulated(
          1,
          'Genesis',
          'GEN',
          translation: 'ORIG',
        );

        final verses = await testDb.getChapterVerses('ORIG', 1, 1);
        expect(verses, isNotEmpty);
        expect(verses.first.verseText, contains('בְּרֵאשִׁ֖ית'));
        expect(verses.first.translationCode, equals('ORIG'));
      },
    );

    test('populates Greek Deuterocanon Tobit 1 from ORIG USFM asset', () async {
      await testDb.ensureBookPopulated(17, 'Tobit', 'TOB', translation: 'ORIG');

      final verses = await testDb.getChapterVerses('ORIG', 17, 1);
      expect(verses, isNotEmpty);
      expect(verses.first.translationCode, equals('ORIG'));
    });

    test(
      'populates Greek New Testament Matthew 1 from ORIG USFM asset',
      () async {
        await testDb.ensureBookPopulated(
          49,
          'Matthew',
          'MAT',
          translation: 'ORIG',
        );

        final verses = await testDb.getChapterVerses('ORIG', 49, 1);
        expect(verses, isNotEmpty);
        expect(
          verses.first.verseText,
          contains('Βίβλος γενέσεως Ἰησοῦ Χριστοῦ'),
        );
        expect(verses.first.translationCode, equals('ORIG'));
      },
    );
  });
}
