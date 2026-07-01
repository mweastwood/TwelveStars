import 'package:flutter/material.dart';
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

class TwelveStarsApp extends StatelessWidget {
  const TwelveStarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twelve Stars',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Marian Deep Blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Marian Deep Blue
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
