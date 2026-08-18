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
      'renders PageView with both cards, default page 0 and swipe navigation',
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
        expect(find.text('Nicene Content'), findsOneWidget);

        // Swipe left to transition to page 1 (Apostles' Creed)
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();

        expect(changedPage, 1);
        expect(find.text('Apostles Content'), findsOneWidget);

        // Swipe right to transition back to page 0 (Nicene Creed)
        await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
        await tester.pumpAndSettle();

        expect(changedPage, 0);
        expect(find.text('Nicene Content'), findsOneWidget);
      },
    );

    testWidgets('renders cards with full width matching parent container', (
      tester,
    ) async {
      const parentWidth = 360.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: parentWidth,
                child: MissalCreedCarousel(
                  niceneCard: Container(
                    key: const Key('nicene_container'),
                    height: 100,
                    color: Colors.blue,
                  ),
                  apostlesCard: Container(
                    key: const Key('apostles_container'),
                    height: 100,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final niceneBox = tester.getRect(
        find.byKey(const Key('nicene_container')),
      );
      expect(niceneBox.width, equals(parentWidth));
    });
  });
}
