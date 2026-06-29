import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart' as gt;

/// Wraps the widget under test in MaterialApp with the app's default theme.
Widget buildTestableWidget({required Widget child}) {
  return MaterialApp(
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
    home: child,
  );
}

/// A wrapper for golden tests that automatically injects MaterialApp with the app's theme.
gt.WidgetWrapper materialAppWrapper({
  TargetPlatform platform = TargetPlatform.android,
  ThemeData? theme,
}) {
  final defaultTheme =
      theme ??
      ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );
  return gt.materialAppWrapper(platform: platform, theme: defaultTheme);
}
