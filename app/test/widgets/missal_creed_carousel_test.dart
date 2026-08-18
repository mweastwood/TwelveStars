import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/missal_creed_carousel.dart';

void main() {
  Widget buildTestableCarousel({
    Widget? niceneCard,
    Widget? apostlesCard,
    PageController? controller,
    ValueChanged<int>? onPageChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MissalCreedCarousel(
              niceneCard: niceneCard,
              apostlesCard: apostlesCard,
              controller: controller,
              onPageChanged: onPageChanged,
            ),
          ),
        ),
      ),
    );
  }

  group('MissalCreedCarousel Tests', () {
    testWidgets('renders empty shrink when both cards are null', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableCarousel());
      await tester.pumpAndSettle();

      expect(find.byType(MissalCreedCarousel), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders directly when only one card is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableCarousel(niceneCard: const Text('Sole Nicene Card')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sole Nicene Card'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);

      await tester.pumpWidget(
        buildTestableCarousel(apostlesCard: const Text('Sole Apostles Card')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sole Apostles Card'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets(
      'renders PageView with both cards and defaults to page 0 (Nicene)',
      (tester) async {
        int? changedPage;
        await tester.pumpWidget(
          buildTestableCarousel(
            niceneCard: const SizedBox(
              height: 200,
              child: Text('Nicene Content'),
            ),
            apostlesCard: const SizedBox(
              height: 200,
              child: Text('Apostles Content'),
            ),
            onPageChanged: (page) => changedPage = page,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('Nicene Creed'), findsOneWidget);
        expect(find.text('Apostles\' Creed'), findsOneWidget);
        expect(find.text('Nicene Content'), findsOneWidget);
        expect(find.text('Apostles Content'), findsOneWidget);

        // Swipe left to transition to page 1 (Apostles' Creed)
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(changedPage, 1);

        // Tap the Nicene Creed chip to transition back
        final niceneChip = find.widgetWithText(InkWell, 'Nicene Creed');
        await tester.tap(niceneChip);
        await tester.pumpAndSettle();

        expect(changedPage, 0);
      },
    );

    testWidgets('tapping indicator chip smoothly navigates pages', (
      tester,
    ) async {
      int? changedPage;
      await tester.pumpWidget(
        buildTestableCarousel(
          niceneCard: const Text('Card 1'),
          apostlesCard: const Text('Card 2'),
          onPageChanged: (p) => changedPage = p,
        ),
      );
      await tester.pumpAndSettle();

      final apostlesChip = find.widgetWithText(InkWell, 'Apostles\' Creed');
      await tester.tap(apostlesChip);
      await tester.pumpAndSettle();

      expect(changedPage, 1);
    });
  });
}
