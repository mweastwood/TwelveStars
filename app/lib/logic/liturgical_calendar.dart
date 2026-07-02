import 'package:flutter/material.dart';

enum LiturgicalSeason { advent, christmas, lent, triduum, easter, ordinaryTime }

enum LiturgicalColor { green, purple, white, red, rose }

class LiturgicalDay {
  final DateTime date;
  final LiturgicalSeason season;
  final LiturgicalColor color;
  final String? name; // Feast/Solemnity name
  final String
  weekName; // e.g. "2nd Sunday of Advent", "15th Week in Ordinary Time"
  final String sundayCycle; // A, B, or C
  final String weekdayCycle; // I or II

  const LiturgicalDay({
    required this.date,
    required this.season,
    required this.color,
    this.name,
    required this.weekName,
    required this.sundayCycle,
    required this.weekdayCycle,
  });

  String get seasonName {
    switch (season) {
      case LiturgicalSeason.advent:
        return 'Advent';
      case LiturgicalSeason.christmas:
        return 'Christmas';
      case LiturgicalSeason.lent:
        return 'Lent';
      case LiturgicalSeason.triduum:
        return 'Sacred Paschal Triduum';
      case LiturgicalSeason.easter:
        return 'Easter Season';
      case LiturgicalSeason.ordinaryTime:
        return 'Ordinary Time';
    }
  }

  Color get colorWidget {
    switch (color) {
      case LiturgicalColor.green:
        return const Color(0xFF2E7D32);
      case LiturgicalColor.purple:
        return const Color(0xFF6A1B9A);
      case LiturgicalColor.white:
        return const Color(0xFFE6B800); // Liturgical Gold/White
      case LiturgicalColor.red:
        return const Color(0xFFC62828);
      case LiturgicalColor.rose:
        return const Color(0xFFD81B60);
    }
  }

  String get colorName {
    switch (color) {
      case LiturgicalColor.green:
        return 'Green';
      case LiturgicalColor.purple:
        return 'Violet';
      case LiturgicalColor.white:
        return 'White/Gold';
      case LiturgicalColor.red:
        return 'Red';
      case LiturgicalColor.rose:
        return 'Rose';
    }
  }
}

class LiturgicalCalendar {
  // Butcher's Gregorian Easter Computus Algorithm
  static DateTime calculateEaster(int year) {
    final int a = year % 19;
    final int b = year ~/ 100;
    final int c = year % 100;
    final int d = b ~/ 4;
    final int e = b % 4;
    final int f = (b + 8) ~/ 25;
    final int g = (b - f + 1) ~/ 3;
    final int h = (19 * a + b - d - g + 15) % 30;
    final int i = c ~/ 4;
    final int k = c % 4;
    final int l = (32 + 2 * e + 2 * i - h - k) % 7;
    final int m = (a + 11 * h + 22 * l) ~/ 451;
    final int month = (h + l - 7 * m + 114) ~/ 31;
    final int day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  // 1st Sunday of Advent is the Sunday on or between Nov 27 and Dec 3
  static DateTime getFirstSundayOfAdvent(int year) {
    final nov30 = DateTime(year, 11, 30);
    final weekday = nov30.weekday;
    int offset = 0;
    if (weekday <= 3) {
      offset = -weekday; // go back to Sunday
    } else if (weekday == 7) {
      offset = 0;
    } else {
      offset = 7 - weekday; // go forward to Sunday
    }
    return nov30.add(Duration(days: offset));
  }

  static DateTime getEpiphany(int year) {
    // Sunday between Jan 2 and Jan 8
    for (int d = 2; d <= 8; d++) {
      final date = DateTime(year, 1, d);
      if (date.weekday == DateTime.sunday) {
        return date;
      }
    }
    return DateTime(year, 1, 6);
  }

  static DateTime getBaptismOfTheLord(int year) {
    final epiphany = getEpiphany(year);
    // If Epiphany is on Jan 7 or Jan 8, Baptism is the next day (Monday)
    if (epiphany.day == 7 || epiphany.day == 8) {
      return epiphany.add(const Duration(days: 1));
    }
    // Otherwise, it is the Sunday after Epiphany
    return epiphany.add(const Duration(days: 7));
  }

  static String getOrdinalSuffix(int num) {
    if (num >= 11 && num <= 13) return 'th';
    switch (num % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  static String getDayOfWeekName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  static String calculateSundayCycle(
    int year,
    DateTime date,
    DateTime adventStart,
  ) {
    // Sunday cycle changes on the 1st Sunday of Advent
    int activeYear = year;
    if (date.isBefore(adventStart)) {
      activeYear = year - 1;
    }
    // Year 2020 was cycle A (starts Dec 2019)
    final remainder = (activeYear - 2019) % 3;
    switch (remainder) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      default:
        return 'A';
    }
  }

  static String calculateWeekdayCycle(
    int year,
    DateTime date,
    DateTime adventStart,
  ) {
    // Weekday cycle changes on the 1st Sunday of Advent
    int activeYear = year;
    if (date.isBefore(adventStart)) {
      activeYear = year - 1;
    }
    final liturgicalYear = activeYear + 1;
    return liturgicalYear % 2 == 1 ? 'I' : 'II';
  }

  static LiturgicalDay computeDay(DateTime date) {
    // Normalize date to midnight to prevent timezone issues
    final localDate = DateTime(date.year, date.month, date.day);
    final year = localDate.year;

    // We calculate anchor dates for the current calendar year
    final easter = calculateEaster(year);
    final advent = getFirstSundayOfAdvent(year);
    final baptism = getBaptismOfTheLord(year);

    // Determine the active liturgical year anchors
    final DateTime activeAdventStart;
    final DateTime activeChristmas;
    final DateTime activeEaster;
    final DateTime activeBaptism;

    if (localDate.isBefore(advent)) {
      // Liturgical year started last calendar year
      activeAdventStart = getFirstSundayOfAdvent(year - 1);
      activeChristmas = DateTime(year - 1, 12, 25);
      activeEaster = easter;
      activeBaptism = baptism;
    } else {
      // Liturgical year starts this calendar year
      activeAdventStart = advent;
      activeChristmas = DateTime(year, 12, 25);
      activeEaster = calculateEaster(year + 1);
      activeBaptism = getBaptismOfTheLord(year + 1);
    }

    final sundayCycle = calculateSundayCycle(year, localDate, advent);
    final weekdayCycle = calculateWeekdayCycle(year, localDate, advent);

    // Movable Feasts relative to activeEaster
    final ashWednesday = activeEaster.subtract(const Duration(days: 46));
    final holyThursday = activeEaster.subtract(const Duration(days: 3));
    final goodFriday = activeEaster.subtract(const Duration(days: 2));
    final pentecost = activeEaster.add(const Duration(days: 49));
    final trinitySunday = activeEaster.add(const Duration(days: 56));
    final corpusChristi = activeEaster.add(
      const Duration(days: 63),
    ); // Sunday transfer
    final sacredHeart = activeEaster.add(
      const Duration(days: 68),
    ); // Friday after 2nd Sunday after Pentecost
    final christTheKing = activeAdventStart.subtract(const Duration(days: 7));

    // Seasons checks
    LiturgicalSeason season;
    LiturgicalColor color;
    String? name;
    String weekName = '';

    if (localDate.isBefore(ashWednesday)) {
      if (localDate.isBefore(activeChristmas)) {
        // --- ADVENT ---
        season = LiturgicalSeason.advent;
        color = LiturgicalColor.purple;
        final days = localDate.difference(activeAdventStart).inDays;
        final week = (days ~/ 7) + 1;
        if (localDate.weekday == DateTime.sunday) {
          if (week == 3) {
            color = LiturgicalColor.rose; // Gaudete Sunday
            weekName = '3rd Sunday of Advent (Gaudete Sunday)';
          } else {
            weekName = '$week${getOrdinalSuffix(week)} Sunday of Advent';
          }
        } else {
          weekName =
              '${getDayOfWeekName(localDate.weekday)} of the $week${getOrdinalSuffix(week)} Week of Advent';
        }
      } else if (localDate.isBefore(activeBaptism) ||
          localDate.isAtSameMomentAs(activeBaptism)) {
        // --- CHRISTMAS ---
        season = LiturgicalSeason.christmas;
        color = LiturgicalColor.white;
        if (localDate.month == 12 && localDate.day == 25) {
          name = 'The Nativity of the Lord (Christmas)';
          weekName = 'Solemnity of Christmas';
        } else if (localDate.month == 1 && localDate.day == 1) {
          name = 'Mary, the Holy Mother of God';
          weekName = 'Solemnity of Mary, Mother of God';
        } else if (localDate.isAtSameMomentAs(getEpiphany(localDate.year))) {
          name = 'The Epiphany of the Lord';
          weekName = 'Solemnity of the Epiphany';
        } else if (localDate.isAtSameMomentAs(activeBaptism)) {
          name = 'The Baptism of the Lord';
          weekName = 'Feast of the Baptism of the Lord';
        } else {
          // Check for Holy Family (Sunday in the Octave of Christmas, or Dec 30 if Christmas is Sunday)
          final dec25 = DateTime(
            localDate.year == 12 ? localDate.year : localDate.year - 1,
            12,
            25,
          );
          final holyFamilySunday = dec25.add(
            Duration(days: 7 - dec25.weekday % 7),
          );
          if (localDate.isAtSameMomentAs(holyFamilySunday)) {
            name = 'The Holy Family of Jesus, Mary and Joseph';
            weekName = 'Feast of the Holy Family';
          } else {
            weekName = 'Weekday in Christmas Season';
          }
        }
      } else {
        // --- ORDINARY TIME (PART 1) ---
        season = LiturgicalSeason.ordinaryTime;
        color = LiturgicalColor.green;
        final days = localDate.difference(activeBaptism).inDays;
        final week = (days ~/ 7) + 1;
        if (localDate.weekday == DateTime.sunday) {
          weekName = '$week${getOrdinalSuffix(week)} Sunday in Ordinary Time';
        } else {
          weekName =
              '${getDayOfWeekName(localDate.weekday)} of the $week${getOrdinalSuffix(week)} Week in Ordinary Time';
        }
      }
    } else if (localDate.isBefore(holyThursday)) {
      // --- LENT ---
      season = LiturgicalSeason.lent;
      color = LiturgicalColor.purple;
      final days = localDate.difference(ashWednesday).inDays;
      if (days == 0) {
        name = 'Ash Wednesday';
        weekName = 'Ash Wednesday';
      } else if (days < 4) {
        weekName = '${getDayOfWeekName(localDate.weekday)} after Ash Wednesday';
      } else {
        final week = ((days - 4) ~/ 7) + 1;
        if (localDate.weekday == DateTime.sunday) {
          if (week == 4) {
            color = LiturgicalColor.rose; // Laetare Sunday
            weekName = '4th Sunday of Lent (Laetare Sunday)';
          } else if (week == 6) {
            name = 'Palm Sunday of the Passion of the Lord';
            color = LiturgicalColor.red;
            weekName = 'Palm Sunday';
          } else {
            weekName = '$week${getOrdinalSuffix(week)} Sunday of Lent';
          }
        } else {
          if (week == 6) {
            weekName = '${getDayOfWeekName(localDate.weekday)} of Holy Week';
          } else {
            weekName =
                '${getDayOfWeekName(localDate.weekday)} of the $week${getOrdinalSuffix(week)} Week of Lent';
          }
        }
      }
    } else if (localDate.isBefore(activeEaster)) {
      // --- TRIDUUM ---
      season = LiturgicalSeason.triduum;
      if (localDate.isAtSameMomentAs(holyThursday)) {
        name = 'Holy Thursday (Evening Mass of the Lord\'s Supper)';
        color = LiturgicalColor.white;
        weekName = 'Holy Thursday';
      } else if (localDate.isAtSameMomentAs(goodFriday)) {
        name = 'Good Friday (Celebration of the Passion of the Lord)';
        color = LiturgicalColor.red;
        weekName = 'Good Friday';
      } else {
        name = 'Holy Saturday (Easter Vigil)';
        color = LiturgicalColor.white;
        weekName = 'Holy Saturday';
      }
    } else if (localDate.isBefore(pentecost) ||
        localDate.isAtSameMomentAs(pentecost)) {
      // --- EASTER SEASON ---
      season = LiturgicalSeason.easter;
      color = LiturgicalColor.white;
      final days = localDate.difference(activeEaster).inDays;
      if (days == 0) {
        name = 'Easter Sunday of the Resurrection of the Lord';
        weekName = 'Easter Sunday';
      } else if (days < 8) {
        weekName =
            '${getDayOfWeekName(localDate.weekday)} in the Octave of Easter';
      } else {
        final week = (days ~/ 7) + 1;
        if (localDate.weekday == DateTime.sunday) {
          if (localDate.isAtSameMomentAs(pentecost)) {
            name = 'Pentecost Sunday';
            color = LiturgicalColor.red;
            weekName = 'Pentecost Sunday';
          } else {
            weekName = '$week${getOrdinalSuffix(week)} Sunday of Easter';
          }
        } else {
          weekName =
              '${getDayOfWeekName(localDate.weekday)} of the $week${getOrdinalSuffix(week)} Week of Easter';
        }
      }
    } else {
      // --- ORDINARY TIME (PART 2) ---
      season = LiturgicalSeason.ordinaryTime;
      color = LiturgicalColor.green;

      // Calculate week number working backwards from next Advent
      final nextAdvent = localDate.isBefore(advent)
          ? advent
          : getFirstSundayOfAdvent(year + 1);
      final sundayOfContainingWeek = localDate.subtract(
        Duration(days: localDate.weekday % 7),
      );
      final weeksFromAdvent =
          nextAdvent.difference(sundayOfContainingWeek).inDays ~/ 7;
      final week = 35 - weeksFromAdvent;

      if (localDate.weekday == DateTime.sunday) {
        weekName = '$week${getOrdinalSuffix(week)} Sunday in Ordinary Time';
      } else {
        weekName =
            '${getDayOfWeekName(localDate.weekday)} of the $week${getOrdinalSuffix(week)} Week in Ordinary Time';
      }

      // Check movable solemnities falling in this period
      if (localDate.isAtSameMomentAs(trinitySunday)) {
        name = 'The Most Holy Trinity';
        color = LiturgicalColor.white;
        weekName = 'Solemnity of the Most Holy Trinity';
      } else if (localDate.isAtSameMomentAs(corpusChristi)) {
        name = 'The Most Holy Body and Blood of Christ (Corpus Christi)';
        color = LiturgicalColor.white;
        weekName = 'Solemnity of Corpus Christi';
      } else if (localDate.isAtSameMomentAs(sacredHeart)) {
        name = 'The Most Sacred Heart of Jesus';
        color = LiturgicalColor.white;
        weekName = 'Solemnity of the Most Sacred Heart of Jesus';
      } else if (localDate.isAtSameMomentAs(christTheKing)) {
        name = 'Our Lord Jesus Christ, King of the Universe';
        color = LiturgicalColor.white;
        weekName = 'Solemnity of Christ the King';
      }
    }

    // Check fixed solemnities (only if it hasn't been set by movable feasts already)
    if (name == null) {
      if (localDate.month == 3 && localDate.day == 19) {
        name = 'St. Joseph, Spouse of the Blessed Virgin Mary';
        color = LiturgicalColor.white;
      } else if (localDate.month == 3 && localDate.day == 25) {
        name = 'The Annunciation of the Lord';
        color = LiturgicalColor.white;
      } else if (localDate.month == 6 && localDate.day == 24) {
        name = 'Nativity of St. John the Baptist';
        color = LiturgicalColor.white;
      } else if (localDate.month == 6 && localDate.day == 29) {
        name = 'Sts. Peter and Paul, Apostles';
        color = LiturgicalColor.red;
      } else if (localDate.month == 8 && localDate.day == 15) {
        name = 'The Assumption of the Blessed Virgin Mary';
        color = LiturgicalColor.white;
      } else if (localDate.month == 11 && localDate.day == 1) {
        name = 'All Saints';
        color = LiturgicalColor.white;
      } else if (localDate.month == 12 && localDate.day == 8) {
        name = 'The Immaculate Conception of the Blessed Virgin Mary';
        color = LiturgicalColor.white;
      }
    }

    return LiturgicalDay(
      date: localDate,
      season: season,
      color: color,
      name: name,
      weekName: weekName,
      sundayCycle: sundayCycle,
      weekdayCycle: weekdayCycle,
    );
  }
}
