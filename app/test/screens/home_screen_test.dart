import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/logic/prayers.dart';
import '../test_helper.dart';

void main() {
  group('HomeScreen Widget', () {
    testWidgets('renders initial tab (Prayers) and switches to Rosary tab', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(child: const HomeScreen()));

      // Verify app bar and header are present
      expect(find.text('TwelveStars'), findsWidgets);
      expect(find.text('Twelve Stars'), findsOneWidget);

      // Verify default prayers are loaded in English initially
      expect(find.text('Our Father'), findsOneWidget);
      expect(find.text('Hail Mary'), findsOneWidget);
      expect(find.text('Glory Be'), findsOneWidget);

      // Verify navigation items
      expect(find.text('Prayers'), findsWidgets);
      expect(find.text('Rosary'), findsWidgets);

      // Rosary tab content should not be present initially
      expect(find.text('The Holy Rosary'), findsNothing);

      // Switch to the Rosary tab
      await tester.tap(find.text('Rosary').last);
      await tester.pumpAndSettle();

      // Rosary content should now be visible
      expect(find.text('The Holy Rosary'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);

      // Prayers should not be visible now
      expect(find.text('Our Father'), findsNothing);

      // Switch back to Prayers tab
      await tester.tap(find.text('Prayers').last);
      await tester.pumpAndSettle();

      // Prayers should be visible again
      expect(find.text('Our Father'), findsOneWidget);
    });

    testWidgets('changes language of prayer in dropdown', (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const HomeScreen()));

      // Select dropdown for Our Father
      final dropdownFinder = find.byType(DropdownButton<PrayerLanguage>).first;
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap Traditional Chinese (nativeName '繁體中文')
      final chineseItemFinder = find.text('繁體中文').last;
      await tester.tap(chineseItemFinder);
      await tester.pumpAndSettle();

      // Title should change to '天主經'
      expect(find.text('天主經'), findsOneWidget);
      expect(find.text('wǒ'), findsWidgets);
    });

    testGoldens('HomeScreen renders correctly in both tabs', (tester) async {
      // 1. Initial/Prayers tab golden
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(400, 800),
      );
      await screenMatchesGolden(tester, 'home_screen_prayers_tab_golden');

      // 2. Rosary tab golden
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(400, 800),
      );
      // Switch tab
      await tester.tap(find.text('Rosary').last);
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_rosary_tab_golden');
    });
  });
}
