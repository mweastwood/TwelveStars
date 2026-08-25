import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/main.dart';
import 'package:twelve_stars/logic/prayers.dart';

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
  });
}
