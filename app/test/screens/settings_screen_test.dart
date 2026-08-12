import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/screens/settings_screen.dart';

import '../test_helper.dart';

void main() {
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
