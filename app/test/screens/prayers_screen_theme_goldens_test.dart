import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/time_helper.dart';
import 'package:twelve_stars/screens/home_screen.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prayers Screen Theme Golden Tests', () {
    final mockPrayers = [
      Prayer.mock(
        id: 'our_father',
        defaultTitle: 'Our Father',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Our Father',
              subtitle: 'The Lord\'s Prayer',
              text: 'Our Father, who art in heaven...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'hail_mary',
        defaultTitle: 'Hail Mary',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Hail Mary',
              subtitle: 'Angelic Salutation',
              text: 'Hail Mary, full of grace...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
    ];

    setUp(() {
      PrayerDatabase.mockPrayers = mockPrayers;
    });

    tearDown(() {
      TimeHelper.setCustomTime(null);
      PrayerDatabase.mockPrayers = null;
      PrayerDatabase.mockSettings = null;
    });

    testGoldens('renders Prayers Screen under Marian Blue theme', (
      tester,
    ) async {
      TimeHelper.setCustomTime(DateTime(2026, 7, 6));
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'marian_blue',
      );

      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

      await tester.pumpWidgetBuilder(
        HomeScreen(initialDate: DateTime(2026, 7, 6)),
        wrapper: materialAppWrapper(theme: theme),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'prayers_screen_theme_marian_blue_golden',
      );
    });

    testGoldens('renders Prayers Screen under Ordinary Time (Green)', (
      tester,
    ) async {
      final date = DateTime(2026, 7, 6); // Ordinary Time
      TimeHelper.setCustomTime(date);
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'liturgical',
      );

      final liturgicalDay = LiturgicalCalendar.computeDay(date);
      expect(liturgicalDay.color, equals(LiturgicalColor.green));

      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: liturgicalDay.colorWidget,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

      await tester.pumpWidgetBuilder(
        HomeScreen(initialDate: date),
        wrapper: materialAppWrapper(theme: theme),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'prayers_screen_theme_liturgical_ordinary_time_green_golden',
      );
    });

    testGoldens('renders Prayers Screen under Lent (Royal Violet / Purple)', (
      tester,
    ) async {
      final date = DateTime(2026, 3, 1); // 1st Sunday of Lent
      TimeHelper.setCustomTime(date);
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'liturgical',
      );

      final liturgicalDay = LiturgicalCalendar.computeDay(date);
      expect(liturgicalDay.color, equals(LiturgicalColor.purple));

      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: liturgicalDay.colorWidget,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

      await tester.pumpWidgetBuilder(
        HomeScreen(initialDate: date),
        wrapper: materialAppWrapper(theme: theme),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'prayers_screen_theme_liturgical_lent_violet_golden',
      );
    });

    testGoldens(
      'renders Prayers Screen under Easter (Liturgical Gold / White)',
      (tester) async {
        final date = DateTime(2026, 4, 5); // Easter Sunday
        TimeHelper.setCustomTime(date);
        PrayerDatabase.mockSettings = UserSettings(
          appThemeModeCode: 'liturgical',
        );

        final liturgicalDay = LiturgicalCalendar.computeDay(date);
        expect(liturgicalDay.color, equals(LiturgicalColor.white));

        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: liturgicalDay.colorWidget,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );

        await tester.pumpWidgetBuilder(
          HomeScreen(initialDate: date),
          wrapper: materialAppWrapper(theme: theme),
          surfaceSize: const Size(400, 800),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'prayers_screen_theme_liturgical_easter_gold_golden',
        );
      },
    );

    testGoldens('renders Prayers Screen under Pentecost (Martyr Red)', (
      tester,
    ) async {
      final date = DateTime(2026, 5, 24); // Pentecost Sunday
      TimeHelper.setCustomTime(date);
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'liturgical',
      );

      final liturgicalDay = LiturgicalCalendar.computeDay(date);
      expect(liturgicalDay.color, equals(LiturgicalColor.red));

      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: liturgicalDay.colorWidget,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

      await tester.pumpWidgetBuilder(
        HomeScreen(initialDate: date),
        wrapper: materialAppWrapper(theme: theme),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'prayers_screen_theme_liturgical_pentecost_red_golden',
      );
    });

    testGoldens('renders Prayers Screen under Gaudete Sunday (Rose)', (
      tester,
    ) async {
      final date = DateTime(
        2026,
        12,
        13,
      ); // 3rd Sunday of Advent (Gaudete Sunday)
      TimeHelper.setCustomTime(date);
      PrayerDatabase.mockSettings = UserSettings(
        appThemeModeCode: 'liturgical',
      );

      final liturgicalDay = LiturgicalCalendar.computeDay(date);
      expect(liturgicalDay.color, equals(LiturgicalColor.rose));

      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: liturgicalDay.colorWidget,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

      await tester.pumpWidgetBuilder(
        HomeScreen(initialDate: date),
        wrapper: materialAppWrapper(theme: theme),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'prayers_screen_theme_liturgical_gaudete_rose_golden',
      );
    });
  });
}
