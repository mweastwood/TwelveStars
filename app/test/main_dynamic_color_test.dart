import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Color Scheme Initialization Tests', () {
    test(
      'MaterialUiColorSchemeX converts material_ui.ColorScheme to flutter.ColorScheme correctly',
      () {
        const materialUiScheme = material_ui.ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF123456),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFF112233),
          onPrimaryContainer: Color(0xFF332211),
          primaryFixed: Color(0xFF111122),
          primaryFixedDim: Color(0xFF222233),
          onPrimaryFixed: Color(0xFF333344),
          onPrimaryFixedVariant: Color(0xFF444455),
          secondary: Color(0xFF654321),
          onSecondary: Color(0xFF000000),
          secondaryContainer: Color(0xFF665544),
          onSecondaryContainer: Color(0xFF445566),
          secondaryFixed: Color(0xFF554433),
          secondaryFixedDim: Color(0xFF443322),
          onSecondaryFixed: Color(0xFF332211),
          onSecondaryFixedVariant: Color(0xFF221100),
          tertiary: Color(0xFF778899),
          onTertiary: Color(0xFF112233),
          tertiaryContainer: Color(0xFF998877),
          onTertiaryContainer: Color(0xFF332211),
          tertiaryFixed: Color(0xFF887766),
          tertiaryFixedDim: Color(0xFF776655),
          onTertiaryFixed: Color(0xFF665544),
          onTertiaryFixedVariant: Color(0xFF554433),
          error: Color(0xFFFF0000),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFF550000),
          onErrorContainer: Color(0xFFFF5555),
          surface: Color(0xFFEEEEEE),
          onSurface: Color(0xFF111111),
        );

        final flutterScheme = materialUiScheme.toFlutterColorScheme();

        expect(flutterScheme, isA<ColorScheme>());
        expect(flutterScheme.brightness, equals(Brightness.light));
        expect(flutterScheme.primary, equals(const Color(0xFF123456)));
        expect(flutterScheme.onPrimary, equals(const Color(0xFFFFFFFF)));
        expect(flutterScheme.primaryContainer, equals(const Color(0xFF112233)));
        expect(
          flutterScheme.onPrimaryContainer,
          equals(const Color(0xFF332211)),
        );
        expect(flutterScheme.primaryFixed, equals(const Color(0xFF111122)));
        expect(flutterScheme.primaryFixedDim, equals(const Color(0xFF222233)));
        expect(flutterScheme.onPrimaryFixed, equals(const Color(0xFF333344)));
        expect(
          flutterScheme.onPrimaryFixedVariant,
          equals(const Color(0xFF444455)),
        );
        expect(flutterScheme.secondary, equals(const Color(0xFF654321)));
        expect(flutterScheme.onSecondary, equals(const Color(0xFF000000)));
        expect(
          flutterScheme.secondaryContainer,
          equals(const Color(0xFF665544)),
        );
        expect(
          flutterScheme.onSecondaryContainer,
          equals(const Color(0xFF445566)),
        );
        expect(flutterScheme.secondaryFixed, equals(const Color(0xFF554433)));
        expect(
          flutterScheme.secondaryFixedDim,
          equals(const Color(0xFF443322)),
        );
        expect(flutterScheme.onSecondaryFixed, equals(const Color(0xFF332211)));
        expect(
          flutterScheme.onSecondaryFixedVariant,
          equals(const Color(0xFF221100)),
        );
        expect(flutterScheme.tertiary, equals(const Color(0xFF778899)));
        expect(flutterScheme.onTertiary, equals(const Color(0xFF112233)));
        expect(
          flutterScheme.tertiaryContainer,
          equals(const Color(0xFF998877)),
        );
        expect(
          flutterScheme.onTertiaryContainer,
          equals(const Color(0xFF332211)),
        );
        expect(flutterScheme.tertiaryFixed, equals(const Color(0xFF887766)));
        expect(flutterScheme.tertiaryFixedDim, equals(const Color(0xFF776655)));
        expect(flutterScheme.onTertiaryFixed, equals(const Color(0xFF665544)));
        expect(
          flutterScheme.onTertiaryFixedVariant,
          equals(const Color(0xFF554433)),
        );
        expect(flutterScheme.error, equals(const Color(0xFFFF0000)));
        expect(flutterScheme.onError, equals(const Color(0xFFFFFFFF)));
        expect(flutterScheme.errorContainer, equals(const Color(0xFF550000)));
        expect(flutterScheme.onErrorContainer, equals(const Color(0xFFFF5555)));
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

    testWidgets(
      'TwelveStarsApp applies non-null dynamic ColorScheme when system mode and dynamic colors are present',
      (WidgetTester tester) async {
        TwelveStarsApp.themeNotifier.value = AppThemeMode.system;

        const channel = MethodChannel('io.material.plugins/dynamic_color');
        // CorePalette.fromList expects 5 * 13 = 65 ARGB integer colors.
        final mockPaletteList = List<int>.filled(65, 0xFF1E3A8A);

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (MethodCall methodCall) async {
            if (methodCall.method == 'getCorePalette') {
              return Int32List.fromList(mockPaletteList);
            }
            return null;
          },
        );

        await tester.pumpWidget(const TwelveStarsApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(MaterialApp), findsOneWidget);
        final MaterialApp app = tester.widget(find.byType(MaterialApp));
        expect(app.theme?.colorScheme, isNotNull);

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      },
    );
  });
}
