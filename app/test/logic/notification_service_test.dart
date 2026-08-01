import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/notification_service.dart';

void main() {
  group('NotificationService Logic Tests', () {
    test('calculates next Sunday at 8:00 AM accurately', () {
      final monday = DateTime(2026, 7, 6); // Monday
      final nextSunday = NotificationService.nextSunday8AM(monday);

      expect(nextSunday.year, equals(2026));
      expect(nextSunday.month, equals(7));
      expect(nextSunday.day, equals(12)); // Sunday July 12
      expect(nextSunday.hour, equals(8));
      expect(nextSunday.minute, equals(0));
    });

    test('evaluates liturgical season & color for Sunday notification', () {
      final easterSunday = DateTime(2026, 4, 5);
      final nextSunday = NotificationService.nextSunday8AM(easterSunday);
      final day = LiturgicalCalendar.computeDay(nextSunday);

      expect(day.season, equals(LiturgicalSeason.easter));
      expect(day.color, equals(LiturgicalColor.white));
    });
  });
}
