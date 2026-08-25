import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Color Scheme Initialization Tests', () {
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
