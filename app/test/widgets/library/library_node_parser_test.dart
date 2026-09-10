import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/library/library_node_parser.dart';

void main() {
  group('parseLibraryNodeId', () {
    test('parses simple chapter and item index with underscore', () {
      final (volKey, itemIdx, qNum) = parseLibraryNodeId('ch1_5');
      expect(volKey, isNull);
      expect(itemIdx, 5);
      expect(qNum, isNull);
    });

    test('parses chapter and item index with hyphen', () {
      final (volKey, itemIdx, qNum) = parseLibraryNodeId('ch1-12');
      expect(volKey, isNull);
      expect(itemIdx, 12);
      expect(qNum, isNull);
    });

    test('parses question number with _q prefix', () {
      final (volKey, itemIdx, qNum) = parseLibraryNodeId('lesson_01_q42');
      expect(volKey, isNull);
      expect(itemIdx, isNull);
      expect(qNum, 42);
    });

    test('parses volume prefix with colon', () {
      final (volKey, itemIdx, qNum) = parseLibraryNodeId('no2:lesson_03_q15');
      expect(volKey, 'no2');
      expect(itemIdx, isNull);
      expect(qNum, 15);
    });

    test('parses volume prefix with item index', () {
      final (volKey, itemIdx, qNum) = parseLibraryNodeId('vol1:sec_2_7');
      expect(volKey, 'vol1');
      expect(itemIdx, 7);
      expect(qNum, isNull);
    });

    test('handles node ID without separators gracefully', () {
      final (volKey, itemIdx, qNum) = parseLibraryNodeId('intro');
      expect(volKey, isNull);
      expect(itemIdx, isNull);
      expect(qNum, isNull);
    });
  });
}
