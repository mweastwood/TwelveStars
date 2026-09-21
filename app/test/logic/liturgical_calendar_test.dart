import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';

void main() {
  setUp(LiturgicalCalendar.resetCache);
  tearDown(LiturgicalCalendar.resetCache);

  group('LiturgicalCalendar Computus & Anchors', () {
    test('calculates correct Easter Sunday dates', () {
      // 2026: April 5
      expect(LiturgicalCalendar.calculateEaster(2026), DateTime(2026, 4, 5));
      // 2027: March 28
      expect(LiturgicalCalendar.calculateEaster(2027), DateTime(2027, 3, 28));
      // 2028: April 16
      expect(LiturgicalCalendar.calculateEaster(2028), DateTime(2028, 4, 16));
    });

    test('calculates correct 1st Sunday of Advent', () {
      // 2026: November 29
      expect(
        LiturgicalCalendar.getFirstSundayOfAdvent(2026),
        DateTime(2026, 11, 29),
      );
      // 2027: November 28
      expect(
        LiturgicalCalendar.getFirstSundayOfAdvent(2027),
        DateTime(2027, 11, 28),
      );
      // 2028: December 3
      expect(
        LiturgicalCalendar.getFirstSundayOfAdvent(2028),
        DateTime(2028, 12, 3),
      );
    });

    test('calculates correct Epiphany and Baptism of the Lord', () {
      // 2026: Epiphany is Sunday Jan 4, Baptism is Sunday Jan 11
      expect(LiturgicalCalendar.getEpiphany(2026), DateTime(2026, 1, 4));
      expect(
        LiturgicalCalendar.getBaptismOfTheLord(2026),
        DateTime(2026, 1, 11),
      );

      // 2027: Epiphany is Sunday Jan 3, Baptism is Sunday Jan 10
      expect(LiturgicalCalendar.getEpiphany(2027), DateTime(2027, 1, 3));
      expect(
        LiturgicalCalendar.getBaptismOfTheLord(2027),
        DateTime(2027, 1, 10),
      );
    });
  });

  group('LiturgicalCalendar Season & Feast Verification', () {
    test('verifies Advent Season', () {
      // Nov 29, 2026: 1st Sunday of Advent (Year B, cycle change)
      final day = LiturgicalCalendar.computeDay(DateTime(2026, 11, 29));
      expect(day.season, LiturgicalSeason.advent);
      expect(day.color, LiturgicalColor.purple);
      expect(day.weekName, '1st Sunday of Advent');
      expect(day.sundayCycle, 'B');
      expect(day.weekdayCycle, 'I');

      // Dec 13, 2026: 3rd Sunday of Advent (Gaudete Sunday, rose color)
      final gaudete = LiturgicalCalendar.computeDay(DateTime(2026, 12, 13));
      expect(gaudete.season, LiturgicalSeason.advent);
      expect(gaudete.color, LiturgicalColor.rose);
      expect(gaudete.weekName, '3rd Sunday of Advent (Gaudete Sunday)');
    });

    test('verifies Christmas Season', () {
      // Dec 25, 2026: Christmas Day
      final day = LiturgicalCalendar.computeDay(DateTime(2026, 12, 25));
      expect(day.season, LiturgicalSeason.christmas);
      expect(day.color, LiturgicalColor.white);
      expect(day.name, 'The Nativity of the Lord (Christmas)');

      // Dec 27, 2026: Holy Family Sunday (Christmas 2026 is Friday)
      final holyFamily2026 = LiturgicalCalendar.computeDay(
        DateTime(2026, 12, 27),
      );
      expect(holyFamily2026.season, LiturgicalSeason.christmas);
      expect(holyFamily2026.color, LiturgicalColor.white);
      expect(holyFamily2026.name, 'The Holy Family of Jesus, Mary and Joseph');
      expect(holyFamily2026.weekName, 'Feast of the Holy Family');

      // Dec 30, 2022: Holy Family Friday (Christmas 2022 was on Sunday Dec 25)
      final holyFamily2022 = LiturgicalCalendar.computeDay(
        DateTime(2022, 12, 30),
      );
      expect(holyFamily2022.season, LiturgicalSeason.christmas);
      expect(holyFamily2022.color, LiturgicalColor.white);
      expect(holyFamily2022.name, 'The Holy Family of Jesus, Mary and Joseph');
      expect(holyFamily2022.weekName, 'Feast of the Holy Family');

      // Dec 30, 2016: Holy Family Friday (Christmas 2016 was on Sunday Dec 25)
      final holyFamily2016 = LiturgicalCalendar.computeDay(
        DateTime(2016, 12, 30),
      );
      expect(holyFamily2016.name, 'The Holy Family of Jesus, Mary and Joseph');
      expect(holyFamily2016.weekName, 'Feast of the Holy Family');

      // Jan 1, 2026: Mary, Mother of God
      final motherOfGod = LiturgicalCalendar.computeDay(DateTime(2026, 1, 1));
      expect(motherOfGod.season, LiturgicalSeason.christmas);
      expect(motherOfGod.color, LiturgicalColor.white);
      expect(motherOfGod.name, 'Mary, the Holy Mother of God');
    });

    test('verifies Lent Season & Triduum', () {
      // Ash Wednesday 2026: Feb 18 (since Easter is April 5,
      // 5 - 46 days = Feb 18)
      final ashWed = LiturgicalCalendar.computeDay(DateTime(2026, 2, 18));
      expect(ashWed.season, LiturgicalSeason.lent);
      expect(ashWed.color, LiturgicalColor.purple);
      expect(ashWed.name, 'Ash Wednesday');

      // Good Friday 2026: April 3
      final goodFri = LiturgicalCalendar.computeDay(DateTime(2026, 4, 3));
      expect(goodFri.season, LiturgicalSeason.triduum);
      expect(goodFri.color, LiturgicalColor.red);
      expect(
        goodFri.name,
        'Good Friday (Celebration of the Passion of the Lord)',
      );
    });

    test('verifies Easter Season', () {
      // Easter Sunday 2026: April 5
      final easter = LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      expect(easter.season, LiturgicalSeason.easter);
      expect(easter.color, LiturgicalColor.white);
      expect(easter.name, 'Easter Sunday of the Resurrection of the Lord');

      // Pentecost Sunday 2026: May 24 (4 + 49 days)
      final pentecost = LiturgicalCalendar.computeDay(DateTime(2026, 5, 24));
      expect(pentecost.season, LiturgicalSeason.easter);
      expect(pentecost.color, LiturgicalColor.red);
      expect(pentecost.name, 'Pentecost Sunday');
    });

    test('verifies Ordinary Time & Solemnities', () {
      // July 2, 2026: Weekday in Ordinary Time
      final day = LiturgicalCalendar.computeDay(DateTime(2026, 7, 2));
      expect(day.season, LiturgicalSeason.ordinaryTime);
      expect(day.color, LiturgicalColor.green);
      expect(day.weekName, 'Thursday of the 13th Week in Ordinary Time');

      // June 29, 2026: Sts. Peter & Paul (Red)
      final stsPeterPaul = LiturgicalCalendar.computeDay(DateTime(2026, 6, 29));
      expect(stsPeterPaul.name, 'Sts. Peter and Paul, Apostles');
      expect(stsPeterPaul.color, LiturgicalColor.red);
    });

    test(
      'calculates correct Ordinary Time week across November DST transition',
      () {
        final nov1 = LiturgicalCalendar.computeDay(DateTime(2026, 11, 1));
        expect(nov1.weekName, '31st Sunday in Ordinary Time');

        final nov8 = LiturgicalCalendar.computeDay(DateTime(2026, 11, 8));
        expect(nov8.weekName, '32nd Sunday in Ordinary Time');

        final nov15 = LiturgicalCalendar.computeDay(DateTime(2026, 11, 15));
        expect(nov15.weekName, '33rd Sunday in Ordinary Time');

        final nov22 = LiturgicalCalendar.computeDay(DateTime(2026, 11, 22));
        expect(nov22.weekName, 'Solemnity of Christ the King');
        expect(nov22.name, 'Our Lord Jesus Christ, King of the Universe');
      },
    );

    test('verifies Christ the King Solemnity lectionaryKey across cycles', () {
      // Year A (2026-11-22)
      final yearA = LiturgicalCalendar.computeDay(DateTime(2026, 11, 22));
      expect(yearA.name, 'Our Lord Jesus Christ, King of the Universe');
      expect(yearA.sundayCycle, 'A');
      expect(yearA.lectionaryKey, 'season_ordinary_time_34_sunday_a');

      // Year B (2024-11-24)
      final yearB = LiturgicalCalendar.computeDay(DateTime(2024, 11, 24));
      expect(yearB.name, 'Our Lord Jesus Christ, King of the Universe');
      expect(yearB.sundayCycle, 'B');
      expect(yearB.lectionaryKey, 'season_ordinary_time_34_sunday_b');

      // Year C (2025-11-23)
      final yearC = LiturgicalCalendar.computeDay(DateTime(2025, 11, 23));
      expect(yearC.name, 'Our Lord Jesus Christ, King of the Universe');
      expect(yearC.sundayCycle, 'C');
      expect(yearC.lectionaryKey, 'season_ordinary_time_34_sunday_c');
    });
  });

  group('LiturgicalCalendar Sunday & Weekday Cycle Calculations', () {
    test('calculates correct Sunday cycle for pre-2019 historical years', () {
      // 2018 Advent start is Dec 2, 2018
      final advent2018 = LiturgicalCalendar.getFirstSundayOfAdvent(2018);
      // Mid-year 2018 (activeYear = 2017): Year B
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2018,
          DateTime(2018, 6, 1),
          advent2018,
        ),
        'B',
      );
      // Advent 2018 (activeYear = 2018): Year C
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2018,
          DateTime(2018, 12, 2),
          advent2018,
        ),
        'C',
      );

      // 2017 Advent start is Dec 3, 2017
      final advent2017 = LiturgicalCalendar.getFirstSundayOfAdvent(2017);
      // Mid-year 2017 (activeYear = 2016): Year A
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2017,
          DateTime(2017, 6, 1),
          advent2017,
        ),
        'A',
      );
      // Advent 2017 (activeYear = 2017): Year B
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2017,
          DateTime(2017, 12, 3),
          advent2017,
        ),
        'B',
      );

      // 2016 Advent start is Nov 27, 2016
      final advent2016 = LiturgicalCalendar.getFirstSundayOfAdvent(2016);
      // Mid-year 2016 (activeYear = 2015): Year C
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2016,
          DateTime(2016, 6, 1),
          advent2016,
        ),
        'C',
      );
      // Advent 2016 (activeYear = 2016): Year A
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2016,
          DateTime(2016, 11, 27),
          advent2016,
        ),
        'A',
      );

      // 2015 Advent start is Nov 29, 2015
      final advent2015 = LiturgicalCalendar.getFirstSundayOfAdvent(2015);
      // Mid-year 2015 (activeYear = 2014): Year B
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2015,
          DateTime(2015, 6, 1),
          advent2015,
        ),
        'B',
      );
      // Advent 2015 (activeYear = 2015): Year C
      expect(
        LiturgicalCalendar.calculateSundayCycle(
          2015,
          DateTime(2015, 11, 29),
          advent2015,
        ),
        'C',
      );
    });

    test(
      'computeDay returns correct Sunday and weekday cycles for historical dates',
      () {
        // 2016
        final day2016Mid = LiturgicalCalendar.computeDay(DateTime(2016, 6, 1));
        expect(day2016Mid.sundayCycle, 'C');
        expect(day2016Mid.weekdayCycle, 'II');

        final day2016Advent = LiturgicalCalendar.computeDay(
          DateTime(2016, 11, 27),
        );
        expect(day2016Advent.sundayCycle, 'A');
        expect(day2016Advent.weekdayCycle, 'I');

        // 2017
        final day2017Mid = LiturgicalCalendar.computeDay(DateTime(2017, 6, 1));
        expect(day2017Mid.sundayCycle, 'A');
        expect(day2017Mid.weekdayCycle, 'I');

        final day2017Advent = LiturgicalCalendar.computeDay(
          DateTime(2017, 12, 3),
        );
        expect(day2017Advent.sundayCycle, 'B');
        expect(day2017Advent.weekdayCycle, 'II');

        // 2018
        final day2018Mid = LiturgicalCalendar.computeDay(DateTime(2018, 6, 1));
        expect(day2018Mid.sundayCycle, 'B');
        expect(day2018Mid.weekdayCycle, 'II');

        final day2018Advent = LiturgicalCalendar.computeDay(
          DateTime(2018, 12, 2),
        );
        expect(day2018Advent.sundayCycle, 'C');
        expect(day2018Advent.weekdayCycle, 'I');

        // 2019
        final day2019Mid = LiturgicalCalendar.computeDay(DateTime(2019, 6, 1));
        expect(day2019Mid.sundayCycle, 'C');
        expect(day2019Mid.weekdayCycle, 'I');

        final day2019Advent = LiturgicalCalendar.computeDay(
          DateTime(2019, 12, 1),
        );
        expect(day2019Advent.sundayCycle, 'A');
        expect(day2019Advent.weekdayCycle, 'II');
      },
    );
  });

  group('LiturgicalCalendar computeDay memoization cache', () {
    setUp(LiturgicalCalendar.resetCache);
    tearDown(LiturgicalCalendar.resetCache);

    test('cache starts empty and grows after computeDay calls', () {
      expect(LiturgicalCalendar.cacheSize, 0);

      LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      expect(LiturgicalCalendar.cacheSize, 1);

      LiturgicalCalendar.computeDay(DateTime(2026, 4, 6));
      expect(LiturgicalCalendar.cacheSize, 2);
    });

    test('returns identical instance for the same calendar date', () {
      final first = LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      final second = LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      expect(identical(first, second), isTrue);
    });

    test(
      'returns cached result for different DateTime objects with the same date '
      '(e.g. non-midnight timestamps are normalised)',
      () {
        // Simulate a timestamp that has non-zero time components.
        final withTime = DateTime(2026, 7, 2, 14, 30, 45);
        final midnight = DateTime(2026, 7, 2);

        final a = LiturgicalCalendar.computeDay(withTime);
        final b = LiturgicalCalendar.computeDay(midnight);

        // Same cache entry: identical object reference.
        expect(identical(a, b), isTrue);
        expect(LiturgicalCalendar.cacheSize, 1);
      },
    );

    test('cache does not conflate distinct dates', () {
      final easter = LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      final christmas = LiturgicalCalendar.computeDay(DateTime(2026, 12, 25));

      expect(identical(easter, christmas), isFalse);
      expect(easter.season, LiturgicalSeason.easter);
      expect(christmas.season, LiturgicalSeason.christmas);
      expect(LiturgicalCalendar.cacheSize, 2);
    });

    test('resetCache clears all entries and cacheSize returns to zero', () {
      LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      LiturgicalCalendar.computeDay(DateTime(2026, 4, 6));
      expect(LiturgicalCalendar.cacheSize, 2);

      LiturgicalCalendar.resetCache();
      expect(LiturgicalCalendar.cacheSize, 0);

      // After reset, computeDay should recompute (cache miss) and re-populate.
      final recomputed = LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      expect(LiturgicalCalendar.cacheSize, 1);
      expect(recomputed.season, LiturgicalSeason.easter);
    });
  });

  group('LiturgicalDay lectionaryKey correctness', () {
    setUp(LiturgicalCalendar.resetCache);
    tearDown(LiturgicalCalendar.resetCache);

    test('returns correct key for each Advent weekday', () {
      // Dec 1, 2026 is Tuesday of the 1st Week of Advent (Cycle B)
      final tue = LiturgicalCalendar.computeDay(DateTime(2026, 12, 1));
      expect(tue.season, LiturgicalSeason.advent);
      expect(tue.lectionaryKey, 'season_advent_1_tuesday');

      // Dec 5, 2026 is Saturday of the 1st Week of Advent
      final sat = LiturgicalCalendar.computeDay(DateTime(2026, 12, 5));
      expect(sat.lectionaryKey, 'season_advent_1_saturday');

      // Dec 6, 2026 is 2nd Sunday of Advent, Year B
      final sun = LiturgicalCalendar.computeDay(DateTime(2026, 12, 6));
      expect(sun.lectionaryKey, 'season_advent_2_sunday_b');
    });

    test(
      'returns correct key for Ash Wednesday and days after Ash Wednesday',
      () {
        final ashWed = LiturgicalCalendar.computeDay(DateTime(2026, 2, 18));
        expect(ashWed.lectionaryKey, 'season_lent_ash_wednesday');

        final thuAfterAshWed = LiturgicalCalendar.computeDay(
          DateTime(2026, 2, 19),
        );
        expect(thuAfterAshWed.weekName, 'Thursday after Ash Wednesday');
        expect(thuAfterAshWed.lectionaryKey, 'season_lent_0_thursday');

        final friAfterAshWed = LiturgicalCalendar.computeDay(
          DateTime(2026, 2, 20),
        );
        expect(friAfterAshWed.weekName, 'Friday after Ash Wednesday');
        expect(friAfterAshWed.lectionaryKey, 'season_lent_0_friday');

        final satAfterAshWed = LiturgicalCalendar.computeDay(
          DateTime(2026, 2, 21),
        );
        expect(satAfterAshWed.weekName, 'Saturday after Ash Wednesday');
        expect(satAfterAshWed.lectionaryKey, 'season_lent_0_saturday');
      },
    );

    test('returns correct key for Lent weekdays and Sundays', () {
      // Feb 22, 2026 is 1st Sunday of Lent, Year A
      final sun = LiturgicalCalendar.computeDay(DateTime(2026, 2, 22));
      expect(sun.lectionaryKey, 'season_lent_1_sunday_a');

      // Feb 23, 2026 is Monday of the 1st Week of Lent
      // (Ash Wednesday was Feb 18, week 0 days; 1st week starts Feb 22)
      final mon = LiturgicalCalendar.computeDay(DateTime(2026, 2, 23));
      expect(mon.lectionaryKey, 'season_lent_1_monday');
    });

    test('returns correct key for Triduum days', () {
      final holyThursday = LiturgicalCalendar.computeDay(DateTime(2026, 4, 2));
      expect(holyThursday.lectionaryKey, 'triduum_holy_thursday');

      final goodFriday = LiturgicalCalendar.computeDay(DateTime(2026, 4, 3));
      expect(goodFriday.lectionaryKey, 'triduum_good_friday');
    });

    test('returns correct key for Easter season weekdays and Sundays', () {
      // Easter Sunday 2026 (Apr 5) → special 'season_easter_sunday' key
      final easter = LiturgicalCalendar.computeDay(DateTime(2026, 4, 5));
      expect(easter.lectionaryKey, 'season_easter_sunday');

      // Apr 12, 2026 is 7 days after Easter (still within the Octave, days < 8
      // is false for days==7; weekName has no ordinal so week defaults to 1).
      final octaveSunday = LiturgicalCalendar.computeDay(DateTime(2026, 4, 12));
      expect(octaveSunday.season, LiturgicalSeason.easter);
      expect(octaveSunday.lectionaryKey, 'season_easter_1_sunday_a');

      // Apr 13, 2026 is Monday of the 2nd Week of Easter
      final mon = LiturgicalCalendar.computeDay(DateTime(2026, 4, 13));
      expect(mon.season, LiturgicalSeason.easter);
      expect(mon.lectionaryKey, 'season_easter_2_monday');
    });

    test(
      'returns correct key for Ordinary Time Sundays and weekdays across cycles',
      () {
        // Jul 5, 2026 is 14th Sunday in Ordinary Time, Year A
        final sun = LiturgicalCalendar.computeDay(DateTime(2026, 7, 5));
        expect(sun.season, LiturgicalSeason.ordinaryTime);
        expect(sun.lectionaryKey, 'season_ordinary_time_14_sunday_a');

        // Jul 6, 2026 is Monday of 14th Week in Ordinary Time, Weekday Cycle II
        final mon = LiturgicalCalendar.computeDay(DateTime(2026, 7, 6));
        expect(mon.weekdayCycle, 'II');
        expect(mon.lectionaryKey, startsWith('season_ordinary_time_'));
        expect(mon.lectionaryKey, endsWith('_2'));
      },
    );

    test('lectionaryKey returns the correct value for every day of the week '
        'in Advent Week 2 (verifying _daysOfWeek indexing)', () {
      // Dec 7-12, 2026 spans all 6 weekdays of Advent Week 2.
      final expected = {
        DateTime(2026, 12, 7): 'season_advent_2_monday',
        DateTime(2026, 12, 8): 'feast_immaculate_conception', // fixed feast
        DateTime(2026, 12, 9): 'season_advent_2_wednesday',
        DateTime(2026, 12, 10): 'season_advent_2_thursday',
        DateTime(2026, 12, 11): 'season_advent_2_friday',
        DateTime(2026, 12, 12): 'season_advent_2_saturday',
      };
      for (final entry in expected.entries) {
        final day = LiturgicalCalendar.computeDay(entry.key);
        expect(
          day.lectionaryKey,
          entry.value,
          reason: 'Failed for ${entry.key}',
        );
      }
    });
  });
}
