import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
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
  group('RosaryScreen Screen', () {
    late List<Prayer> mockPrayers;

    setUp(() {
      mockPrayers = _createMockPrayers();
    });

    testWidgets('allows progressing, backing, and resetting the Rosary', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: RosaryScreen(
            prayers: mockPrayers,
            primaryLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.latin,
            initialDate: DateTime(
              2026,
              7,
              6,
            ), // Fixed Monday (Joyful Mysteries)
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

    testWidgets(
      'allows volume up and volume down keys to control Rosary navigation',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: RosaryScreen(
              prayers: mockPrayers,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              initialDate: DateTime(2026, 7, 27),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Step 0: Sign of the Cross
        expect(find.text('Sign of the Cross'), findsWidgets);

        // Press Volume Up -> Next step (Our Father)
        await tester.sendKeyEvent(LogicalKeyboardKey.audioVolumeUp);
        await tester.pumpAndSettle();
        expect(find.text('Our Father'), findsWidgets);

        // Press Volume Down -> Back step (Sign of the Cross)
        await tester.sendKeyEvent(LogicalKeyboardKey.audioVolumeDown);
        await tester.pumpAndSettle();
        expect(find.text('Sign of the Cross'), findsWidgets);
      },
    );

    testWidgets('changing mystery type resets step to 0', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: RosaryScreen(
            prayers: mockPrayers,
            primaryLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.latin,
            initialDate: DateTime(
              2026,
              7,
              6,
            ), // Fixed Monday (Joyful Mysteries)
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

    testWidgets('initializes with mystery selection based on initialDate', (
      tester,
    ) async {
      // Test Thursday (Luminous)
      await tester.pumpWidget(
        buildTestableWidget(
          child: RosaryScreen(
            prayers: mockPrayers,
            primaryLanguage: PrayerLanguage.english,
            compareLanguage: PrayerLanguage.latin,
            initialDate: DateTime(2026, 7, 9), // Thursday
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Luminous Mysteries (Thursdays)'), findsOneWidget);
    });

    testGoldens('renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Rosary Tab Active State',
          SizedBox(
            height: 640,
            child: RosaryScreen(
              prayers: mockPrayers,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              initialDate: DateTime(
                2026,
                7,
                6,
              ), // Fixed Monday (Joyful Mysteries)
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'rosary_tab_populated_golden');
    });

    testWidgets(
      'forwards fontSize to PrayerCards and loads/persists preferred prayer versions',
      (tester) async {
        final multiVersionPrayers = _createMockPrayers().map((p) {
          if (p.prayerId == 'sign_of_the_cross') {
            return Prayer.mock(
              id: 'sign_of_the_cross',
              defaultTitle: 'Sign of the Cross',
              translations: {
                PrayerLanguage.english: [
                  PrayerTranslation(
                    title: 'Sign of the Cross (Traditional)',
                    subtitle: 'Traditional',
                    text: 'In the name of the Father...',
                  ),
                  PrayerTranslation(
                    title: 'Sign of the Cross (Modern)',
                    subtitle: 'Modern',
                    text: 'In the name of the Father (Modern)...',
                  ),
                ],
              },
            );
          }
          return p;
        }).toList();

        final settings = UserSettings()
          ..setPreferredVersionIndex(
            'sign_of_the_cross_${PrayerLanguage.english.code}',
            1,
          );
        PrayerDatabase.mockSettings = settings;
        addTearDown(() {
          PrayerDatabase.mockSettings = null;
        });
        await UserSettingsController.instance.update(settings);

        await tester.pumpWidget(
          buildTestableWidget(
            child: RosaryScreen(
              prayers: multiVersionPrayers,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              fontSize: 22.0,
              initialDate: DateTime(2026, 7, 6),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final prayerCards = tester
            .widgetList<PrayerCard>(find.byType(PrayerCard))
            .toList();
        expect(prayerCards, isNotEmpty);
        for (final card in prayerCards) {
          expect(card.fontSize, equals(22.0));
        }

        final signCard = prayerCards.firstWhere(
          (c) => c.prayer.prayerId == 'sign_of_the_cross',
        );
        expect(signCard.initialVersionIndex, equals(1));
      },
    );

    testWidgets(
      'ignores volume key events while the Rosary Completed dialog is open so duplicate dialogs are not stacked',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: RosaryScreen(
              prayers: mockPrayers,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
              initialDate: DateTime(2026, 7, 6),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final totalSteps = RosaryHelper.generateSteps(
          RosaryMysteryType.joyful,
        ).length;

        // Advance to the final step using Volume Up
        for (int i = 0; i < totalSteps - 1; i++) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.audioVolumeUp);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.audioVolumeUp);
        }
        await tester.pumpAndSettle();

        expect(find.widgetWithText(FilledButton, 'Finish'), findsOneWidget);

        // Press Volume Up on the final step -> opens "Rosary Completed" dialog
        await tester.sendKeyDownEvent(LogicalKeyboardKey.audioVolumeUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.audioVolumeUp);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Rosary Completed'), findsOneWidget);

        // Press Volume Up and Volume Down while dialog is open -> must NOT stack another dialog
        await tester.sendKeyDownEvent(LogicalKeyboardKey.audioVolumeUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.audioVolumeUp);
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.audioVolumeDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.audioVolumeDown);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // Dismiss the single dialog via 'Amen' -> dialog closes cleanly and Rosary resets
        await tester.tap(find.widgetWithText(FilledButton, 'Amen'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Sign of the Cross'), findsWidgets);
      },
    );
  });
}
