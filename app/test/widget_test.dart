import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/main.dart';

void main() {
  testWidgets('TwelveStarsApp widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TwelveStarsApp());

    expect(find.text('TwelveStars'), findsOneWidget);
    expect(find.text('Twelve Stars'), findsOneWidget);

    // Verify default prayers are loaded in English initially
    expect(find.text('Our Father'), findsOneWidget);
    expect(find.text('Hail Mary'), findsOneWidget);
    expect(find.text('Glory Be'), findsOneWidget);

    // Verify that the bottom navigation bar is present and has two destinations
    expect(find.text('Prayers'), findsWidgets);
    expect(find.text('Rosary'), findsWidgets);

    // Verify Rosary content is NOT shown yet
    expect(find.text('The Holy Rosary'), findsNothing);

    // Switch to the Rosary tab
    await tester.tap(find.text('Rosary').last);
    await tester.pumpAndSettle();

    // Verify Rosary tab content is now shown
    expect(find.text('The Holy Rosary'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);
    expect(find.text('Our Father'), findsNothing);

    // Switch back to Prayers tab
    await tester.tap(find.text('Prayers').last);
    await tester.pumpAndSettle();
    expect(find.text('Our Father'), findsOneWidget);
  });
}
