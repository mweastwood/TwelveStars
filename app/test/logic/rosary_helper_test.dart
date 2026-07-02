import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';

void main() {
  group('RosaryHelper', () {
    test('getMysteryForDay maps weekdays correctly', () {
      // Mondays and Saturdays -> Joyful
      expect(
        RosaryHelper.getMysteryForDay(DateTime(2026, 7, 6)),
        RosaryMysteryType.joyful,
      ); // Monday
      expect(
        RosaryHelper.getMysteryForDay(DateTime(2026, 7, 11)),
        RosaryMysteryType.joyful,
      ); // Saturday

      // Tuesdays and Fridays -> Sorrowful
      expect(
        RosaryHelper.getMysteryForDay(DateTime(2026, 7, 7)),
        RosaryMysteryType.sorrowful,
      ); // Tuesday
      expect(
        RosaryHelper.getMysteryForDay(DateTime(2026, 7, 10)),
        RosaryMysteryType.sorrowful,
      ); // Friday

      // Wednesdays and Sundays -> Glorious
      expect(
        RosaryHelper.getMysteryForDay(DateTime(2026, 7, 8)),
        RosaryMysteryType.glorious,
      ); // Wednesday
      expect(
        RosaryHelper.getMysteryForDay(DateTime(2026, 7, 12)),
        RosaryMysteryType.glorious,
      ); // Sunday

      // Thursdays -> Luminous
      expect(
        RosaryHelper.getMysteryForDay(DateTime(2026, 7, 9)),
        RosaryMysteryType.luminous,
      ); // Thursday
    });
  });
}
