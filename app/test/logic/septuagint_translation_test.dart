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

    test(
      'ensureBookPopulated cleanly skips New Testament books for LXX without crashing',
      () async {
        // Matthew is book 49
        await expectLater(
          testDb.ensureBookPopulated(49, 'Matthew', 'MAT', translation: 'LXX'),
          completes,
        );

        expect(testDb.inFlightBookPopulations, isEmpty);

        final verses = await testDb.getChapterVerses('LXX', 49, 1);
        expect(verses, isEmpty);

        // Apocalypse / Revelation is book 76
        await expectLater(
          testDb.ensureBookPopulated(
            76,
            'Apocalypse',
            'REV',
            translation: 'LXX',
          ),
          completes,
        );
        expect(testDb.inFlightBookPopulations, isEmpty);

        final revVerses = await testDb.getChapterVerses('LXX', 76, 1);
        expect(revVerses, isEmpty);
      },
    );
  });
}
