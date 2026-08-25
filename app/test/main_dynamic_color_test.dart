import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:twelve_stars/main.dart';
import 'package:twelve_stars/logic/prayers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Color Scheme Mapping & Initialization Tests', () {
    test(
      'MaterialUiColorSchemeMapper converts material_ui.ColorScheme to flutter.ColorScheme correctly',
      () {
        const materialUiScheme = material_ui.ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF123456),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF654321),
          onSecondary: Color(0xFF000000),
          error: Color(0xFFFF0000),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFEEEEEE),
          onSurface: Color(0xFF111111),
        );

        final flutterScheme = materialUiScheme.toFlutterColorScheme();

        expect(flutterScheme, isA<ColorScheme>());
        expect(flutterScheme.brightness, equals(Brightness.light));
        expect(flutterScheme.primary, equals(const Color(0xFF123456)));
        expect(flutterScheme.onPrimary, equals(const Color(0xFFFFFFFF)));
        expect(flutterScheme.secondary, equals(const Color(0xFF654321)));
        expect(flutterScheme.onSecondary, equals(const Color(0xFF000000)));
        expect(flutterScheme.error, equals(const Color(0xFFFF0000)));
        expect(flutterScheme.onError, equals(const Color(0xFFFFFFFF)));
        expect(flutterScheme.surface, equals(const Color(0xFFEEEEEE)));
        expect(flutterScheme.onSurface, equals(const Color(0xFF111111)));
      },
    );

    testWidgets(
      'TwelveStarsApp initializes and renders properly under system dynamic theme',
      (WidgetTester tester) async {
        TwelveStarsApp.themeNotifier.value = AppThemeMode.system;

        await tester.pumpWidget(const TwelveStarsApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'TwelveStarsApp initializes and renders properly under Marian Blue theme',
      (WidgetTester tester) async {
        TwelveStarsApp.themeNotifier.value = AppThemeMode.marianBlue;

        await tester.pumpWidget(const TwelveStarsApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );
  });
}
