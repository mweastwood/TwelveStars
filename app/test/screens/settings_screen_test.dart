import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Toggle switch off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(PrayerDatabase.mockSettings!.hapticsEnabled, isFalse);

      PrayerDatabase.mockSettings = null;
    });
  });
}
