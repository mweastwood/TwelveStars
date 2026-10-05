import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static const int kSundayNotificationLegacyId = 1001;
  static const int kSundayNotificationBaseId = 1010;
  static const int kSundayRollingWeeks = 6;

  static const int kAngelusMorningLegacyId = 2001;
  static const int kAngelusMiddayLegacyId = 2002;
  static const int kAngelusEveningLegacyId = 2003;
  static const int kAngelusMorningBaseId = 2100;
  static const int kAngelusMiddayBaseId = 2200;
  static const int kAngelusEveningBaseId = 2300;
  static const int kAngelusRollingDays = 14;

  static const int kRosaryNotificationLegacyId = 2004;
  static const int kRosaryNotificationBaseId =
      2400; // IDs 2401..2407 for weekdays 1..7

  static const int kMorningPrayerNotificationId = 2005;
  static const int kNightPrayerNotificationId = 2006;

  static FlutterLocalNotificationsPlugin? mockPlugin;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  @visibleForTesting
  static VoidCallback? onSyncAll;

  @visibleForTesting
  static int syncAllCallCount = 0;

  @visibleForTesting
  static bool get isInitialized => _isInitialized;

  @visibleForTesting
  static set isInitialized(bool value) => _isInitialized = value;

  static FlutterLocalNotificationsPlugin get plugin =>
      mockPlugin ?? _notificationsPlugin;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e, stack) {
      debugPrint(
        'NotificationService timezone initialization error: $e\n$stack',
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
    );

    try {
      await plugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e, stack) {
      debugPrint('NotificationService plugin initialization error: $e\n$stack');
    }
  }

  /// Calculates next Sunday at 8:00 AM local time.
  static tz.TZDateTime nextSunday8AM([DateTime? fromDate]) {
    try {
      tz.initializeTimeZones();
    } catch (e, stack) {
      debugPrint(
        'NotificationService timezone initialization error: $e\n$stack',
      );
    }

    final now = fromDate ?? DateTime.now();
    final tzNow = now is tz.TZDateTime
        ? now
        : tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
            now.millisecond,
          );

    // Days until next Sunday (Sunday is 7 in DateTime.weekday)
    int daysUntilSunday = DateTime.sunday - tzNow.weekday;
    if (daysUntilSunday < 0) {
      daysUntilSunday += 7;
    } else if (daysUntilSunday == 0) {
      final targetToday8AM = tz.TZDateTime(
        tz.local,
        tzNow.year,
        tzNow.month,
        tzNow.day,
        8,
        0,
      );
      if (!tzNow.isBefore(targetToday8AM)) {
        daysUntilSunday = 7;
      }
    }

    final scheduledDate = tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day + daysUntilSunday,
      8,
      0,
    );

    return scheduledDate;
  }

  /// Calculates the next occurrence of [hour]:[minute] local time.
  static tz.TZDateTime nextDailyTime(
    int hour,
    int minute, [
    DateTime? fromDate,
  ]) {
    try {
      tz.initializeTimeZones();
    } catch (e, stack) {
      debugPrint(
        'NotificationService timezone initialization error: $e\n$stack',
      );
    }

    final now = fromDate ?? DateTime.now();
    final tzNow = now is tz.TZDateTime
        ? now
        : tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
            now.millisecond,
          );

    var scheduledDate = tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day,
      hour,
      minute,
    );

    if (!tzNow.isBefore(scheduledDate)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Calculates the next occurrence of [weekday] (1 = Monday, 7 = Sunday) at [hour]:[minute] local time.
  static tz.TZDateTime nextWeekdayTime(
    int weekday,
    int hour,
    int minute, [
    DateTime? fromDate,
  ]) {
    try {
      tz.initializeTimeZones();
    } catch (e, stack) {
      debugPrint(
        'NotificationService timezone initialization error: $e\n$stack',
      );
    }

    final now = fromDate ?? DateTime.now();
    final tzNow = now is tz.TZDateTime
        ? now
        : tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
            now.millisecond,
          );

    int daysUntilWeekday = weekday - tzNow.weekday;
    if (daysUntilWeekday < 0) {
      daysUntilWeekday += 7;
    } else if (daysUntilWeekday == 0) {
      final targetToday = tz.TZDateTime(
        tz.local,
        tzNow.year,
        tzNow.month,
        tzNow.day,
        hour,
        minute,
      );
      if (!tzNow.isBefore(targetToday)) {
        daysUntilWeekday = 7;
      }
    }

    return tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day + daysUntilWeekday,
      hour,
      minute,
    );
  }

  /// Computes Angelus title and body based on liturgical season (switches to Regina Caeli in Easter).
  static (String, String) computeAngelusContent(DateTime date) {
    final liturgicalDay = LiturgicalCalendar.computeDay(date);
    if (liturgicalDay.season == LiturgicalSeason.easter) {
      return (
        'Regina Caeli',
        'Queen of Heaven, rejoice, alleluia! For He whom you did merit to bear has risen, as He said, alleluia.',
      );
    }
    return (
      'The Angelus',
      'The Angel of the Lord declared unto Mary, and she conceived of the Holy Spirit.',
    );
  }

  /// Computes Rosary reminder title and body based on the mystery of the day.
  static (String, String) computeRosaryContent(DateTime date) {
    final mystery = RosaryHelper.getMysteryForDay(date);
    return (
      'Daily Rosary',
      "Time for the Rosary. Today's meditation: The ${mystery.name}.",
    );
  }

  /// Computes Morning Prayer reminder content.
  static (String, String) computeMorningPrayerContent(DateTime date) {
    return (
      'Morning Prayer',
      'Offer your day to the Lord: "O Lord, open my lips, and my mouth shall declare your praise."',
    );
  }

  /// Computes Night Prayer reminder content.
  static (String, String) computeNightPrayerContent(DateTime date) {
    return (
      'Night Prayer (Compline)',
      'Time for examination of conscience and night prayer: "Into your hands, Lord, I commend my spirit."',
    );
  }

  /// Helper to schedule a notification with fallback to inexact scheduling.
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    tz.TZDateTime? scheduledDate,
    DateTimeComponents? matchDateTimeComponents = DateTimeComponents.time,
    String channelId = 'prayer_reminders',
    String channelName = 'Prayer Reminders',
    String channelDescription =
        'Daily devotional notifications for Angelus, Rosary, and prayer hours',
    Color? color,
  }) async {
    final targetDate = scheduledDate ?? nextDailyTime(hour, minute);
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: color,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    try {
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: targetDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e, stack) {
      debugPrint(
        'NotificationService exact schedule failed ($e), falling back to inexact schedule: $stack',
      );
      try {
        await plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: targetDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: matchDateTimeComponents,
        );
      } catch (e, stack) {
        debugPrint('NotificationService inexact schedule error: $e\n$stack');
      }
    }
  }

  /// Updates or cancels Sunday Liturgical Notifications based on UserSettings.
  static Future<void> syncSundayNotification([
    UserSettings? settings,
    DateTime? fromDate,
  ]) async {
    if (kIsWeb) return;

    try {
      final userSettings = settings ?? await PrayerDatabase.loadSettings();
      await initialize();

      if (!userSettings.sundayNotificationsEnabled) {
        await plugin.cancel(id: kSundayNotificationLegacyId);
        for (
          int weekOffset = 0;
          weekOffset < kSundayRollingWeeks;
          weekOffset++
        ) {
          await plugin.cancel(id: kSundayNotificationBaseId + weekOffset);
        }
        return;
      }

      await plugin.cancel(id: kSundayNotificationLegacyId);
      final firstSunday = nextSunday8AM(fromDate);
      for (int weekOffset = 0; weekOffset < kSundayRollingWeeks; weekOffset++) {
        final sundayDate = tz.TZDateTime(
          tz.local,
          firstSunday.year,
          firstSunday.month,
          firstSunday.day + (7 * weekOffset),
          8,
          0,
        );
        final liturgicalDay = LiturgicalCalendar.computeDay(sundayDate);

        final androidDetails = AndroidNotificationDetails(
          'sunday_liturgical_season',
          'Sunday Liturgical Season',
          channelDescription:
              'Subtle weekly notification showing the current liturgical season and color accent',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: liturgicalDay.colorWidget,
          enableLights: true,
          ledColor: liturgicalDay.colorWidget,
          ledOnMs: 1000,
          ledOffMs: 500,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        );

        final title = 'Liturgical Season: ${liturgicalDay.seasonName}';
        final body =
            'Today is ${liturgicalDay.colorName} — ${liturgicalDay.seasonName}. Tap to view Mass readings & prayers.';

        final notificationId = kSundayNotificationBaseId + weekOffset;

        try {
          await plugin.zonedSchedule(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: sundayDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e, stack) {
          debugPrint(
            'NotificationService exact schedule failed ($e), falling back to inexact schedule: $stack',
          );
          try {
            await plugin.zonedSchedule(
              id: notificationId,
              title: title,
              body: body,
              scheduledDate: sundayDate,
              notificationDetails: notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexact,
            );
          } catch (e, stack) {
            debugPrint(
              'NotificationService inexact schedule error: $e\n$stack',
            );
          }
        }
      }
    } catch (e, stack) {
      debugPrint(
        'NotificationService syncSundayNotification error: $e\n$stack',
      );
    }
  }

  /// Updates or cancels Angelus / Regina Caeli reminders based on UserSettings.
  static Future<void> syncAngelusNotifications([
    UserSettings? settings,
    DateTime? fromDate,
  ]) async {
    if (kIsWeb) return;

    try {
      final userSettings = settings ?? await PrayerDatabase.loadSettings();
      await initialize();

      Future<void> syncAngelusSlot({
        required bool enabled,
        required int legacyId,
        required int baseId,
        required int hour,
        required int minute,
      }) async {
        await plugin.cancel(id: legacyId);
        if (enabled) {
          final firstOccurrence = nextDailyTime(hour, minute, fromDate);
          for (
            int dayOffset = 0;
            dayOffset < kAngelusRollingDays;
            dayOffset++
          ) {
            final targetDate = tz.TZDateTime(
              tz.local,
              firstOccurrence.year,
              firstOccurrence.month,
              firstOccurrence.day + dayOffset,
              hour,
              minute,
            );
            final (title, body) = computeAngelusContent(targetDate);
            await scheduleDailyNotification(
              id: baseId + dayOffset,
              title: title,
              body: body,
              hour: hour,
              minute: minute,
              scheduledDate: targetDate,
              matchDateTimeComponents: null,
            );
          }
        } else {
          for (
            int dayOffset = 0;
            dayOffset < kAngelusRollingDays;
            dayOffset++
          ) {
            await plugin.cancel(id: baseId + dayOffset);
          }
        }
      }

      // Morning (6:00 AM)
      await syncAngelusSlot(
        enabled:
            userSettings.angelusReminderEnabled &&
            userSettings.angelusMorningEnabled,
        legacyId: kAngelusMorningLegacyId,
        baseId: kAngelusMorningBaseId,
        hour: 6,
        minute: 0,
      );

      // Midday (12:00 PM)
      await syncAngelusSlot(
        enabled:
            userSettings.angelusReminderEnabled &&
            userSettings.angelusMiddayEnabled,
        legacyId: kAngelusMiddayLegacyId,
        baseId: kAngelusMiddayBaseId,
        hour: 12,
        minute: 0,
      );

      // Evening (6:00 PM / 18:00)
      await syncAngelusSlot(
        enabled:
            userSettings.angelusReminderEnabled &&
            userSettings.angelusEveningEnabled,
        legacyId: kAngelusEveningLegacyId,
        baseId: kAngelusEveningBaseId,
        hour: 18,
        minute: 0,
      );
    } catch (e, stack) {
      debugPrint(
        'NotificationService syncAngelusNotifications error: $e\n$stack',
      );
    }
  }

  /// Updates or cancels Daily Rosary reminder based on UserSettings.
  static Future<void> syncRosaryNotification([
    UserSettings? settings,
    DateTime? fromDate,
  ]) async {
    if (kIsWeb) return;

    try {
      final userSettings = settings ?? await PrayerDatabase.loadSettings();
      await initialize();

      if (userSettings.rosaryReminderEnabled) {
        await plugin.cancel(id: kRosaryNotificationLegacyId);
        final hour = userSettings.rosaryReminderHour;
        final minute = userSettings.rosaryReminderMinute;

        for (int weekday = 1; weekday <= 7; weekday++) {
          final scheduled = nextWeekdayTime(weekday, hour, minute, fromDate);
          final (title, body) = computeRosaryContent(scheduled);
          await scheduleDailyNotification(
            id: kRosaryNotificationBaseId + weekday,
            title: title,
            body: body,
            hour: hour,
            minute: minute,
            scheduledDate: scheduled,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        await plugin.cancel(id: kRosaryNotificationLegacyId);
        for (int weekday = 1; weekday <= 7; weekday++) {
          await plugin.cancel(id: kRosaryNotificationBaseId + weekday);
        }
      }
    } catch (e, stack) {
      debugPrint(
        'NotificationService syncRosaryNotification error: $e\n$stack',
      );
    }
  }

  /// Updates or cancels Morning Prayer reminder based on UserSettings.
  static Future<void> syncMorningPrayerNotification([
    UserSettings? settings,
  ]) async {
    if (kIsWeb) return;

    try {
      final userSettings = settings ?? await PrayerDatabase.loadSettings();
      await initialize();

      if (userSettings.morningPrayerReminderEnabled) {
        final hour = userSettings.morningPrayerReminderHour;
        final minute = userSettings.morningPrayerReminderMinute;
        final scheduled = nextDailyTime(hour, minute);
        final (title, body) = computeMorningPrayerContent(scheduled);
        await scheduleDailyNotification(
          id: kMorningPrayerNotificationId,
          title: title,
          body: body,
          hour: hour,
          minute: minute,
        );
      } else {
        await plugin.cancel(id: kMorningPrayerNotificationId);
      }
    } catch (e, stack) {
      debugPrint(
        'NotificationService syncMorningPrayerNotification error: $e\n$stack',
      );
    }
  }

  /// Updates or cancels Night Prayer reminder based on UserSettings.
  static Future<void> syncNightPrayerNotification([
    UserSettings? settings,
  ]) async {
    if (kIsWeb) return;

    try {
      final userSettings = settings ?? await PrayerDatabase.loadSettings();
      await initialize();

      if (userSettings.nightPrayerReminderEnabled) {
        final hour = userSettings.nightPrayerReminderHour;
        final minute = userSettings.nightPrayerReminderMinute;
        final scheduled = nextDailyTime(hour, minute);
        final (title, body) = computeNightPrayerContent(scheduled);
        await scheduleDailyNotification(
          id: kNightPrayerNotificationId,
          title: title,
          body: body,
          hour: hour,
          minute: minute,
        );
      } else {
        await plugin.cancel(id: kNightPrayerNotificationId);
      }
    } catch (e, stack) {
      debugPrint(
        'NotificationService syncNightPrayerNotification error: $e\n$stack',
      );
    }
  }

  /// Master sync method to synchronize all notifications based on current UserSettings.
  static Future<void> syncAllNotifications([
    UserSettings? settings,
    DateTime? fromDate,
  ]) async {
    onSyncAll?.call();
    if (kIsWeb) return;
    try {
      await initialize();
      final userSettings = settings ?? await PrayerDatabase.loadSettings();
      await syncSundayNotification(userSettings, fromDate);
      await syncAngelusNotifications(userSettings, fromDate);
      await syncRosaryNotification(userSettings, fromDate);
      await syncMorningPrayerNotification(userSettings);
      await syncNightPrayerNotification(userSettings);
    } catch (e, stack) {
      debugPrint('NotificationService syncAllNotifications error: $e\n$stack');
    }
  }
}
