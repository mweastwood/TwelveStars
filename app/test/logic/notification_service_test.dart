import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/logic/prayers.dart';

class MockFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  bool isInitialized = false;
  InitializationSettings? capturedSettings;
  int? cancelledId;
  bool cancelCalled = false;

  int? scheduledId;
  String? scheduledTitle;
  String? scheduledBody;
  tz.TZDateTime? scheduledDate;
  NotificationDetails? scheduledNotificationDetails;
  AndroidScheduleMode? scheduledAndroidScheduleMode;

  bool shouldFailExactSchedule = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    isInitialized = true;
    capturedSettings = settings;
    return true;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelCalled = true;
    cancelledId = id;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    bool uiLocalNotificationDateInterpretation = true,
  }) async {
    if (shouldFailExactSchedule &&
        androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
      throw Exception('Exact alarm permission denied');
    }
    scheduledId = id;
    scheduledTitle = title;
    scheduledBody = body;
    this.scheduledDate = scheduledDate;
    scheduledNotificationDetails = notificationDetails;
    scheduledAndroidScheduleMode = androidScheduleMode;
  }
}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    NotificationService.mockPlugin = mockPlugin;
    NotificationService.isInitialized = false;
  });

  tearDown(() {
    NotificationService.mockPlugin = null;
    NotificationService.isInitialized = false;
  });

  group('NotificationService Logic Tests', () {
    group('nextSunday8AM', () {
      test('schedules next Sunday from a non-Sunday day (Monday)', () {
        final monday = DateTime(2026, 7, 6, 14, 30); // Monday
        final nextSunday = NotificationService.nextSunday8AM(monday);

        expect(nextSunday.year, equals(2026));
        expect(nextSunday.month, equals(7));
        expect(nextSunday.day, equals(12)); // Sunday July 12
        expect(nextSunday.hour, equals(8));
        expect(nextSunday.minute, equals(0));
        expect(nextSunday.second, equals(0));
      });

      test('schedules today at 8:00 AM on Sunday before 8:00 AM', () {
        final sundayBefore8 = DateTime(2026, 7, 12, 7, 59, 59);
        final nextSunday = NotificationService.nextSunday8AM(sundayBefore8);

        expect(nextSunday.year, equals(2026));
        expect(nextSunday.month, equals(7));
        expect(nextSunday.day, equals(12)); // Today July 12
        expect(nextSunday.hour, equals(8));
        expect(nextSunday.minute, equals(0));
        expect(nextSunday.second, equals(0));
      });

      test('schedules next Sunday on Sunday at exactly 8:00:00 AM', () {
        final sundayAt8 = DateTime(2026, 7, 12, 8, 0, 0);
        final nextSunday = NotificationService.nextSunday8AM(sundayAt8);

        expect(nextSunday.year, equals(2026));
        expect(nextSunday.month, equals(7));
        expect(nextSunday.day, equals(19)); // Next Sunday July 19
        expect(nextSunday.hour, equals(8));
        expect(nextSunday.minute, equals(0));
        expect(nextSunday.second, equals(0));
      });

      test(
        'schedules next Sunday on Sunday at 8:00 AM with non-zero seconds',
        () {
          final sundayAt8WithSec = DateTime(2026, 7, 12, 8, 0, 30);
          final nextSunday = NotificationService.nextSunday8AM(
            sundayAt8WithSec,
          );

          expect(nextSunday.year, equals(2026));
          expect(nextSunday.month, equals(7));
          expect(nextSunday.day, equals(19)); // Next Sunday July 19
          expect(nextSunday.hour, equals(8));
          expect(nextSunday.minute, equals(0));
          expect(nextSunday.second, equals(0));
        },
      );

      test(
        'schedules next Sunday on Sunday at 8:00 AM with non-zero milliseconds',
        () {
          final sundayAt8WithMillis = DateTime(2026, 7, 12, 8, 0, 0, 500);
          final nextSunday = NotificationService.nextSunday8AM(
            sundayAt8WithMillis,
          );

          expect(nextSunday.year, equals(2026));
          expect(nextSunday.month, equals(7));
          expect(nextSunday.day, equals(19)); // Next Sunday July 19
          expect(nextSunday.hour, equals(8));
          expect(nextSunday.minute, equals(0));
          expect(nextSunday.second, equals(0));
        },
      );
    });

    test('evaluates liturgical season & color for Sunday notification', () {
      final easterSunday = DateTime(2026, 4, 5);
      final nextSunday = NotificationService.nextSunday8AM(easterSunday);
      final day = LiturgicalCalendar.computeDay(nextSunday);

      expect(day.season, equals(LiturgicalSeason.easter));
      expect(day.color, equals(LiturgicalColor.white));
    });

    test(
      'initializes and cancels notification when Sunday notifications disabled',
      () async {
        final settings = UserSettings(sundayNotificationsEnabled: false);

        await NotificationService.syncSundayNotification(settings);

        expect(mockPlugin.isInitialized, isTrue);
        expect(mockPlugin.cancelCalled, isTrue);
        expect(mockPlugin.cancelledId, equals(1001));
        expect(mockPlugin.scheduledId, isNull);
      },
    );

    test(
      'initializes and schedules notification when Sunday notifications enabled',
      () async {
        final settings = UserSettings(sundayNotificationsEnabled: true);

        await NotificationService.syncSundayNotification(settings);

        expect(mockPlugin.isInitialized, isTrue);
        expect(mockPlugin.cancelCalled, isFalse);
        expect(mockPlugin.scheduledId, equals(1001));
        expect(mockPlugin.scheduledTitle, contains('Liturgical Season:'));
        expect(
          mockPlugin.scheduledAndroidScheduleMode,
          equals(AndroidScheduleMode.exactAllowWhileIdle),
        );
      },
    );

    test('falls back to inexact schedule when exact schedule fails', () async {
      final settings = UserSettings(sundayNotificationsEnabled: true);
      mockPlugin.shouldFailExactSchedule = true;

      await NotificationService.syncSundayNotification(settings);

      expect(mockPlugin.isInitialized, isTrue);
      expect(mockPlugin.scheduledId, equals(1001));
      expect(
        mockPlugin.scheduledAndroidScheduleMode,
        equals(AndroidScheduleMode.inexact),
      );
    });
  });
}
