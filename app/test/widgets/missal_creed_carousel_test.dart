import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/missal_creed_carousel.dart';
import '../test_helper.dart';

void main() {
  Widget buildTestableCarousel({
    Widget? niceneCard,
    Widget? apostlesCard,
    ScrollController? controller,
    ValueChanged<int>? onPageChanged,
    double peekOffset = 24.0,
    double cardGap = 8.0,
    int initialPage = 0,
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
              peekOffset: peekOffset,
              cardGap: cardGap,
              initialPage: initialPage,
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
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('renders directly when only one card is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableCarousel(niceneCard: const Text('Sole Nicene Card')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sole Nicene Card'), findsOneWidget);
      expect(find.byKey(const Key('nicene_card_wrapper')), findsNothing);

      await tester.pumpWidget(
        buildTestableCarousel(apostlesCard: const Text('Sole Apostles Card')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sole Apostles Card'), findsOneWidget);
      expect(find.byKey(const Key('apostles_card_wrapper')), findsNothing);
    });

    testWidgets(
      'renders without indicator chips, aligns Nicene Creed left on page 0 with Apostles Creed peeking, and aligns Apostles Creed right on page 1 with Nicene Creed peeking',
      (tester) async {
        const containerWidth = 400.0;
        const peekOffset = 24.0;
        const cardGap = 8.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: containerWidth,
                  child: MissalCreedCarousel(
                    peekOffset: peekOffset,
                    cardGap: cardGap,
                    niceneCard: Container(
                      key: const Key('nicene_content'),
                      height: 200,
                      color: Colors.blue,
                      child: const Text('Nicene Content'),
                    ),
                    apostlesCard: Container(
                      key: const Key('apostles_content'),
                      height: 200,
                      color: Colors.red,
                      child: const Text('Apostles Content'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify NO indicator chips exist
        expect(find.byKey(const Key('nicene_creed_chip')), findsNothing);
        expect(find.byKey(const Key('apostles_creed_chip')), findsNothing);
        expect(find.byType(ChoiceChip), findsNothing);

        // 2. On Page 0 (Nicene Creed active):
        // Container rect
        final carouselFinder = find.byType(MissalCreedCarousel);
        final carouselRect = tester.getRect(carouselFinder);
        final niceneWrapperRect = tester.getRect(
          find.byKey(const Key('nicene_card_wrapper')),
        );
        final apostlesWrapperRect = tester.getRect(
          find.byKey(const Key('apostles_card_wrapper')),
        );

        // Nicene left edge aligns with carousel left edge
        expect(niceneWrapperRect.left, closeTo(carouselRect.left, 0.1));
        // Nicene card width is (containerWidth - peekOffset - cardGap)
        const expectedCardWidth = containerWidth - peekOffset - cardGap;
        expect(niceneWrapperRect.width, closeTo(expectedCardWidth, 0.1));

        // Apostles card starts at right edge minus peekOffset
        expect(
          apostlesWrapperRect.left,
          closeTo(carouselRect.right - peekOffset, 0.1),
        );

        // 3. Tap on the peeking Apostles Creed card to focus it
        final apostlesPeekingTapFinder = find.byKey(
          const Key('apostles_creed_peeking_tap'),
        );
        expect(apostlesPeekingTapFinder, findsOneWidget);
        await tester.tap(apostlesPeekingTapFinder);
        await tester.pumpAndSettle();

        // On Page 1 (Apostles Creed active):
        final niceneWrapperRectPage1 = tester.getRect(
          find.byKey(const Key('nicene_card_wrapper')),
        );
        final apostlesWrapperRectPage1 = tester.getRect(
          find.byKey(const Key('apostles_card_wrapper')),
        );

        // Apostles Creed right edge aligns with carousel right edge
        expect(
          apostlesWrapperRectPage1.right,
          closeTo(carouselRect.right, 0.1),
        );
        // Nicene Creed peeks on the left from left edge with width peekOffset
        expect(
          niceneWrapperRectPage1.right,
          closeTo(carouselRect.left + peekOffset, 0.1),
        );

        // 4. Tap on the peeking Nicene Creed card to switch back to page 0
        final nicenePeekingTapFinder = find.byKey(
          const Key('nicene_creed_peeking_tap'),
        );
        expect(nicenePeekingTapFinder, findsOneWidget);
        await tester.tap(nicenePeekingTapFinder);
        await tester.pumpAndSettle();

        // Back on Page 0:
        final niceneWrapperRectPage0Again = tester.getRect(
          find.byKey(const Key('nicene_card_wrapper')),
        );
        expect(
          niceneWrapperRectPage0Again.left,
          closeTo(carouselRect.left, 0.1),
        );
      },
    );

    testWidgets('supports horizontal swipe gesture navigation', (tester) async {
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

      expect(find.text('Nicene Content'), findsOneWidget);

      // Swipe left to transition to page 1 (Apostles Creed)
      await tester.drag(
        find.byKey(const Key('nicene_card_wrapper')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      expect(changedPage, 1);

      // Swipe right to transition back to page 0 (Nicene Creed)
      await tester.drag(
        find.byKey(const Key('apostles_card_wrapper')),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();

      expect(changedPage, 0);
    });

    testWidgets(
      'handles didUpdateWidget when controller changes and cleanly disposes owned controller',
      (tester) async {
        final externalController = ScrollController();

        await tester.pumpWidget(
          buildTestableCarousel(
            niceneCard: const Text('Nicene'),
            apostlesCard: const Text('Apostles'),
          ),
        );
        await tester.pumpAndSettle();

        // Update with external controller
        await tester.pumpWidget(
          buildTestableCarousel(
            niceneCard: const Text('Nicene'),
            apostlesCard: const Text('Apostles'),
            controller: externalController,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MissalCreedCarousel), findsOneWidget);
        externalController.dispose();
      },
    );

    testGoldens(
      'MissalCreedCarousel renders Nicene and Apostles Creeds in focused and peeking states',
      (tester) async {
        final niceneCard = PrayerCard(
          prayer: Prayer.mock(
            id: 'nicene_creed',
            defaultTitle: 'Nicene Creed',
            translations: {
              PrayerLanguage.english: [
                PrayerTranslation.mock(
                  title: 'Nicene Creed',
                  subtitle: 'Symbol of Faith',
                  text:
                      'I believe in one God, the Father almighty, maker of heaven and earth, of all things visible and invisible. I believe in one Lord Jesus Christ, the Only Begotten Son of God...',
                  sourceName: 'Vatican',
                  sourceUrl: 'https://vatican.va',
                ),
              ],
            },
          ),
          selectedLanguage: PrayerLanguage.english,
          initialVersionIndex: 0,
          onVersionChanged: (_) {},
          onLaunchSource: (_) {},
        );

        final apostlesCard = PrayerCard(
          prayer: Prayer.mock(
            id: 'apostles_creed',
            defaultTitle: 'Apostles\' Creed',
            translations: {
              PrayerLanguage.english: [
                PrayerTranslation.mock(
                  title: 'Apostles\' Creed',
                  subtitle: 'Profession of Faith',
                  text:
                      'I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord...',
                  sourceName: 'Vatican',
                  sourceUrl: 'https://vatican.va',
                ),
              ],
            },
          ),
          selectedLanguage: PrayerLanguage.english,
          initialVersionIndex: 0,
          onVersionChanged: (_) {},
          onLaunchSource: (_) {},
        );

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: MissalCreedCarousel(
                  niceneCard: niceneCard,
                  apostlesCard: apostlesCard,
                  initialPage: 0,
                ),
              ),
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 450),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'missal_creed_carousel_nicene_golden',
          customPump: (tester) async => await tester.pump(),
        );

        // Tap peeking Apostles' Creed card
        await tester.tap(find.byKey(const Key('apostles_creed_peeking_tap')));
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'missal_creed_carousel_apostles_golden',
          customPump: (tester) async => await tester.pump(),
        );
      },
    );
  });
}
