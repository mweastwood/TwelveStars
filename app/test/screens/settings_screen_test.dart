import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/screens/settings_screen.dart';
import '../test_helper.dart';

class FakeNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required dynamic scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    bool uiLocalNotificationDateInterpretation = true,
  }) async {}
}

void main() {
  setUp(() {
    NotificationService.mockPlugin = FakeNotificationsPlugin();
  });

  tearDown(() {
    NotificationService.mockPlugin = null;
    PrayerDatabase.mockSettings = null;
  });

  group('SettingsScreen Widget', () {
    testWidgets('renders haptics toggle and persists changes', (tester) async {
      PrayerDatabase.mockSettings = UserSettings(hapticsEnabled: true);

      await tester.pumpWidget(
        buildTestableWidget(child: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byKey(const Key('settings_haptics_tile')), findsOneWidget);

      final switchFinder = find.descendant(
        of: find.byKey(const Key('settings_haptics_tile')),
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Toggle switch off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(PrayerDatabase.mockSettings!.hapticsEnabled, isFalse);

      PrayerDatabase.mockSettings = null;
    });

    testWidgets('renders theme mode dropdown and changes theme', (
      tester,
    ) async {
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'marian_blue',
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_theme_tile')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_dropdown')), findsOneWidget);

      // Open dropdown
      await tester.tap(find.byKey(const Key('settings_theme_dropdown')));
      await tester.pumpAndSettle();

      // Tap 'Liturgical Season'
      final liturgicalOption = find.byKey(
        const Key('settings_theme_option_liturgical'),
      );
      expect(liturgicalOption, findsOneWidget);
      await tester.tap(liturgicalOption);
      await tester.pumpAndSettle();

      expect(
        PrayerDatabase.mockSettings!.appThemeMode,
        equals(AppThemeMode.liturgical),
      );

      PrayerDatabase.mockSettings = null;
    });

    testWidgets('renders Sunday notification toggle and persists changes', (
      tester,
    ) async {
      PrayerDatabase.mockSettings = UserSettings(
        sundayNotificationsEnabled: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      final tileFinder = find.byKey(
        const Key('settings_sunday_notifications_tile'),
      );
      expect(tileFinder, findsOneWidget);

      final switchFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Toggle switch off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(PrayerDatabase.mockSettings!.sundayNotificationsEnabled, isFalse);

      PrayerDatabase.mockSettings = null;
    });

    testWidgets(
      'renders Bible numbering system dropdown and changes numbering preference',
      (tester) async {
        PrayerDatabase.mockSettings = UserSettings(
          bibleNumberingSystemCode: 'vulgate',
        );

        await tester.pumpWidget(
          buildTestableWidget(child: const SettingsScreen()),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('settings_bible_numbering_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('settings_bible_numbering_dropdown')),
          findsOneWidget,
        );

        // Open dropdown
        await tester.tap(
          find.byKey(const Key('settings_bible_numbering_dropdown')),
        );
        await tester.pumpAndSettle();

        // Tap 'Modern (Masoretic)'
        final modernOption = find.byKey(
          const Key('settings_bible_numbering_option_modern'),
        );
        expect(modernOption, findsWidgets);
        await tester.tap(modernOption.last);
        await tester.pumpAndSettle();

        expect(
          PrayerDatabase.mockSettings!.bibleNumberingSystem,
          equals(BibleNumberingSystem.modern),
        );

        PrayerDatabase.mockSettings = null;
      },
    );

    testWidgets('renders Angelus toggle and time chips and persists changes', (
      tester,
    ) async {
      PrayerDatabase.mockSettings = UserSettings(
        angelusReminderEnabled: true,
        angelusMorningEnabled: false,
        angelusMiddayEnabled: true,
        angelusEveningEnabled: false,
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      final angelusTile = find.byKey(const Key('settings_angelus_tile'));
      expect(angelusTile, findsOneWidget);

      final morningChip = find.byKey(
        const Key('settings_angelus_morning_chip'),
      );
      expect(morningChip, findsOneWidget);

      // Tap morning chip to enable 6 AM
      await tester.tap(morningChip);
      await tester.pumpAndSettle();

      expect(PrayerDatabase.mockSettings!.angelusMorningEnabled, isTrue);

      PrayerDatabase.mockSettings = null;
    });

    testWidgets('renders Rosary reminder switch and toggles state', (
      tester,
    ) async {
      PrayerDatabase.mockSettings = UserSettings(
        rosaryReminderEnabled: false,
        rosaryReminderHour: 20,
        rosaryReminderMinute: 0,
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('settings_rosary_switch'));
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(PrayerDatabase.mockSettings!.rosaryReminderEnabled, isTrue);

      PrayerDatabase.mockSettings = null;
    });

    testWidgets('renders Morning and Night Prayer switches', (tester) async {
      PrayerDatabase.mockSettings = UserSettings(
        morningPrayerReminderEnabled: false,
        nightPrayerReminderEnabled: false,
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      final morningSwitch = find.byKey(
        const Key('settings_morning_prayer_switch'),
      );
      await tester.scrollUntilVisible(morningSwitch, 500);
      expect(morningSwitch, findsOneWidget);
      await tester.tap(morningSwitch);
      await tester.pumpAndSettle();
      expect(PrayerDatabase.mockSettings!.morningPrayerReminderEnabled, isTrue);

      final nightSwitch = find.byKey(const Key('settings_night_prayer_switch'));
      await tester.scrollUntilVisible(nightSwitch, 500);
      expect(nightSwitch, findsOneWidget);
      await tester.tap(nightSwitch);
      await tester.pumpAndSettle();
      expect(PrayerDatabase.mockSettings!.nightPrayerReminderEnabled, isTrue);

      PrayerDatabase.mockSettings = null;
    });

    testGoldens('SettingsScreen renders options and scenarios correctly', (
      tester,
    ) async {
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'marian_blue',
        hapticsEnabled: true,
        sundayNotificationsEnabled: true,
      );

      final builder = GoldenBuilder.column()
        ..addScenario(
          'Settings Screen Marian Blue Theme',
          const SizedBox(height: 600, child: SettingsScreen()),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 700),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'settings_screen_marian_blue_golden');

      // Test Liturgical Theme scenario with Haptics & Sunday Notifications Disabled
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'liturgical',
        hapticsEnabled: false,
        sundayNotificationsEnabled: false,
      );

      final liturgicalBuilder = GoldenBuilder.column()
        ..addScenario(
          'Settings Screen Liturgical Theme & Options Disabled',
          const SizedBox(height: 600, child: SettingsScreen()),
        );

      await tester.pumpWidgetBuilder(
        liturgicalBuilder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 700),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'settings_screen_liturgical_golden');

      PrayerDatabase.mockSettings = null;
    });
  });
}
