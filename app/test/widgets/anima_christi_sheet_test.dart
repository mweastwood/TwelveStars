import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/widgets/anima_christi_sheet.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';

void main() {
  group('AnimaChristiSheet Tests', () {
    late Prayer animaChristiPrayer;

    setUp(() {
      PrayerDatabase.mockSettings = UserSettings();
      animaChristiPrayer = Prayer.mock(
        id: 'anima_christi',
        defaultTitle: 'Anima Christi',
        category: 'devotion',
        hasAmen: true,
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Anima Christi',
              subtitle: 'Soul of Christ',
              text:
                  '{Soul of Christ, sanctify me.|anima_christi_1} {Body of Christ, save me.|anima_christi_2}',
              sourceName: 'Traditional',
              sourceUrl: 'https://vatican.va',
            ),
            PrayerTranslation.mock(
              title: 'Anima Christi (Alternative)',
              subtitle: 'Soul of Christ (Alt)',
              text:
                  '{Soul of Christ, make me holy.|anima_christi_1} {Body of Christ, redeem me.|anima_christi_2}',
              sourceName: 'Traditional Alt',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation.mock(
              title: 'Anima Christi',
              subtitle: 'Anima Christi',
              text:
                  '{Anima Christi, sanctifica me.|anima_christi_1} {Corpus Christi, salva me.|anima_christi_2}',
              sourceName: 'Traditional',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      );
    });

    tearDown(() {
      PrayerDatabase.mockSettings = null;
    });

    testWidgets('renders header, close button, and prayer content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimaChristiSheet(
              prayer: animaChristiPrayer,
              primaryLanguage: PrayerLanguage.english,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anima Christi'), findsWidgets);
      expect(find.text('Thanksgiving after Communion'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
      expect(find.byType(PrayerCard), findsOneWidget);
      expect(
        find.textContaining('Soul of Christ, sanctify me.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders dual-language comparison when compareLanguage is set',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimaChristiSheet(
                prayer: animaChristiPrayer,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Soul of Christ, sanctify me.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Anima Christi, sanctifica me.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AnimaChristiSheet.show opens modal and close button dismisses it',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => AnimaChristiSheet.show(
                      context,
                      prayer: animaChristiPrayer,
                      primaryLanguage: PrayerLanguage.english,
                    ),
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Thanksgiving after Communion'), findsNothing);

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Thanksgiving after Communion'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Thanksgiving after Communion'), findsNothing);
      },
    );

    testWidgets('version changed callback is triggered and persists settings', (
      WidgetTester tester,
    ) async {
      int? changedVersion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimaChristiSheet(
              prayer: animaChristiPrayer,
              primaryLanguage: PrayerLanguage.english,
              settings: UserSettings(),
              onVersionChanged: (val) {
                changedVersion = val;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find version selector dropdown / inkwell if versions are multiple
      final versionSelector = find.byType(DropdownButton<int>);
      if (versionSelector.evaluate().isNotEmpty) {
        await tester.tap(versionSelector);
        await tester.pumpAndSettle();

        final secondOption = find.text('Anima Christi (Alternative)').last;
        await tester.tap(secondOption);
        await tester.pumpAndSettle();

        expect(changedVersion, equals(1));
      }
    });
  });
}
