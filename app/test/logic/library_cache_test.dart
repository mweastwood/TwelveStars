import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryHelper LRU Cache Unit Tests', () {
    setUp(() {
      LibraryHelper.clearCache();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            final String key = utf8.decode(message!.buffer.asUint8List());
            final dummyData = {
              'bookId': key,
              'title': 'Book for $key',
              'subtitle': '',
              'author': '',
              'toc': [],
              'sections': [
                {
                  'id': 'sec_1',
                  'title': 'Section 1',
                  'subtitle': '',
                  'content': [
                    {'type': 'text', 'text': 'Content for Book in $key'},
                  ],
                },
              ],
            };
            final jsonStr = jsonEncode(dummyData);
            return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonStr)).buffer,
            );
          });
    });

    tearDown(() {
      LibraryHelper.clearCache();
    });

    test(
      'enforces maxCacheSize (5) and evicts least-recently-used items',
      () async {
        expect(LibraryHelper.cacheSize, equals(0));

        // Load 5 items
        for (int i = 1; i <= 5; i++) {
          await LibraryHelper.loadBookData('path_$i.json');
        }
        expect(LibraryHelper.cacheSize, equals(5));

        // Access path_1.json to make it most recently used
        await LibraryHelper.loadBookData('path_1.json');
        expect(LibraryHelper.cacheSize, equals(5));

        // Load a 6th item -> should evict path_2.json (which is now the LRU item)
        await LibraryHelper.loadBookData('path_6.json');
        expect(LibraryHelper.cacheSize, equals(5));
      },
    );

    test(
      'searchCatalog does not perturb reader LRU cache or evict cached reader items',
      () async {
        expect(LibraryHelper.cacheSize, equals(0));
        expect(LibraryHelper.searchIndexSize, equals(0));

        // Prime the reader LRU cache with 3 items
        await LibraryHelper.loadBookData('path_1.json');
        await LibraryHelper.loadBookData('path_2.json');
        await LibraryHelper.loadBookData('path_3.json');
        expect(LibraryHelper.cacheSize, equals(3));

        // Execute global catalog search
        final results = await LibraryHelper.searchCatalog('Book');
        expect(results, isNotEmpty);

        // Reader cache size should remain 3 (untouched by search)
        expect(LibraryHelper.cacheSize, equals(3));
        expect(LibraryHelper.searchIndexSize, greaterThan(0));

        // Clear cache should reset both LRU cache and search index
        LibraryHelper.clearCache();
        expect(LibraryHelper.cacheSize, equals(0));
        expect(LibraryHelper.searchIndexSize, equals(0));
      },
    );

    test(
      'enforces maxSearchIndexSize (30) when indexing books for catalog search',
      () async {
        expect(LibraryHelper.searchIndexSize, equals(0));
        expect(
          LibraryHelper.getAllCatalogPaths().length,
          greaterThan(LibraryHelper.maxSearchIndexSize),
        );

        final results = await LibraryHelper.searchCatalog(
          'nonexistent_token_so_all_books_are_scanned',
        );
        expect(results, isEmpty);
        expect(
          LibraryHelper.searchIndexSize,
          equals(LibraryHelper.maxSearchIndexSize),
        );
      },
    );

    test(
      'pubspec.yaml excludes build-time raw catechism sources and pinyin_dict.txt',
      () {
        final pubspecFile = File('pubspec.yaml');
        expect(pubspecFile.existsSync(), isTrue);
        final content = pubspecFile.readAsStringSync();

        expect(content, isNot(contains('assets/pinyin_dict.txt')));
        expect(content, isNot(contains('assets/catechism/baltimore/')));
        expect(content, isNot(contains('assets/catechism/trent/')));
        expect(content, isNot(contains('assets/catechism/aquinas/')));
        expect(content, contains('assets/catechism/json/'));
        expect(content, contains('assets/catechism/thematic_index.json'));
      },
    );
  });
}
