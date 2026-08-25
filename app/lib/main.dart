import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'screens/home_screen.dart';

void main() {
  mainCommon();
}

void mainCommon() {
  runApp(const TwelveStarsApp());
}

enum AppEnvironment { dev, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;
}

class TwelveStarsApp extends StatefulWidget {
  const TwelveStarsApp({super.key});

  static final ValueNotifier<AppThemeMode> themeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.marianBlue);

  @override
  State<TwelveStarsApp> createState() => _TwelveStarsAppState();
}

class _TwelveStarsAppState extends State<TwelveStarsApp> {
  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

  Future<void> _loadThemeSetting() async {
    final settings = await PrayerDatabase.loadSettings();
    TwelveStarsApp.themeNotifier.value = settings.appThemeMode;
  }

  Color _getSeedColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.liturgical:
        final today = LiturgicalCalendar.computeDay(DateTime.now());
        return today.colorWidget;
      case AppThemeMode.marianBlue:
      case AppThemeMode.system:
        return const Color(0xFF1E3A8A); // Marian Deep Blue
    }
  }

  ColorScheme _toFlutterColorScheme(dynamic scheme) {
    return ColorScheme(
      brightness: scheme.brightness as Brightness,
      primary: scheme.primary as Color,
      onPrimary: scheme.onPrimary as Color,
      primaryContainer: scheme.primaryContainer as Color?,
      onPrimaryContainer: scheme.onPrimaryContainer as Color?,
      secondary: scheme.secondary as Color,
      onSecondary: scheme.onSecondary as Color,
      secondaryContainer: scheme.secondaryContainer as Color?,
      onSecondaryContainer: scheme.onSecondaryContainer as Color?,
      tertiary: scheme.tertiary as Color?,
      onTertiary: scheme.onTertiary as Color?,
      tertiaryContainer: scheme.tertiaryContainer as Color?,
      onTertiaryContainer: scheme.onTertiaryContainer as Color?,
      error: scheme.error as Color,
      onError: scheme.onError as Color,
      errorContainer: scheme.errorContainer as Color?,
      onErrorContainer: scheme.onErrorContainer as Color?,
      surface: scheme.surface as Color,
      onSurface: scheme.onSurface as Color,
      surfaceDim: scheme.surfaceDim as Color?,
      surfaceBright: scheme.surfaceBright as Color?,
      surfaceContainerLowest: scheme.surfaceContainerLowest as Color?,
      surfaceContainerLow: scheme.surfaceContainerLow as Color?,
      surfaceContainer: scheme.surfaceContainer as Color?,
      surfaceContainerHigh: scheme.surfaceContainerHigh as Color?,
      surfaceContainerHighest: scheme.surfaceContainerHighest as Color?,
      onSurfaceVariant: scheme.onSurfaceVariant as Color?,
      outline: scheme.outline as Color?,
      outlineVariant: scheme.outlineVariant as Color?,
      shadow: scheme.shadow as Color?,
      scrim: scheme.scrim as Color?,
      inverseSurface: scheme.inverseSurface as Color?,
      onInverseSurface: scheme.onInverseSurface as Color?,
      inversePrimary: scheme.inversePrimary as Color?,
      surfaceTint: scheme.surfaceTint as Color?,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: TwelveStarsApp.themeNotifier,
      builder: (context, themeMode, child) {
        return DynamicColorBuilder(
          builder: (dynamic lightDynamic, dynamic darkDynamic) {
            ColorScheme lightScheme;
            ColorScheme darkScheme;

            if (themeMode == AppThemeMode.system &&
                lightDynamic != null &&
                darkDynamic != null) {
              lightScheme = _toFlutterColorScheme(lightDynamic);
              darkScheme = _toFlutterColorScheme(darkDynamic);
            } else {
              final seedColor = _getSeedColor(themeMode);
              lightScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              );
              darkScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              );
            }

            return MaterialApp(
              title: 'Twelve Stars',
              theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
              darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
              home: const HomeScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
