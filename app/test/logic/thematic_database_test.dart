import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ThematicHelper.mockPassages = null;
    ThematicHelper.mockRandom = null;
    ThematicHelper.clearCache();
    rootBundle.evict(ThematicHelper.assetPath);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('1. Model Deserialization (ThematicPassage.fromJson)', () {
    test('Full Payload Parsing populates all properties', () {
      final json = <String, dynamic>{
        'bookId': 'test_book',
        'bookTitle': 'Test Book Title',
        'author': 'Test Author',
        'sectionId': 'test_sec_1',
        'sectionTitle': 'Test Section Title',
        'itemIndex': 42,
        'questionNumber': 123,
        'primaryTheme': 'sacraments.eucharist',
        'secondaryThemes': ['theology.trinity', 'prayer.contemplation_union'],
        'keyExcerpt': 'Test excerpt text',
        'oneSentenceSummary': 'Test summary statement',
        'fullText': 'Test full body text',
      };

      final passage = ThematicPassage.fromJson(
        json,
        authorSaintId: 'test_saint_id',
      );

      expect(passage.bookId, 'test_book');
      expect(passage.bookTitle, 'Test Book Title');
      expect(passage.author, 'Test Author');
      expect(passage.sectionId, 'test_sec_1');
      expect(passage.sectionTitle, 'Test Section Title');
      expect(passage.itemIndex, 42);
      expect(passage.questionNumber, 123);
      expect(passage.primaryTheme, 'sacraments.eucharist');
      expect(passage.secondaryThemes, [
        'theology.trinity',
        'prayer.contemplation_union',
      ]);
      expect(passage.keyExcerpt, 'Test excerpt text');
      expect(passage.oneSentenceSummary, 'Test summary statement');
      expect(passage.fullText, 'Test full body text');
      expect(passage.authorSaintId, 'test_saint_id');
    });

    test('Fallback and Default Values for empty or omitted JSON fields', () {
      final passage = ThematicPassage.fromJson({});

      expect(passage.bookId, '');
      expect(passage.bookTitle, '');
      expect(passage.author, '');
      expect(passage.sectionId, '');
      expect(passage.sectionTitle, '');
      expect(passage.itemIndex, 0);
      expect(passage.questionNumber, isNull);
      expect(passage.primaryTheme, 'theology.trinity');
      expect(passage.secondaryThemes, isEmpty);
      expect(passage.keyExcerpt, '');
      expect(passage.oneSentenceSummary, '');
      expect(passage.fullText, '');
      expect(passage.authorSaintId, isNull);
    });

    test(
      'Secondary Themes dynamic list conversion casts elements to string',
      () {
        final json = <String, dynamic>{
          'secondaryThemes': [123, true, 45.67, 'sacraments.baptism'],
        };

        final passage = ThematicPassage.fromJson(json);

        expect(passage.secondaryThemes, [
          '123',
          'true',
          '45.67',
          'sacraments.baptism',
        ]);
      },
    );
  });

  group('2. Taxonomy & Invariant Checks', () {
    test('categoryGroups defines exactly 7 valid groups', () {
      expect(ThematicHelper.categoryGroups.length, 7);

      for (final group in ThematicHelper.categoryGroups) {
        expect(group.name.trim(), isNotEmpty);
        expect(group.icon.trim(), isNotEmpty);
        expect(group.themes, isNotEmpty);
        for (final entry in group.themes.entries) {
          expect(entry.key.trim(), isNotEmpty);
          expect(entry.value.trim(), isNotEmpty);
        }
      }
    });

    test('allThemes contains exactly 35 unique themes without duplicates', () {
      expect(ThematicHelper.allThemes.length, 35);

      final allKeysCount = ThematicHelper.categoryGroups.fold<int>(
        0,
        (sum, group) => sum + group.themes.length,
      );
      expect(allKeysCount, 35);

      final uniqueKeys = <String>{};
      for (final group in ThematicHelper.categoryGroups) {
        for (final key in group.themes.keys) {
          expect(
            uniqueKeys.contains(key),
            isFalse,
            reason: 'Duplicate theme key detected: $key',
          );
          uniqueKeys.add(key);
        }
      }
      expect(uniqueKeys.length, 35);
    });

    test('getThemeTitle returns expected titles and falls back to themeId', () {
      expect(
        ThematicHelper.getThemeTitle('sacraments.eucharist'),
        'The Most Holy Eucharist & The Mass',
      );
      expect(
        ThematicHelper.getThemeTitle('theology.trinity'),
        'The Holy Trinity & Divine Nature',
      );
      expect(
        ThematicHelper.getThemeTitle('prayer.vocal_mental_meditation'),
        'Vocal & Mental Prayer, Our Father',
      );
      expect(
        ThematicHelper.getThemeTitle('combat.temptation_sin'),
        'Temptations & Capital Sins',
      );
      expect(
        ThematicHelper.getThemeTitle('virtues.faith_hope_charity'),
        'Theological Virtues: Faith, Hope & Charity',
      );
      expect(
        ThematicHelper.getThemeTitle('ecclesiology.church_unity_papacy'),
        'Unity of the Church & Papacy',
      );
      expect(
        ThematicHelper.getThemeTitle('devotion.our_lady'),
        'The Blessed Virgin Mary & Consecration',
      );
      expect(
        ThematicHelper.getThemeTitle('unrecognized.test.key'),
        'unrecognized.test.key',
      );
    });
  });

  group('3. Passage Loading, Caching & Mocking Lifecycle', () {
    test(
      'ThematicHelper.mockPassages takes precedence over asset loading',
      () async {
        final mock = [
          ThematicPassage(
            bookId: 'mock_book',
            bookTitle: 'Mock Book',
            author: 'Mock Author',
            sectionId: 'mock_sec',
            sectionTitle: 'Mock Section',
            itemIndex: 0,
            primaryTheme: 'sacraments.eucharist',
            keyExcerpt: 'Mock excerpt',
            oneSentenceSummary: 'Mock summary',
            fullText: 'Mock full text',
          ),
        ];

        ThematicHelper.mockPassages = mock;

        final passages = await ThematicHelper.loadAllPassages();
        expect(passages, same(mock));
        expect(passages.length, 1);
        expect(passages.first.bookId, 'mock_book');
      },
    );

    test(
      'loadAllPassages caches results in memory across consecutive calls',
      () async {
        final first = await ThematicHelper.loadAllPassages();
        final second = await ThematicHelper.loadAllPassages();

        expect(first, isNotEmpty);
        expect(identical(first, second), isTrue);
      },
    );

    test(
      'forceReload: true invalidates and refreshes cached list reference',
      () async {
        final original = await ThematicHelper.loadAllPassages();
        final reloaded = await ThematicHelper.loadAllPassages(
          forceReload: true,
        );

        expect(original, isNotEmpty);
        expect(reloaded, isNotEmpty);
        expect(identical(original, reloaded), isFalse);
        expect(original.length, equals(reloaded.length));
      },
    );

    test(
      'gracefully handles missing assets and corrupted JSON without throwing',
      () async {
        // 1. Asset missing / unreadable (handler returning null triggers FlutterError)
        ThematicHelper.clearCache();
        rootBundle.evict(ThematicHelper.assetPath);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
              return null;
            });

        final resultOnException = await ThematicHelper.loadAllPassages(
          forceReload: true,
        );
        expect(resultOnException, isEmpty);

        // 2. Corrupted malformed JSON payload
        ThematicHelper.clearCache();
        rootBundle.evict(ThematicHelper.assetPath);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
              const malformed = '{"passages": [NOT_VALID_JSON}';
              return ByteData.view(
                Uint8List.fromList(utf8.encode(malformed)).buffer,
              );
            });

        final resultOnCorrupt = await ThematicHelper.loadAllPassages(
          forceReload: true,
        );
        expect(resultOnCorrupt, isEmpty);
      },
    );

    test(
      'authorSaintId correctly attributed via LibraryHelper catalog lookup',
      () async {
        final passages = await ThematicHelper.loadAllPassages();
        expect(passages, isNotEmpty);

        final catalog = LibraryHelper.getCatalog();
        final Map<String, String?> bookSaintMap = {};
        for (final b in catalog) {
          bookSaintMap[b.id] = b.authorSaintId;
          if (b.volumes != null) {
            for (final v in b.volumes!) {
              bookSaintMap[v.volumeKey] = b.authorSaintId;
            }
          }
        }

        final vincentPassages = passages.where(
          (p) => p.bookId == 'vincent_commonitory',
        );
        expect(vincentPassages, isNotEmpty);
        for (final p in vincentPassages) {
          expect(p.authorSaintId, 'vincent-of-lerins');
        }

        for (final p in passages) {
          if (bookSaintMap.containsKey(p.bookId)) {
            expect(p.authorSaintId, equals(bookSaintMap[p.bookId]));
          }
        }
      },
    );
  });

  group('4. Theme Aggregation & Filtering Logic', () {
    test(
      'getThemeCounts accurately tallies primary and secondary themes',
      () async {
        ThematicHelper.mockPassages = [
          ThematicPassage(
            bookId: 'b1',
            bookTitle: 'Book 1',
            author: 'Author 1',
            sectionId: 's1',
            sectionTitle: 'Sec 1',
            itemIndex: 0,
            primaryTheme: 'theology.trinity',
            secondaryThemes: ['sacraments.eucharist'],
            keyExcerpt: '',
            oneSentenceSummary: '',
            fullText: '',
          ),
          ThematicPassage(
            bookId: 'b2',
            bookTitle: 'Book 2',
            author: 'Author 2',
            sectionId: 's2',
            sectionTitle: 'Sec 2',
            itemIndex: 0,
            primaryTheme: 'sacraments.eucharist',
            secondaryThemes: ['prayer.contemplation_union'],
            keyExcerpt: '',
            oneSentenceSummary: '',
            fullText: '',
          ),
          ThematicPassage(
            bookId: 'b3',
            bookTitle: 'Book 3',
            author: 'Author 3',
            sectionId: 's3',
            sectionTitle: 'Sec 3',
            itemIndex: 0,
            primaryTheme: 'theology.trinity',
            secondaryThemes: [
              'theology.trinity',
            ], // Overlapping secondary theme
            keyExcerpt: '',
            oneSentenceSummary: '',
            fullText: '',
          ),
        ];

        final counts = await ThematicHelper.getThemeCounts();

        // theology.trinity: b1 (primary) + b3 (primary) + b3 (secondary) = 3
        expect(counts['theology.trinity'], 3);
        // sacraments.eucharist: b1 (secondary) + b2 (primary) = 2
        expect(counts['sacraments.eucharist'], 2);
        // prayer.contemplation_union: b2 (secondary) = 1
        expect(counts['prayer.contemplation_union'], 1);
        expect(counts['unknown.theme'], isNull);
      },
    );

    test(
      'getPassagesForTheme filters by primary or secondary theme membership',
      () async {
        final p1 = ThematicPassage(
          bookId: 'b1',
          bookTitle: 'Book 1',
          author: 'Author 1',
          sectionId: 's1',
          sectionTitle: 'Sec 1',
          itemIndex: 1,
          primaryTheme: 'theology.trinity',
          secondaryThemes: ['sacraments.eucharist'],
          keyExcerpt: '',
          oneSentenceSummary: '',
          fullText: '',
        );
        final p2 = ThematicPassage(
          bookId: 'b2',
          bookTitle: 'Book 2',
          author: 'Author 2',
          sectionId: 's2',
          sectionTitle: 'Sec 2',
          itemIndex: 2,
          primaryTheme: 'sacraments.baptism',
          secondaryThemes: ['theology.trinity'],
          keyExcerpt: '',
          oneSentenceSummary: '',
          fullText: '',
        );
        final p3 = ThematicPassage(
          bookId: 'b3',
          bookTitle: 'Book 3',
          author: 'Author 3',
          sectionId: 's3',
          sectionTitle: 'Sec 3',
          itemIndex: 3,
          primaryTheme: 'virtues.faith_hope_charity',
          secondaryThemes: ['combat.spiritual_warfare'],
          keyExcerpt: '',
          oneSentenceSummary: '',
          fullText: '',
        );

        ThematicHelper.mockPassages = [p1, p2, p3];

        final trinityPassages = await ThematicHelper.getPassagesForTheme(
          'theology.trinity',
          shuffle: false,
        );
        expect(trinityPassages.length, 2);
        expect(trinityPassages, containsAll([p1, p2]));
        expect(trinityPassages, isNot(contains(p3)));

        final eucharistPassages = await ThematicHelper.getPassagesForTheme(
          'sacraments.eucharist',
          shuffle: false,
        );
        expect(eucharistPassages.length, 1);
        expect(eucharistPassages.first, same(p1));

        final nonExistent = await ThematicHelper.getPassagesForTheme(
          'eschatology.heaven_beatific_vision',
          shuffle: false,
        );
        expect(nonExistent, isEmpty);
      },
    );

    test('Deterministic Shuffling vs Preserved Ordering', () async {
      final mockList = List.generate(
        10,
        (i) => ThematicPassage(
          bookId: 'book_$i',
          bookTitle: 'Title $i',
          author: 'Author $i',
          sectionId: 'sec_$i',
          sectionTitle: 'Section $i',
          itemIndex: i,
          primaryTheme: 'theology.trinity',
          keyExcerpt: '',
          oneSentenceSummary: '',
          fullText: '',
        ),
      );

      ThematicHelper.mockPassages = mockList;

      // 1. shuffle: false maintains original insertion order deterministically
      final unshuffled1 = await ThematicHelper.getPassagesForTheme(
        'theology.trinity',
        shuffle: false,
      );
      final unshuffled2 = await ThematicHelper.getPassagesForTheme(
        'theology.trinity',
        shuffle: false,
      );

      expect(
        unshuffled1.map((p) => p.itemIndex).toList(),
        List.generate(10, (i) => i),
      );
      expect(
        unshuffled2.map((p) => p.itemIndex).toList(),
        List.generate(10, (i) => i),
      );

      // 2. shuffle: true with seeded mockRandom produces reproducible ordering
      ThematicHelper.mockRandom = Random(42);
      final shuffled1 = await ThematicHelper.getPassagesForTheme(
        'theology.trinity',
        shuffle: true,
      );
      final indices1 = shuffled1.map((p) => p.itemIndex).toList();

      ThematicHelper.mockRandom = Random(42);
      final shuffled2 = await ThematicHelper.getPassagesForTheme(
        'theology.trinity',
        shuffle: true,
      );
      final indices2 = shuffled2.map((p) => p.itemIndex).toList();

      expect(indices1, equals(indices2));
      expect(indices1, isNot(equals(List.generate(10, (i) => i))));
    });
  });
}
