import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';

void main() {
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

      // Jan 1, 2026: Mary, Mother of God
      final motherOfGod = LiturgicalCalendar.computeDay(DateTime(2026, 1, 1));
      expect(motherOfGod.season, LiturgicalSeason.christmas);
      expect(motherOfGod.color, LiturgicalColor.white);
      expect(motherOfGod.name, 'Mary, the Holy Mother of God');
    });

    test('verifies Lent Season & Triduum', () {
      // Ash Wednesday 2026: Feb 18 (since Easter is April 5, 5 - 46 days = Feb 18)
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
  });
}
