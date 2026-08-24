import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/logic/prayers.dart';

class ScheduledNotificationRecord {
  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails notificationDetails;
  final AndroidScheduleMode androidScheduleMode;
  final DateTimeComponents? matchDateTimeComponents;

  ScheduledNotificationRecord({
    required this.id,
    this.title,
    this.body,
    required this.scheduledDate,
    required this.notificationDetails,
    required this.androidScheduleMode,
    this.matchDateTimeComponents,
  });
}

class MockFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  bool isInitialized = false;
  InitializationSettings? capturedSettings;
  final List<int> cancelledIds = [];
  final List<ScheduledNotificationRecord> scheduledList = [];

  bool get cancelCalled => cancelledIds.isNotEmpty;
  int? get cancelledId => cancelledIds.isNotEmpty ? cancelledIds.last : null;

  int? get scheduledId =>
      scheduledList.isNotEmpty ? scheduledList.last.id : null;
  String? get scheduledTitle =>
      scheduledList.isNotEmpty ? scheduledList.last.title : null;
  String? get scheduledBody =>
      scheduledList.isNotEmpty ? scheduledList.last.body : null;
  tz.TZDateTime? get scheduledDate =>
      scheduledList.isNotEmpty ? scheduledList.last.scheduledDate : null;
  NotificationDetails? get scheduledNotificationDetails =>
      scheduledList.isNotEmpty ? scheduledList.last.notificationDetails : null;
  AndroidScheduleMode? get scheduledAndroidScheduleMode =>
      scheduledList.isNotEmpty ? scheduledList.last.androidScheduleMode : null;

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
    cancelledIds.add(id);
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
    scheduledList.add(
      ScheduledNotificationRecord(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      ),
    );
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
    });

    group('nextDailyTime', () {
      test('schedules today if target time is in the future', () {
        final morning = DateTime(2026, 8, 24, 9, 30);
        final target = NotificationService.nextDailyTime(12, 0, morning);

        expect(target.year, equals(2026));
        expect(target.month, equals(8));
        expect(target.day, equals(24));
        expect(target.hour, equals(12));
        expect(target.minute, equals(0));
      });

      test('schedules tomorrow if target time has already passed today', () {
        final afternoon = DateTime(2026, 8, 24, 14, 30);
        final target = NotificationService.nextDailyTime(12, 0, afternoon);

        expect(target.year, equals(2026));
        expect(target.month, equals(8));
        expect(target.day, equals(25));
        expect(target.hour, equals(12));
        expect(target.minute, equals(0));
      });

      test('schedules tomorrow if target time is exactly now', () {
        final exact = DateTime(2026, 8, 24, 12, 0, 0);
        final target = NotificationService.nextDailyTime(12, 0, exact);

        expect(target.day, equals(25));
        expect(target.hour, equals(12));
        expect(target.minute, equals(0));
      });
    });

    group('Content Generators', () {
      test('computeAngelusContent returns Regina Caeli during Easter', () {
        final easterDate = DateTime(2026, 4, 15);
        final (title, body) = NotificationService.computeAngelusContent(
          easterDate,
        );

        expect(title, equals('Regina Caeli'));
        expect(body, contains('Queen of Heaven, rejoice'));
      });

      test('computeAngelusContent returns The Angelus outside Easter', () {
        final ordinaryDate = DateTime(2026, 8, 24);
        final (title, body) = NotificationService.computeAngelusContent(
          ordinaryDate,
        );

        expect(title, equals('The Angelus'));
        expect(body, contains('The Angel of the Lord declared unto Mary'));
      });

      test('computeRosaryContent returns correct mystery for day of week', () {
        final monday = DateTime(2026, 8, 24); // Monday -> Joyful
        final tuesday = DateTime(2026, 8, 25); // Tuesday -> Sorrowful
        final wednesday = DateTime(2026, 8, 26); // Wednesday -> Glorious
        final thursday = DateTime(2026, 8, 27); // Thursday -> Luminous

        final (titleMon, bodyMon) = NotificationService.computeRosaryContent(
          monday,
        );
        expect(titleMon, equals('Daily Rosary'));
        expect(bodyMon, contains('Joyful Mysteries'));

        final (_, bodyTue) = NotificationService.computeRosaryContent(tuesday);
        expect(bodyTue, contains('Sorrowful Mysteries'));

        final (_, bodyWed) = NotificationService.computeRosaryContent(
          wednesday,
        );
        expect(bodyWed, contains('Glorious Mysteries'));

        final (_, bodyThu) = NotificationService.computeRosaryContent(thursday);
        expect(bodyThu, contains('Luminous Mysteries'));
      });

      test('computeMorningPrayerContent and computeNightPrayerContent', () {
        final date = DateTime(2026, 8, 24);
        final (mTitle, mBody) = NotificationService.computeMorningPrayerContent(
          date,
        );
        expect(mTitle, equals('Morning Prayer'));
        expect(mBody, contains('open my lips'));

        final (nTitle, nBody) = NotificationService.computeNightPrayerContent(
          date,
        );
        expect(nTitle, equals('Night Prayer (Compline)'));
        expect(nBody, contains('commend my spirit'));
      });
    });

    group('Sunday Notification', () {
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
          expect(mockPlugin.cancelledIds, contains(1001));
        },
      );

      test(
        'initializes and schedules notification when Sunday notifications enabled',
        () async {
          final settings = UserSettings(sundayNotificationsEnabled: true);

          await NotificationService.syncSundayNotification(settings);

          expect(mockPlugin.isInitialized, isTrue);
          expect(mockPlugin.scheduledId, equals(1001));
          expect(mockPlugin.scheduledTitle, contains('Liturgical Season:'));
          expect(
            mockPlugin.scheduledAndroidScheduleMode,
            equals(AndroidScheduleMode.exactAllowWhileIdle),
          );
        },
      );
    });

    group('Angelus Notifications', () {
      test('schedules selected times when angelus enabled', () async {
        final settings = UserSettings(
          angelusReminderEnabled: true,
          angelusMorningEnabled: true,
          angelusMiddayEnabled: true,
          angelusEveningEnabled: false,
        );

        await NotificationService.syncAngelusNotifications(settings);

        final scheduledIds = mockPlugin.scheduledList.map((e) => e.id).toList();
        expect(
          scheduledIds,
          contains(NotificationService.kAngelusMorningNotificationId),
        );
        expect(
          scheduledIds,
          contains(NotificationService.kAngelusMiddayNotificationId),
        );
        expect(
          scheduledIds,
          isNot(contains(NotificationService.kAngelusEveningNotificationId)),
        );
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusEveningNotificationId),
        );
      });

      test('cancels all angelus notifications when disabled', () async {
        final settings = UserSettings(angelusReminderEnabled: false);

        await NotificationService.syncAngelusNotifications(settings);

        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusMorningNotificationId),
        );
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusMiddayNotificationId),
        );
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusEveningNotificationId),
        );
      });
    });

    group('Rosary Notification', () {
      test('schedules rosary at custom hour and minute', () async {
        final settings = UserSettings(
          rosaryReminderEnabled: true,
          rosaryReminderHour: 19,
          rosaryReminderMinute: 45,
        );

        await NotificationService.syncRosaryNotification(settings);

        expect(
          mockPlugin.scheduledId,
          equals(NotificationService.kRosaryNotificationId),
        );
        expect(mockPlugin.scheduledTitle, equals('Daily Rosary'));
        expect(
          mockPlugin.scheduledList.last.matchDateTimeComponents,
          equals(DateTimeComponents.time),
        );
      });

      test('cancels rosary notification when disabled', () async {
        final settings = UserSettings(rosaryReminderEnabled: false);

        await NotificationService.syncRosaryNotification(settings);

        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kRosaryNotificationId),
        );
      });
    });

    group('Morning and Night Prayer Notifications', () {
      test('schedules morning and night prayers when enabled', () async {
        final settings = UserSettings(
          morningPrayerReminderEnabled: true,
          morningPrayerReminderHour: 6,
          morningPrayerReminderMinute: 30,
          nightPrayerReminderEnabled: true,
          nightPrayerReminderHour: 22,
          nightPrayerReminderMinute: 0,
        );

        await NotificationService.syncMorningPrayerNotification(settings);
        await NotificationService.syncNightPrayerNotification(settings);

        final scheduledIds = mockPlugin.scheduledList.map((e) => e.id).toList();
        expect(
          scheduledIds,
          contains(NotificationService.kMorningPrayerNotificationId),
        );
        expect(
          scheduledIds,
          contains(NotificationService.kNightPrayerNotificationId),
        );
      });
    });

    group('syncAllNotifications', () {
      test('synchronizes all configured reminders simultaneously', () async {
        final settings = UserSettings(
          sundayNotificationsEnabled: true,
          angelusReminderEnabled: true,
          angelusMiddayEnabled: true,
          rosaryReminderEnabled: true,
          morningPrayerReminderEnabled: false,
          nightPrayerReminderEnabled: false,
        );

        await NotificationService.syncAllNotifications(settings);

        final scheduledIds = mockPlugin.scheduledList.map((e) => e.id).toSet();
        expect(scheduledIds, contains(1001));
        expect(
          scheduledIds,
          contains(NotificationService.kAngelusMiddayNotificationId),
        );
        expect(
          scheduledIds,
          contains(NotificationService.kRosaryNotificationId),
        );
      });
    });
  });
}
