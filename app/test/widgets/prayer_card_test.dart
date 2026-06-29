import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import '../test_helper.dart';

void main() {
  group('PrayerCard Widget', () {
    final testPrayer = defaultPrayers.first; // Our Father

    testWidgets('renders prayer title, subtitle, and content in English', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: PrayerCard(
                prayer: testPrayer,
                selectedLanguage: PrayerLanguage.english,
                onLanguageChanged: (_) {},
                onLaunchSource: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Our Father'), findsOneWidget);
      expect(find.textContaining("The Lord's Prayer"), findsOneWidget);
      expect(find.textContaining('who art in heaven'), findsOneWidget);
      expect(
        find.textContaining('Compendium of the Catechism'),
        findsOneWidget,
      );
    });

    testWidgets('triggers onLanguageChanged callback', (tester) async {
      PrayerLanguage? newLanguage;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: PrayerCard(
                prayer: testPrayer,
                selectedLanguage: PrayerLanguage.english,
                onLanguageChanged: (lang) => newLanguage = lang,
                onLaunchSource: (_) {},
              ),
            ),
          ),
        ),
      );

      final dropdownFinder = find.byType(DropdownButton<PrayerLanguage>);
      expect(dropdownFinder, findsOneWidget);

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap the Spanish option (nativeName 'Español')
      final spanishItemFinder = find.text('Español').last;
      await tester.tap(spanishItemFinder);
      await tester.pumpAndSettle();

      expect(newLanguage, PrayerLanguage.spanish);
    });

    testGoldens('renders English and Traditional Chinese states correctly', (
      tester,
    ) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'English State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.english,
            onLanguageChanged: (_) {},
            onLaunchSource: (_) {},
          ),
        )
        ..addScenario(
          'Traditional Chinese State',
          PrayerCard(
            prayer: testPrayer,
            selectedLanguage: PrayerLanguage.traditionalChinese,
            onLanguageChanged: (_) {},
            onLaunchSource: (_) {},
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 1500),
      );

      await screenMatchesGolden(tester, 'prayer_card_golden');
    });
  });
}
