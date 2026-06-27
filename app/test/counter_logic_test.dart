import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/counter_logic.dart';

void main() {
  group('CounterLogic', () {
    test('starts at 0 with plural label', () {
      final logic = CounterLogic();
      expect(logic.count, 0);
      expect(logic.label, '0 stars shining');
    });

    test('increments count and formats label correctly', () {
      final logic = CounterLogic();
      
      logic.increment();
      expect(logic.count, 1);
      expect(logic.label, '1 star shining');

      logic.increment();
      expect(logic.count, 2);
      expect(logic.label, '2 stars shining');
    });
  });
}
