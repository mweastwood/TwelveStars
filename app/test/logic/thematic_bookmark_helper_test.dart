import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/thematic_bookmark_helper.dart';
import 'package:twelve_stars/logic/thematic_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    ThematicHelper.mockRandom = null;
  });

  tearDown(() async {
    ThematicHelper.mockRandom = null;
    await testDb.close();
  });

  final multiVolumePassage = ThematicPassage(
    bookId: 'baltimore_1',
    bookTitle: 'Baltimore Catechism No. 1',
    author: 'Third Plenary Council of Baltimore',
    sectionId: 'sec_3',
    sectionTitle: 'Lesson 2',
    itemIndex: 1,
    questionNumber: 14,
    primaryTheme: 'theology.trinity',
    secondaryThemes: const [],
    keyExcerpt: 'God is a spirit infinitely perfect.',
    oneSentenceSummary: 'Nature of God.',
    fullText: 'God is a spirit infinitely perfect.',
  );

  final singleVolumePassage = ThematicPassage(
    bookId: 'didache_lightfoot',
    bookTitle: 'The Didache',
    author: 'Apostolic Fathers',
    sectionId: 'ch1',
    sectionTitle: 'Chapter 1',
    itemIndex: 0,
    primaryTheme: 'virtues.faith_hope_charity',
    secondaryThemes: const [],
    keyExcerpt: 'There are two ways, one of life and one of death.',
    oneSentenceSummary: 'The Two Ways.',
    fullText: 'There are two ways, one of life and one of death.',
  );

  final unknownBookPassage = ThematicPassage(
    bookId: 'custom_unknown_book',
    bookTitle: 'Custom Unknown Treatise',
    author: 'St. Thomas Aquinas',
    sectionId: 'part_1',
    sectionTitle: '',
    itemIndex: 2,
    primaryTheme: 'theology.trinity',
    secondaryThemes: const [],
    keyExcerpt: '',
    oneSentenceSummary: 'Summary fallback text.',
    fullText: 'Full text of custom treatise.',
  );

  group('ThematicBookmarkHelper.selectDailyFeaturedPassage', () {
    test('deterministically selects passage from date seed', () {
      final passages = [
        multiVolumePassage,
        singleVolumePassage,
        unknownBookPassage,
      ];
      final date = DateTime(2026, 11, 1);

      final first = ThematicBookmarkHelper.selectDailyFeaturedPassage(
        passages,
        date,
      );
      final second = ThematicBookmarkHelper.selectDailyFeaturedPassage(
        passages,
        date,
      );

      expect(first.bookId, equals(second.bookId));
      final expectedSeed = 2026 * 10000 + 11 * 100 + 1;
      final expectedIndex = Random(expectedSeed).nextInt(passages.length);
      expect(first.bookId, equals(passages[expectedIndex].bookId));
    });

    test('throws ArgumentError when passages list is empty', () {
      expect(
        () => ThematicBookmarkHelper.selectDailyFeaturedPassage(
          const [],
          DateTime(2026, 11, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ThematicBookmarkHelper.bookmarkKeysForPassage', () {
    test(
      'returns legacy and canonical (docId, nodeId) pairs for multi-volume book',
      () {
        final keys = ThematicBookmarkHelper.bookmarkKeysForPassage(
          multiVolumePassage,
        );

        expect(
          keys,
          containsAll([
            (docId: 'baltimore_1', nodeId: 'sec_3_1'),
            (docId: 'baltimore_1', nodeId: 'no1:sec_3_1'),
            (docId: 'baltimore_catechism', nodeId: 'sec_3_1'),
            (docId: 'baltimore_catechism', nodeId: 'no1:sec_3_1'),
          ]),
        );
        expect(keys.length, equals(4));
      },
    );

    test('deduplicates keys when single-volume bookId matches catalog id', () {
      final keys = ThematicBookmarkHelper.bookmarkKeysForPassage(
        singleVolumePassage,
      );

      expect(keys, equals([(docId: 'didache_lightfoot', nodeId: 'ch1_0')]));
    });
  });

  group('ThematicBookmarkHelper.isPassageBookmarked', () {
    test(
      'matches both legacy raw-bookId bookmarks and canonical bookmarks',
      () {
        final legacyBookmark = LibraryBookmark(
          id: 1,
          documentId: 'baltimore_1',
          sectionIndex: 0,
          nodeId: 'sec_3_1',
          textPreview: 'Preview',
          createdAt: DateTime(2026, 1, 1),
        );
        final canonicalBookmark = LibraryBookmark(
          id: 2,
          documentId: 'baltimore_catechism',
          sectionIndex: 2,
          nodeId: 'no1:sec_3_1',
          textPreview: 'Preview',
          createdAt: DateTime(2026, 1, 1),
        );
        final unrelatedBookmark = LibraryBookmark(
          id: 3,
          documentId: 'didache_lightfoot',
          sectionIndex: 0,
          nodeId: 'ch2_0',
          textPreview: 'Preview',
          createdAt: DateTime(2026, 1, 1),
        );

        expect(
          ThematicBookmarkHelper.isPassageBookmarked(multiVolumePassage, [
            legacyBookmark,
          ]),
          isTrue,
        );
        expect(
          ThematicBookmarkHelper.isPassageBookmarked(multiVolumePassage, [
            canonicalBookmark,
          ]),
          isTrue,
        );
        expect(
          ThematicBookmarkHelper.isPassageBookmarked(multiVolumePassage, [
            unrelatedBookmark,
          ]),
          isFalse,
        );
      },
    );
  });

  group('ThematicBookmarkHelper.resolveSectionIndex', () {
    test('returns 0 when assetPath is null or empty', () async {
      expect(
        await ThematicBookmarkHelper.resolveSectionIndex(
          multiVolumePassage,
          null,
        ),
        equals(0),
      );
      expect(
        await ThematicBookmarkHelper.resolveSectionIndex(
          multiVolumePassage,
          '',
        ),
        equals(0),
      );
    });

    test('resolves sectionIndex from loaded book JSON', () async {
      await LibraryHelper.loadBookData(
        'assets/catechism/json/baltimore_1.json',
      );
      final index = await ThematicBookmarkHelper.resolveSectionIndex(
        multiVolumePassage,
        'assets/catechism/json/baltimore_1.json',
      );
      expect(index, equals(2));
    });
  });

  group('ThematicBookmarkHelper.togglePassageBookmark', () {
    test(
      'inserts canonical bookmark when not bookmarked and removes all matching legacy/canonical bookmarks on toggle off',
      () async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_1.json',
        );

        // Toggle ON
        final addResult = await ThematicBookmarkHelper.togglePassageBookmark(
          passage: multiVolumePassage,
          currentBookmarks: const [],
        );
        expect(addResult.isNowBookmarked, isTrue);
        expect(addResult.updatedBookmarks.length, equals(1));
        final saved = addResult.updatedBookmarks.first;
        expect(saved.documentId, equals('baltimore_catechism'));
        expect(saved.nodeId, equals('no1:sec_3_1'));
        expect(saved.sectionIndex, equals(2));
        expect(
          saved.textPreview,
          equals(
            'Baltimore Catechism No. 1 — Lesson 2\nGod is a spirit infinitely perfect.',
          ),
        );

        // Also seed a duplicate legacy bookmark for the same passage
        await testDb.saveLibraryBookmark(
          LibraryBookmarksCompanion.insert(
            documentId: 'baltimore_1',
            sectionIndex: 0,
            nodeId: 'sec_3_1',
            textPreview: 'Legacy duplicate',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        final allBeforeRemove = await testDb.getLibraryBookmarks();
        expect(allBeforeRemove.length, equals(2));

        // Toggle OFF should remove both canonical and legacy bookmarks
        final removeResult = await ThematicBookmarkHelper.togglePassageBookmark(
          passage: multiVolumePassage,
          currentBookmarks: allBeforeRemove,
        );
        expect(removeResult.isNowBookmarked, isFalse);
        expect(removeResult.updatedBookmarks, isEmpty);
      },
    );

    test(
      'falls back to oneSentenceSummary and bookTitle when keyExcerpt and sectionTitle are empty',
      () async {
        final addResult = await ThematicBookmarkHelper.togglePassageBookmark(
          passage: unknownBookPassage,
          currentBookmarks: const [],
        );
        expect(addResult.isNowBookmarked, isTrue);
        expect(addResult.updatedBookmarks.length, equals(1));
        expect(
          addResult.updatedBookmarks.first.textPreview,
          equals('Custom Unknown Treatise\nSummary fallback text.'),
        );
      },
    );
  });

  group('ThematicBookmarkHelper.resolveReaderLaunchTarget', () {
    test(
      'resolves multi-volume book, volume, sectionId, and questionNumber',
      () {
        final target = ThematicBookmarkHelper.resolveReaderLaunchTarget(
          multiVolumePassage,
        );
        expect(target, isNotNull);
        expect(target!.bookItem.id, equals('baltimore_catechism'));
        expect(target.initialVolume, isNotNull);
        expect(target.initialVolume!.volumeKey, equals('no1'));
        expect(
          target.initialVolume!.assetPath,
          equals('assets/catechism/json/baltimore_1.json'),
        );
        expect(target.initialSectionId, equals('sec_3'));
        expect(target.initialQuestionNumber, equals(14));
      },
    );

    test(
      'returns null for unknown book by default and fallback target when fallbackIfMissing is true',
      () {
        expect(
          ThematicBookmarkHelper.resolveReaderLaunchTarget(unknownBookPassage),
          isNull,
        );

        final fallbackTarget = ThematicBookmarkHelper.resolveReaderLaunchTarget(
          unknownBookPassage,
          fallbackIfMissing: true,
        );
        expect(fallbackTarget, isNotNull);
        expect(fallbackTarget!.bookItem.id, equals('custom_unknown_book'));
        expect(
          fallbackTarget.bookItem.category,
          equals('Doctor of the Church'),
        );
        expect(fallbackTarget.initialVolume, isNull);
        expect(fallbackTarget.initialSectionId, equals('part_1'));
        expect(fallbackTarget.initialQuestionNumber, isNull);
      },
    );
  });
}
