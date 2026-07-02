import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';
import 'package:twelve_stars/screens/rosary_tab.dart';
import '../test_helper.dart';

List<Prayer> _createMockPrayers() {
  PrayerTranslation transFor(String title) {
    return PrayerTranslation(
      title: title,
      subtitle: 'Mock Subtitle',
      text: 'This is the mock prayer text.',
      sourceName: 'Mock Source',
      sourceUrl: 'https://example.com',
    );
  }

  return [
    Prayer.mock(
      id: 'sign_of_the_cross',
      defaultTitle: 'Sign of the Cross',
      translations: {
        PrayerLanguage.english: [transFor('Sign of the Cross')],
      },
    ),
    Prayer.mock(
      id: 'apostles_creed',
      defaultTitle: 'Apostles\' Creed',
      translations: {
        PrayerLanguage.english: [transFor('Apostles\' Creed')],
      },
    ),
    Prayer.mock(
      id: 'our_father',
      defaultTitle: 'Our Father',
      translations: {
        PrayerLanguage.english: [transFor('Our Father')],
      },
    ),
    Prayer.mock(
      id: 'hail_mary',
      defaultTitle: 'Hail Mary',
      translations: {
        PrayerLanguage.english: [transFor('Hail Mary')],
      },
    ),
    Prayer.mock(
      id: 'glory_be',
      defaultTitle: 'Glory Be',
      translations: {
        PrayerLanguage.english: [transFor('Glory Be')],
      },
    ),
    Prayer.mock(
      id: 'fatima_prayer',
      defaultTitle: 'Fatima Prayer',
      translations: {
        PrayerLanguage.english: [transFor('Fatima Prayer')],
      },
    ),
    Prayer.mock(
      id: 'hail_holy_queen',
      defaultTitle: 'Hail Holy Queen',
      translations: {
        PrayerLanguage.english: [transFor('Hail Holy Queen')],
      },
    ),
    Prayer.mock(
      id: 'final_prayer_rosary',
      defaultTitle: 'Final Prayer',
      translations: {
        PrayerLanguage.english: [transFor('Final Prayer')],
      },
    ),
  ];
}

void main() {
  group('RosaryTab Screen', () {
    late List<Prayer> mockPrayers;

    setUp(() {
      mockPrayers = _createMockPrayers();
    });

    testWidgets('allows progressing, backing, and resetting the Rosary', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: RosaryTab(
              prayers: mockPrayers,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              onLaunchSource: (_) {},
            ),
          ),
        ),
      );

      // 1. Initial state: Sign of the Cross and Apostles' Creed should be visible
      expect(find.text('Sign of the Cross'), findsWidgets);
      expect(find.text('Apostles\' Creed'), findsWidgets);

      // Back button should be disabled
      final backButtonFinder = find.widgetWithText(ElevatedButton, 'Back');
      expect(tester.widget<ElevatedButton>(backButtonFinder).onPressed, isNull);

      // 2. Click "Next" -> advances to Our Father
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Our Father'), findsWidgets);
      expect(
        tester.widget<ElevatedButton>(backButtonFinder).onPressed,
        isNotNull,
      );

      // 3. Click "Back" -> goes back to Opening Prayers (disabled again)
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Sign of the Cross'), findsWidgets);
      expect(find.text('Apostles\' Creed'), findsWidgets);
      expect(tester.widget<ElevatedButton>(backButtonFinder).onPressed, isNull);

      // 4. Click "Next" twice -> reaches Hail Mary
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Hail Mary'), findsWidgets);

      // 5. Reset -> goes back to Opening Prayers
      await tester.tap(find.byIcon(Icons.replay));
      await tester.pumpAndSettle();

      expect(find.text('Sign of the Cross'), findsWidgets);
    });

    testWidgets('changing mystery type resets step to 0', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: RosaryTab(
              prayers: mockPrayers,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              onLaunchSource: (_) {},
            ),
          ),
        ),
      );

      // Advance to Our Father (Next once from Opening Prayers)
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Our Father'), findsWidgets);

      // Open Mystery Dropdown and select Sorrowful
      await tester.tap(find.byType(DropdownButtonFormField<RosaryMysteryType>));
      await tester.pumpAndSettle();

      // Tap on Sorrowful Mysteries item
      await tester.tap(
        find.text('Sorrowful Mysteries (Tuesdays & Fridays)').last,
      );
      await tester.pumpAndSettle();

      // Active step should reset to 0 (Opening Prayers)
      expect(find.text('Sign of the Cross'), findsWidgets);
      expect(find.text('Apostles\' Creed'), findsWidgets);
    });

    testGoldens('renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Rosary Tab Active State',
          RosaryTab(
            prayers: mockPrayers,
            primaryLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.latin,
            onLaunchSource: (_) {},
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'rosary_tab_populated_golden');
    });
  });
}
