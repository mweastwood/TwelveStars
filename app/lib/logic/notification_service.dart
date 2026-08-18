import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static FlutterLocalNotificationsPlugin? mockPlugin;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

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

  /// Updates or cancels Sunday Liturgical Notification based on UserSettings.
  static Future<void> syncSundayNotification([UserSettings? settings]) async {
    if (kIsWeb) return;
    final userSettings = settings ?? await PrayerDatabase.loadSettings();

    try {
      await initialize();

      if (!userSettings.sundayNotificationsEnabled) {
        await plugin.cancel(id: 1001);
        return;
      }

      final scheduledTime = nextSunday8AM();
      final liturgicalDay = LiturgicalCalendar.computeDay(scheduledTime);

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

      try {
        await plugin.zonedSchedule(
          id: 1001,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e, stack) {
        debugPrint(
          'NotificationService exact schedule failed ($e), falling back to inexact schedule: $stack',
        );
        try {
          await plugin.zonedSchedule(
            id: 1001,
            title: title,
            body: body,
            scheduledDate: scheduledTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
          );
        } catch (e, stack) {
          debugPrint('NotificationService inexact schedule error: $e\n$stack');
        }
      }
    } catch (e, stack) {
      debugPrint(
        'NotificationService syncSundayNotification error: $e\n$stack',
      );
    }
  }
}
