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

    test('generateSteps generates exactly 67 steps with correct sequence', () {
      for (final type in RosaryMysteryType.values) {
        final steps = RosaryHelper.generateSteps(type);
        expect(
          steps.length,
          equals(67),
          reason: 'Failed for mystery type $type',
        );

        // Step 1: Crucifix
        expect(steps[0].beadType, equals(RosaryBeadType.crucifix));
        expect(steps[0].prayerId, equals('sign_of_the_cross'));
        expect(steps[0].secondaryPrayerId, equals('apostles_creed'));

        // Step 2: Our Father
        expect(steps[1].beadType, equals(RosaryBeadType.large));
        expect(steps[1].prayerId, equals('our_father'));
        expect(steps[1].mystery, isNull);

        // Steps 3-5: Hail Marys
        for (int i = 2; i <= 4; i++) {
          expect(steps[i].beadType, equals(RosaryBeadType.small));
          expect(steps[i].prayerId, equals('hail_mary'));
        }

        // Step 6: Glory Be
        expect(steps[5].beadType, equals(RosaryBeadType.chainLink));
        expect(steps[5].prayerId, equals('glory_be'));

        // Step 7 to 65: 5 Decades (each is 12 steps)
        for (int decade = 0; decade < 5; decade++) {
          final startIdx = 6 + (decade * 12);

          // 1. Decade Our Father
          expect(steps[startIdx].beadType, equals(RosaryBeadType.large));
          expect(steps[startIdx].prayerId, equals('our_father'));
          expect(steps[startIdx].decadeIndex, equals(decade));
          expect(steps[startIdx].mystery, isNotNull);
          expect(steps[startIdx].mystery!.number, equals(decade + 1));

          // 2. 10 Hail Marys
          for (int h = 0; h < 10; h++) {
            final idx = startIdx + 1 + h;
            expect(steps[idx].beadType, equals(RosaryBeadType.small));
            expect(steps[idx].prayerId, equals('hail_mary'));
            expect(steps[idx].decadeIndex, equals(decade));
            expect(steps[idx].beadIndexInDecade, equals(h + 1));
            expect(steps[idx].mystery!.number, equals(decade + 1));
          }

          // 3. Glory Be & Fatima Prayer combo
          final endIdx = startIdx + 11;
          expect(steps[endIdx].beadType, equals(RosaryBeadType.chainLink));
          expect(steps[endIdx].prayerId, equals('glory_be'));
          expect(steps[endIdx].secondaryPrayerId, equals('fatima_prayer'));
          expect(steps[endIdx].decadeIndex, equals(decade));
        }

        // Step 66: Closing Prayers Medal
        expect(steps[66].beadType, equals(RosaryBeadType.medal));
        expect(steps[66].prayerId, equals('hail_holy_queen'));
        expect(steps[66].secondaryPrayerId, equals('final_prayer_rosary'));
        expect(steps[66].tertiaryPrayerId, equals('sign_of_the_cross'));
      }
    });

    test('generateSteps maps correct mysteries to each type', () {
      // Joyful
      final joyfulSteps = RosaryHelper.generateSteps(RosaryMysteryType.joyful);
      expect(joyfulSteps[6].mystery!.title, equals('The Annunciation'));
      expect(joyfulSteps[18].mystery!.title, equals('The Visitation'));
      expect(joyfulSteps[30].mystery!.title, equals('The Nativity'));
      expect(joyfulSteps[42].mystery!.title, equals('The Presentation'));
      expect(
        joyfulSteps[54].mystery!.title,
        equals('The Finding in the Temple'),
      );

      // Luminous
      final luminousSteps = RosaryHelper.generateSteps(
        RosaryMysteryType.luminous,
      );
      expect(luminousSteps[6].mystery!.title, equals('The Baptism of Christ'));

      // Sorrowful
      final sorrowfulSteps = RosaryHelper.generateSteps(
        RosaryMysteryType.sorrowful,
      );
      expect(
        sorrowfulSteps[6].mystery!.title,
        equals('The Agony in the Garden'),
      );

      // Glorious
      final gloriousSteps = RosaryHelper.generateSteps(
        RosaryMysteryType.glorious,
      );
      expect(gloriousSteps[6].mystery!.title, equals('The Resurrection'));
    });
  });
}
