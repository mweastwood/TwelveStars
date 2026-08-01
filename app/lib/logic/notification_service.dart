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

  static FlutterLocalNotificationsPlugin get plugin =>
      mockPlugin ?? _notificationsPlugin;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

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
      await plugin.initialize(initSettings);
      _isInitialized = true;
    } catch (_) {}
  }

  /// Calculates next Sunday at 8:00 AM local time.
  static tz.TZDateTime nextSunday8AM([DateTime? fromDate]) {
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    final now = fromDate ?? DateTime.now();
    final tzNow = tz.TZDateTime.from(now, tz.local);

    // Days until next Sunday (Sunday is 7 in DateTime.weekday)
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday < 0) {
      daysUntilSunday += 7;
    } else if (daysUntilSunday == 0 &&
        (now.hour > 8 || (now.hour == 8 && now.minute > 0))) {
      daysUntilSunday = 7;
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
    final userSettings = settings ?? await PrayerDatabase.loadSettings();

    try {
      if (!userSettings.sundayNotificationsEnabled) {
        await plugin.cancel(1001);
        return;
      }

      await initialize();

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
          1001,
          title,
          body,
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        try {
          await plugin.zonedSchedule(
            1001,
            title,
            body,
            scheduledTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (_) {}
      }
    } catch (_) {}
  }
}
