import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';
import 'package:twelve_stars/widgets/reader/bible_ribbons_widget.dart';

void main() {
  group('BibleRibbonsWidget Tests', () {
    testWidgets(
      'renders all 4 ribbons with correct liturgical colors and default unassigned state',
      (WidgetTester tester) async {
        int? tappedIndex;
        BibleRibbonBookmark? tappedBookmark;
        int? longPressedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleRibbonsWidget(
                bookmarks: null,
                onRibbonTap: (index, bookmark) {
                  tappedIndex = index;
                  tappedBookmark = bookmark;
                },
                onRibbonLongPress: (index) {
                  longPressedIndex = index;
                },
              ),
            ),
          ),
        );

        for (int i = 0; i < 4; i++) {
          expect(find.byKey(Key('bible_ribbon_$i')), findsOneWidget);
          expect(
            find.byTooltip('Ribbon ${i + 1}: Unassigned (Long press to set)'),
            findsOneWidget,
          );
        }

        // Check physical shape colors
        final physicalShapes = tester
            .widgetList<PhysicalShape>(find.byType(PhysicalShape))
            .toList();
        expect(physicalShapes.length, equals(4));

        expect(
          physicalShapes[0].color,
          equals(AppThemeTokens.liturgicalRed.withValues(alpha: 0.35)),
        );
        expect(
          physicalShapes[1].color,
          equals(AppThemeTokens.liturgicalGold.withValues(alpha: 0.35)),
        );
        expect(
          physicalShapes[2].color,
          equals(AppThemeTokens.liturgicalGreen.withValues(alpha: 0.35)),
        );
        expect(
          physicalShapes[3].color,
          equals(AppThemeTokens.liturgicalPurple.withValues(alpha: 0.35)),
        );

        // Tap unassigned ribbon
        await tester.tap(find.byKey(const Key('bible_ribbon_1')));
        expect(tappedIndex, equals(1));
        expect(tappedBookmark, isNull);

        // Long press ribbon
        await tester.longPress(find.byKey(const Key('bible_ribbon_2')));
        expect(longPressedIndex, equals(2));
      },
    );

    testWidgets(
      'renders assigned ribbons with full color, shadow elevation, and correct tooltip',
      (WidgetTester tester) async {
        int? tappedIndex;
        BibleRibbonBookmark? tappedBookmark;

        final bookmarks = [
          const BibleRibbonBookmark(
            ribbonIndex: 0,
            bookNumber: 49,
            chapter: 26,
          ),
          const BibleRibbonBookmark(ribbonIndex: 2, bookNumber: 1, chapter: 1),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleRibbonsWidget(
                bookmarks: bookmarks,
                onRibbonTap: (index, bookmark) {
                  tappedIndex = index;
                  tappedBookmark = bookmark;
                },
                onRibbonLongPress: (_) {},
              ),
            ),
          ),
        );

        // Ribbon 0 is assigned to Matthew (49) 26
        expect(find.byTooltip('Red Ribbon: Matthew 26'), findsOneWidget);
        // Ribbon 1 is unassigned
        expect(
          find.byTooltip('Ribbon 2: Unassigned (Long press to set)'),
          findsOneWidget,
        );
        // Ribbon 2 is assigned to Genesis (1) 1
        expect(find.byTooltip('Green Ribbon: Genesis 1'), findsOneWidget);
        // Ribbon 3 is unassigned
        expect(
          find.byTooltip('Ribbon 4: Unassigned (Long press to set)'),
          findsOneWidget,
        );

        final physicalShapes = tester
            .widgetList<PhysicalShape>(find.byType(PhysicalShape))
            .toList();

        expect(physicalShapes[0].color, equals(AppThemeTokens.liturgicalRed));
        expect(physicalShapes[0].elevation, equals(2.0));

        expect(
          physicalShapes[1].color,
          equals(AppThemeTokens.liturgicalGold.withValues(alpha: 0.35)),
        );
        expect(physicalShapes[1].elevation, equals(0.0));

        expect(physicalShapes[2].color, equals(AppThemeTokens.liturgicalGreen));
        expect(physicalShapes[2].elevation, equals(2.0));

        expect(
          physicalShapes[3].color,
          equals(AppThemeTokens.liturgicalPurple.withValues(alpha: 0.35)),
        );
        expect(physicalShapes[3].elevation, equals(0.0));

        // Tap assigned ribbon 0
        await tester.tap(find.byKey(const Key('bible_ribbon_0')));
        expect(tappedIndex, equals(0));
        expect(tappedBookmark, equals(bookmarks[0]));
      },
    );

    test(
      'RibbonClipper produces expected path with notch and does not reclip',
      () {
        const clipper = RibbonClipper();
        const size = Size(16.0, 38.0);
        final path = clipper.getClip(size);

        expect(path, isNotNull);
        expect(path.contains(const Offset(8.0, 10.0)), isTrue);
        // The notch cuts out the bottom center (8.0, 37.0)
        expect(path.contains(const Offset(8.0, 37.0)), isFalse);

        expect(clipper.shouldReclip(const RibbonClipper()), isFalse);
      },
    );

    test(
      'PageRibbonClipper produces expected full-length vertical path with bottom notch and does not reclip',
      () {
        const clipper = PageRibbonClipper();
        const size = Size(8.0, 600.0);
        final path = clipper.getClip(size);

        expect(path, isNotNull);
        expect(path.contains(const Offset(4.0, 10.0)), isTrue);
        expect(path.contains(const Offset(4.0, 300.0)), isTrue);
        // The notch cuts out bottom center (4.0, 598.0)
        expect(path.contains(const Offset(4.0, 598.0)), isFalse);

        expect(clipper.shouldReclip(const PageRibbonClipper()), isFalse);
      },
    );

    testWidgets(
      'BiblePageRibbonsWidget renders nothing for null or unbookmarked chapters',
      (WidgetTester tester) async {
        // 1. Null bookmarks
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  BiblePageRibbonsWidget(
                    bookmarks: null,
                    bookNumber: 1,
                    chapter: 1,
                  ),
                ],
              ),
            ),
          ),
        );
        expect(find.byType(BiblePageRibbon), findsNothing);

        // 2. Bookmarks for a different chapter
        const bookmarks = [
          BibleRibbonBookmark(ribbonIndex: 0, bookNumber: 1, chapter: 2),
          BibleRibbonBookmark(ribbonIndex: 1, bookNumber: 2, chapter: 1),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  BiblePageRibbonsWidget(
                    bookmarks: bookmarks,
                    bookNumber: 1,
                    chapter: 1,
                  ),
                ],
              ),
            ),
          ),
        );
        expect(find.byType(BiblePageRibbon), findsNothing);
      },
    );

    testWidgets(
      'BiblePageRibbonsWidget renders ribbon with matching color and key for bookmarked chapter',
      (WidgetTester tester) async {
        const bookmarks = [
          BibleRibbonBookmark(ribbonIndex: 0, bookNumber: 1, chapter: 1),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  BiblePageRibbonsWidget(
                    bookmarks: bookmarks,
                    bookNumber: 1,
                    chapter: 1,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('bible_page_ribbon_0')), findsOneWidget);
        final physicalShape = tester.widget<PhysicalShape>(
          find.byKey(const Key('bible_page_ribbon_0')),
        );
        expect(physicalShape.color, equals(AppThemeTokens.liturgicalRed));
        expect(physicalShape.elevation, equals(2.0));
      },
    );

    testWidgets(
      'BiblePageRibbonsWidget renders multiple ribbons side-by-side when multiple bookmarks match the same chapter',
      (WidgetTester tester) async {
        const bookmarks = [
          BibleRibbonBookmark(ribbonIndex: 3, bookNumber: 19, chapter: 23),
          BibleRibbonBookmark(ribbonIndex: 1, bookNumber: 19, chapter: 23),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  BiblePageRibbonsWidget(
                    bookmarks: bookmarks,
                    bookNumber: 19,
                    chapter: 23,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('bible_page_ribbon_1')), findsOneWidget);
        expect(find.byKey(const Key('bible_page_ribbon_3')), findsOneWidget);

        final ribbons = tester
            .widgetList<BiblePageRibbon>(find.byType(BiblePageRibbon))
            .toList();
        expect(ribbons.length, equals(2));
        // Bookmarks should be sorted by ribbonIndex
        expect(ribbons[0].ribbonIndex, equals(1));
        expect(ribbons[1].ribbonIndex, equals(3));

        final physicalShapes = tester
            .widgetList<PhysicalShape>(find.byType(PhysicalShape))
            .toList();
        expect(physicalShapes[0].color, equals(AppThemeTokens.liturgicalGold));
        expect(
          physicalShapes[1].color,
          equals(AppThemeTokens.liturgicalPurple),
        );
      },
    );
  });
}
