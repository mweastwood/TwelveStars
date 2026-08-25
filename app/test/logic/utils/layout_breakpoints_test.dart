import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';

void main() {
  group('LayoutBreakpoints', () {
    test('kWideScreenBreakpoint constant is defined as 600.0', () {
      expect(kWideScreenBreakpoint, 600.0);
    });

    group('isWideScreen', () {
      Future<bool> checkIsWideScreen(
        WidgetTester tester,
        double width, {
        double height = 800.0,
      }) async {
        late bool result;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, height)),
            child: Builder(
              builder: (context) {
                result = isWideScreen(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        return result;
      }

      group('Narrow viewports (< 600.0)', () {
        final testCases = <String, double>{
          'compact phone (320.0)': 320.0,
          'standard phone (480.0)': 480.0,
          'just below breakpoint boundary (599.9)': 599.9,
        };

        for (final entry in testCases.entries) {
          testWidgets('returns false for ${entry.key}', (tester) async {
            final isWide = await checkIsWideScreen(tester, entry.value);
            expect(isWide, isFalse);
          });
        }
      });

      group('Exact breakpoint boundary (= 600.0)', () {
        testWidgets('returns true at exact breakpoint (600.0)', (tester) async {
          final isWide = await checkIsWideScreen(tester, 600.0);
          expect(isWide, isTrue);
        });
      });

      group('Wide viewports (> 600.0)', () {
        final testCases = <String, double>{
          'just above breakpoint boundary (600.1)': 600.1,
          'tablet portrait (800.0)': 800.0,
          'tablet landscape / small desktop (1024.0)': 1024.0,
          'desktop full HD (1920.0)': 1920.0,
        };

        for (final entry in testCases.entries) {
          testWidgets('returns true for ${entry.key}', (tester) async {
            final isWide = await checkIsWideScreen(tester, entry.value);
            expect(isWide, isTrue);
          });
        }
      });
    });
  });
}
