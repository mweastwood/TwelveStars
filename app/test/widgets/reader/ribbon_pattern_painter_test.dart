import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/reader/ribbon_pattern_painter.dart';

void main() {
  group('RibbonClipper', () {
    test(
      'getClip produces expected path with bottom notch and rounded top',
      () {
        const clipper = RibbonClipper();
        const size = Size(16.0, 38.0);
        final path = clipper.getClip(size);

        expect(path.getBounds(), equals(const Rect.fromLTWH(0, 0, 16.0, 38.0)));
        expect(path.contains(const Offset(8.0, 10.0)), isTrue);
        // Bottom notch cuts out the center bottom area
        expect(path.contains(const Offset(8.0, 37.0)), isFalse);
        // Bottom corners remain inside
        expect(path.contains(const Offset(1.0, 36.0)), isTrue);
        expect(path.contains(const Offset(15.0, 36.0)), isTrue);
      },
    );

    test('shouldReclip always returns false', () {
      const clipper = RibbonClipper();
      expect(clipper.shouldReclip(const RibbonClipper()), isFalse);
    });
  });

  group('PageRibbonClipper', () {
    test('getClip produces full-length vertical path with bottom notch', () {
      const clipper = PageRibbonClipper();
      const size = Size(16.0, 400.0);
      final path = clipper.getClip(size);

      expect(path.getBounds(), equals(const Rect.fromLTWH(0, 0, 16.0, 400.0)));
      expect(path.contains(const Offset(8.0, 1.0)), isTrue);
      expect(path.contains(const Offset(8.0, 200.0)), isTrue);
      // Bottom notch cuts out the center bottom area
      expect(path.contains(const Offset(8.0, 398.0)), isFalse);
    });

    test('shouldReclip always returns false', () {
      const clipper = PageRibbonClipper();
      expect(clipper.shouldReclip(const PageRibbonClipper()), isFalse);
    });
  });

  group('PageRibbonPatternPainter', () {
    test(
      'shouldRepaint detects changes in ribbonIndex, stripeColor, and edgeColor',
      () {
        const base = PageRibbonPatternPainter(
          ribbonIndex: 0,
          stripeColor: Color(0x24FFFFFF),
          edgeColor: Color(0x1A000000),
        );
        const identical = PageRibbonPatternPainter(
          ribbonIndex: 0,
          stripeColor: Color(0x24FFFFFF),
          edgeColor: Color(0x1A000000),
        );
        const differentIndex = PageRibbonPatternPainter(
          ribbonIndex: 2,
          stripeColor: Color(0x24FFFFFF),
          edgeColor: Color(0x1A000000),
        );
        const differentStripe = PageRibbonPatternPainter(
          ribbonIndex: 0,
          stripeColor: Color(0x44FFFFFF),
          edgeColor: Color(0x1A000000),
        );
        const differentEdge = PageRibbonPatternPainter(
          ribbonIndex: 0,
          stripeColor: Color(0x24FFFFFF),
          edgeColor: Color(0x33000000),
        );

        expect(base.shouldRepaint(identical), isFalse);
        expect(base.shouldRepaint(differentIndex), isTrue);
        expect(base.shouldRepaint(differentStripe), isTrue);
        expect(base.shouldRepaint(differentEdge), isTrue);
      },
    );

    test('paint handles degenerate sizes and caches LRU patterns cleanly', () {
      const painter = PageRibbonPatternPainter(ribbonIndex: 0);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, Size.zero), returnsNormally);
      expect(
        () => painter.paint(canvas, const Size(-5.0, 100.0)),
        returnsNormally,
      );
      expect(
        () => painter.paint(canvas, const Size(16.0, double.infinity)),
        returnsNormally,
      );

      for (int i = 0; i < 20; i++) {
        final p = PageRibbonPatternPainter(ribbonIndex: i % 5);
        final size = Size(16.0, 80.0 + i * 5.0);
        expect(() => p.paint(canvas, size), returnsNormally);
        expect(() => p.paint(canvas, size), returnsNormally);
      }

      recorder.endRecording();
    });

    for (var patternIndex = 0; patternIndex <= 4; patternIndex++) {
      testWidgets(
        'renders pattern index $patternIndex inside CustomPaint without errors',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 16.0,
                    height: 120.0,
                    child: CustomPaint(
                      key: ValueKey('ribbon_paint_$patternIndex'),
                      painter: PageRibbonPatternPainter(
                        ribbonIndex: patternIndex,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(ValueKey('ribbon_paint_$patternIndex')),
            findsOneWidget,
          );
        },
      );
    }
  });
}
