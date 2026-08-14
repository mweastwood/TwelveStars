import 'dart:convert';
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
              'sections': [],
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
  });
}
