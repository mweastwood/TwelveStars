import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/main.dart';

void main() {
  testWidgets('HomeScreen interactive widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TwelveStarsApp());

    // Verify Hello, World! is shown
    expect(find.text('Hello, World!'), findsOneWidget);
    expect(find.text('0 stars shining'), findsOneWidget);

    // Tap the 'Shine Star' button and trigger a frame.
    await tester.tap(find.widgetWithText(FilledButton, 'Shine Star'));
    await tester.pump();

    // Verify that the label has updated.
    expect(find.text('1 star shining'), findsOneWidget);
  });
}
