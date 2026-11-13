import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/time_helper.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class _TwelveStarsAppState extends State<TwelveStarsApp>
    with WidgetsBindingObserver, UserSettingsStateMixin<TwelveStarsApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeSetting();
    unawaited(
      NotificationService.syncAllNotifications().catchError((e, stack) {
        debugPrint(
          'Error during NotificationService.syncAllNotifications in initState: $e\n$stack',
        );
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void onUserSettingsChanged(UserSettings settings) {
    TwelveStarsApp.themeNotifier.value = settings.appThemeMode;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted &&
          TwelveStarsApp.themeNotifier.value == AppThemeMode.liturgical) {
        setState(() {});
      }
      unawaited(
        NotificationService.syncAllNotifications().catchError((e, stack) {
          debugPrint(
            'Error during NotificationService.syncAllNotifications in didChangeAppLifecycleState: $e\n$stack',
          );
        }),
      );
    }
  }

  Future<void> _loadThemeSetting() async {
    final settings = await ensureUserSettingsLoaded();
    TwelveStarsApp.themeNotifier.value = settings.appThemeMode;
  }

  Color _getSeedColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.liturgical:
        final today = LiturgicalCalendar.computeDay(TimeHelper.now());
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
