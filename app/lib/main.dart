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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: TwelveStarsApp.themeNotifier,
      builder: (context, themeMode, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ColorScheme lightScheme;
            ColorScheme darkScheme;

            if (themeMode == AppThemeMode.system &&
                lightDynamic != null &&
                darkDynamic != null) {
              lightScheme = lightDynamic;
              darkScheme = darkDynamic;
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
