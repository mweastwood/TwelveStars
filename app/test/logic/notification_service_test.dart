import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/main.dart';

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
    NotificationService.syncAllCallCount = 0;
  });

  tearDown(() {
    NotificationService.mockPlugin = null;
    NotificationService.isInitialized = false;
    NotificationService.syncAllCallCount = 0;
    PrayerDatabase.mockSettings = null;
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

    group('nextWeekdayTime', () {
      test(
        'schedules today if target weekday is today and time is in future',
        () {
          final mondayMorning = DateTime(2026, 8, 24, 9, 30); // Monday
          final target = NotificationService.nextWeekdayTime(
            DateTime.monday,
            19,
            0,
            mondayMorning,
          );

          expect(target.year, equals(2026));
          expect(target.month, equals(8));
          expect(target.day, equals(24));
          expect(target.hour, equals(19));
          expect(target.minute, equals(0));
          expect(target.weekday, equals(DateTime.monday));
        },
      );

      test(
        'schedules next week if target weekday is today and time has passed',
        () {
          final mondayNight = DateTime(2026, 8, 24, 21, 30); // Monday
          final target = NotificationService.nextWeekdayTime(
            DateTime.monday,
            19,
            0,
            mondayNight,
          );

          expect(target.year, equals(2026));
          expect(target.month, equals(8));
          expect(target.day, equals(31)); // Monday next week
          expect(target.hour, equals(19));
          expect(target.minute, equals(0));
          expect(target.weekday, equals(DateTime.monday));
        },
      );

      test(
        'schedules correct date when target weekday is in the upcoming days',
        () {
          final monday = DateTime(2026, 8, 24, 10, 0); // Monday (weekday 1)
          final target = NotificationService.nextWeekdayTime(
            DateTime.friday, // Friday (weekday 5)
            12,
            0,
            monday,
          );

          expect(target.year, equals(2026));
          expect(target.month, equals(8));
          expect(target.day, equals(28)); // Friday Aug 28
          expect(target.hour, equals(12));
          expect(target.minute, equals(0));
          expect(target.weekday, equals(DateTime.friday));
        },
      );
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
        'initializes and cancels notifications when Sunday notifications disabled',
        () async {
          final settings = UserSettings(sundayNotificationsEnabled: false);

          await NotificationService.syncSundayNotification(settings);

          expect(mockPlugin.isInitialized, isTrue);
          expect(mockPlugin.cancelCalled, isTrue);
          expect(
            mockPlugin.cancelledIds,
            contains(NotificationService.kSundayNotificationLegacyId),
          );
          for (int i = 0; i < NotificationService.kSundayRollingWeeks; i++) {
            expect(
              mockPlugin.cancelledIds,
              contains(NotificationService.kSundayNotificationBaseId + i),
            );
          }
        },
      );

      test(
        'initializes and schedules 6 rolling weekly instances when Sunday notifications enabled',
        () async {
          final settings = UserSettings(sundayNotificationsEnabled: true);
          final fromDate = DateTime(2026, 2, 20, 10, 0);

          await NotificationService.syncSundayNotification(settings, fromDate);

          expect(mockPlugin.isInitialized, isTrue);
          expect(
            mockPlugin.cancelledIds,
            contains(NotificationService.kSundayNotificationLegacyId),
          );
          expect(
            mockPlugin.scheduledList.length,
            equals(NotificationService.kSundayRollingWeeks),
          );

          for (int i = 0; i < NotificationService.kSundayRollingWeeks; i++) {
            final record = mockPlugin.scheduledList[i];
            expect(
              record.id,
              equals(NotificationService.kSundayNotificationBaseId + i),
            );
            expect(record.title, contains('Liturgical Season:'));
            expect(record.body, contains('Tap to view Mass readings & prayers'));
            expect(record.matchDateTimeComponents, isNull);
            expect(
              record.androidScheduleMode,
              equals(AndroidScheduleMode.exactAllowWhileIdle),
            );
          }
        },
      );

      test('falls back to inexact schedule when exact schedule throws', () async {
        mockPlugin.shouldFailExactSchedule = true;
        final settings = UserSettings(sundayNotificationsEnabled: true);

        await NotificationService.syncSundayNotification(settings);

        expect(
          mockPlugin.scheduledList.length,
          equals(NotificationService.kSundayRollingWeeks),
        );
        for (final record in mockPlugin.scheduledList) {
          expect(
            record.androidScheduleMode,
            equals(AndroidScheduleMode.inexact),
          );
        }
      });
    });

    group('Angelus Notifications', () {
      test('schedules 14 one-shot notifications per enabled slot and cancels legacy IDs', () async {
        final settings = UserSettings(
          angelusReminderEnabled: true,
          angelusMorningEnabled: true,
          angelusMiddayEnabled: true,
          angelusEveningEnabled: false,
        );

        await NotificationService.syncAngelusNotifications(settings);

        // Morning (14) + Midday (14) = 28 scheduled notifications
        expect(
          mockPlugin.scheduledList.length,
          equals(NotificationService.kAngelusRollingDays * 2),
        );

        final scheduledIds = mockPlugin.scheduledList.map((e) => e.id).toSet();
        for (int i = 0; i < NotificationService.kAngelusRollingDays; i++) {
          expect(
            scheduledIds,
            contains(NotificationService.kAngelusMorningBaseId + i),
          );
          expect(
            scheduledIds,
            contains(NotificationService.kAngelusMiddayBaseId + i),
          );
          expect(
            scheduledIds,
            isNot(contains(NotificationService.kAngelusEveningBaseId + i)),
          );
        }

        // Cancelled IDs include legacy IDs and disabled evening IDs
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusMorningLegacyId),
        );
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusMiddayLegacyId),
        );
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusEveningLegacyId),
        );
        for (int i = 0; i < NotificationService.kAngelusRollingDays; i++) {
          expect(
            mockPlugin.cancelledIds,
            contains(NotificationService.kAngelusEveningBaseId + i),
          );
        }

        // All Angelus instances are scheduled as one-shot notifications
        for (final record in mockPlugin.scheduledList) {
          expect(record.matchDateTimeComponents, isNull);
        }
      });

      test('switches from The Angelus to Regina Caeli across Easter boundary', () async {
        // Easter in 2026 is April 5.
        // Start 5 days before Easter: March 31, 2026 at 5:00 AM (before morning Angelus at 6:00 AM)
        final fromDate = DateTime(2026, 3, 31, 5, 0);
        final settings = UserSettings(
          angelusReminderEnabled: true,
          angelusMorningEnabled: true,
          angelusMiddayEnabled: false,
          angelusEveningEnabled: false,
        );

        await NotificationService.syncAngelusNotifications(settings, fromDate);

        expect(
          mockPlugin.scheduledList.length,
          equals(NotificationService.kAngelusRollingDays),
        );

        // Days 0..4 (March 31, April 1, 2, 3, 4) should be 'The Angelus'
        for (int dayOffset = 0; dayOffset < 5; dayOffset++) {
          final record = mockPlugin.scheduledList[dayOffset];
          expect(
            record.title,
            equals('The Angelus'),
            reason: 'dayOffset $dayOffset should be The Angelus',
          );
          expect(
            record.body,
            contains('The Angel of the Lord declared unto Mary'),
          );
        }

        // Days 5..13 (April 5 Easter Sunday onwards) should be 'Regina Caeli'
        for (int dayOffset = 5; dayOffset < 14; dayOffset++) {
          final record = mockPlugin.scheduledList[dayOffset];
          expect(
            record.title,
            equals('Regina Caeli'),
            reason: 'dayOffset $dayOffset should be Regina Caeli',
          );
          expect(record.body, contains('Queen of Heaven, rejoice'));
        }
      });

      test('cancels all angelus notifications and legacy IDs when disabled', () async {
        final settings = UserSettings(angelusReminderEnabled: false);

        await NotificationService.syncAngelusNotifications(settings);

        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusMorningLegacyId),
        );
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusMiddayLegacyId),
        );
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kAngelusEveningLegacyId),
        );

        for (int i = 0; i < NotificationService.kAngelusRollingDays; i++) {
          expect(
            mockPlugin.cancelledIds,
            contains(NotificationService.kAngelusMorningBaseId + i),
          );
          expect(
            mockPlugin.cancelledIds,
            contains(NotificationService.kAngelusMiddayBaseId + i),
          );
          expect(
            mockPlugin.cancelledIds,
            contains(NotificationService.kAngelusEveningBaseId + i),
          );
        }
      });
    });

    group('Rosary Notification', () {
      test('schedules 7 weekly repeating notifications matching each day of week', () async {
        final settings = UserSettings(
          rosaryReminderEnabled: true,
          rosaryReminderHour: 19,
          rosaryReminderMinute: 45,
        );

        await NotificationService.syncRosaryNotification(settings);

        expect(mockPlugin.scheduledList.length, equals(7));
        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kRosaryNotificationLegacyId),
        );

        final mysteriesByWeekday = {
          1: 'Joyful Mysteries', // Monday
          2: 'Sorrowful Mysteries', // Tuesday
          3: 'Glorious Mysteries', // Wednesday
          4: 'Luminous Mysteries', // Thursday
          5: 'Sorrowful Mysteries', // Friday
          6: 'Joyful Mysteries', // Saturday
          7: 'Glorious Mysteries', // Sunday
        };

        for (int weekday = 1; weekday <= 7; weekday++) {
          final record = mockPlugin.scheduledList.firstWhere(
            (r) => r.id == NotificationService.kRosaryNotificationBaseId + weekday,
          );
          expect(record.title, equals('Daily Rosary'));
          expect(record.body, contains(mysteriesByWeekday[weekday]!));
          expect(
            record.matchDateTimeComponents,
            equals(DateTimeComponents.dayOfWeekAndTime),
          );
          expect(record.scheduledDate.hour, equals(19));
          expect(record.scheduledDate.minute, equals(45));
          expect(record.scheduledDate.weekday, equals(weekday));
        }
      });

      test('cancels all 7 weekday notifications and legacy ID when disabled', () async {
        final settings = UserSettings(rosaryReminderEnabled: false);

        await NotificationService.syncRosaryNotification(settings);

        expect(
          mockPlugin.cancelledIds,
          contains(NotificationService.kRosaryNotificationLegacyId),
        );
        for (int weekday = 1; weekday <= 7; weekday++) {
          expect(
            mockPlugin.cancelledIds,
            contains(NotificationService.kRosaryNotificationBaseId + weekday),
          );
        }
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
        // Sunday: 6 rolling instances (1010..1015)
        for (int i = 0; i < NotificationService.kSundayRollingWeeks; i++) {
          expect(
            scheduledIds,
            contains(NotificationService.kSundayNotificationBaseId + i),
          );
        }
        // Angelus Midday: 14 rolling instances (2200..2213)
        for (int i = 0; i < NotificationService.kAngelusRollingDays; i++) {
          expect(
            scheduledIds,
            contains(NotificationService.kAngelusMiddayBaseId + i),
          );
        }
        // Rosary: 7 weekday repeating instances (2401..2407)
        for (int i = 1; i <= 7; i++) {
          expect(
            scheduledIds,
            contains(NotificationService.kRosaryNotificationBaseId + i),
          );
        }
      });
    });

    group('Lifecycle Resync in TwelveStarsApp', () {
      testWidgets(
        'calls syncAllNotifications on init and on resumed lifecycle state',
        (tester) async {
          PrayerDatabase.mockSettings = UserSettings(
            sundayNotificationsEnabled: false,
            angelusReminderEnabled: false,
            rosaryReminderEnabled: false,
          );

          NotificationService.syncAllCallCount = 0;

          await tester.pumpWidget(const TwelveStarsApp());
          await tester.pump();

          expect(NotificationService.syncAllCallCount, equals(1));

          // Simulate app going inactive or paused - should NOT re-trigger sync
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          await tester.pump();
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump();
          expect(NotificationService.syncAllCallCount, equals(1));

          // Simulate app resuming to foreground - should trigger sync
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          expect(NotificationService.syncAllCallCount, equals(2));
        },
      );
    });
  });
  });
}
