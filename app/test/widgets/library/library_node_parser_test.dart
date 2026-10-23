import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';

void main() {
  group('ReaderNodeId.parseLibrary', () {
    test('parses simple chapter and item index with underscore', () {
      final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary('ch1_5');
      expect(volKey, isNull);
      expect(itemIdx, 5);
      expect(qNum, isNull);
    });

    test('parses chapter and item index with hyphen', () {
      final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary('ch1-12');
      expect(volKey, isNull);
      expect(itemIdx, 12);
      expect(qNum, isNull);
    });

    test('parses question number with _q prefix', () {
      final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary(
        'lesson_01_q42',
      );
      expect(volKey, isNull);
      expect(itemIdx, isNull);
      expect(qNum, 42);
    });

    test('parses volume prefix with colon', () {
      final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary(
        'no2:lesson_03_q15',
      );
      expect(volKey, 'no2');
      expect(itemIdx, isNull);
      expect(qNum, 15);
    });

    test('parses volume prefix with item index', () {
      final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary('vol1:sec_2_7');
      expect(volKey, 'vol1');
      expect(itemIdx, 7);
      expect(qNum, isNull);
    });

    test(
      'parses section ID with underscore and hyphen-delimited item index',
      () {
        final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary('sec_1-0');
        expect(volKey, isNull);
        expect(itemIdx, 0);
        expect(qNum, isNull);

        final (volKey2, itemIdx2, qNum2) = ReaderNodeId.parseLibrary(
          'vol1:sec_1-0',
        );
        expect(volKey2, 'vol1');
        expect(itemIdx2, 0);
        expect(qNum2, isNull);
      },
    );

    test('handles node ID without separators gracefully', () {
      final (volKey, itemIdx, qNum) = ReaderNodeId.parseLibrary('intro');
      expect(volKey, isNull);
      expect(itemIdx, isNull);
      expect(qNum, isNull);
    });
  });
}
