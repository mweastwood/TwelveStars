import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/widgets/prayers_header.dart';
import '../test_helper.dart';

void main() {
  group('PrayersHeader Widget', () {
    testWidgets('renders title, quote, and reference correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: PrayersHeader())),
      );

      expect(find.text('Twelve Stars'), findsOneWidget);
      expect(
        find.text(
          '“A great sign appeared in heaven: a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars.”',
        ),
        findsOneWidget,
      );
      expect(find.text('— Revelation 12:1'), findsOneWidget);
    });

    testGoldens('renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario('Prayers Header Default', const PrayersHeader());

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'prayers_header_golden');
    });
  });
}
