import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/calendar_tab.dart';
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:drift/native.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import '../test_helper.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() async {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    await testDb.ensurePopulated();
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Placeholder Tabs Golden Tests', () {
    testGoldens('CalendarTab renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Calendar Tab Placeholder',
          SizedBox(
            height: 600,
            child: Scaffold(
              body: CalendarTab(initialDate: DateTime(2026, 7, 2)),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'calendar_tab_placeholder_golden');
    });

    testGoldens('MissalTab renders correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Missal Tab Placeholder',
          const SizedBox(height: 600, child: Scaffold(body: MissalTab())),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'missal_tab_placeholder_golden');
    });
  });

  group('CalendarTab Interactive Widget Tests', () {
    testWidgets('allows month navigation and day selection', (tester) async {
      final fixedDate = DateTime(2026, 7, 2); // Thursday in Ordinary Time
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: CalendarTab(initialDate: fixedDate)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State Check
      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);
      expect(find.text('July 2026'), findsOneWidget);
      expect(find.textContaining('13th Week in Ordinary Time'), findsWidgets);

      // 2. Next Month Navigation
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();

      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Sunday, August 2, 2026'), findsOneWidget);

      // 3. Grid Cell Selection (Select Assumption of BVM - Aug 15)
      // Note: Cell text is '15'.
      final cell15 = find.widgetWithText(InkWell, '15');
      expect(cell15, findsOneWidget);
      await tester.tap(cell15);
      await tester.pumpAndSettle();

      expect(find.text('Saturday, August 15, 2026'), findsOneWidget);
      expect(
        find.text('The Assumption of the Blessed Virgin Mary'),
        findsOneWidget,
      );
    });

    testWidgets('Today FAB visibility and click behavior', (tester) async {
      // Initialize with today's real date to test FAB visibility
      final today = DateTime.now();

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: CalendarTab(initialDate: today)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Today is selected initially -> Today FAB should NOT be visible
      expect(find.widgetWithText(FloatingActionButton, 'Today'), findsNothing);

      // 2. Navigate away -> Today FAB should become visible
      await tester.tap(find.byTooltip('Next Day'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FloatingActionButton, 'Today'),
        findsOneWidget,
      );

      // 3. Tap Today FAB -> selection returns to today, FAB is hidden again
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Today'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FloatingActionButton, 'Today'), findsNothing);
    });

    testWidgets('Next Sunday FAB jumps to next Sunday', (tester) async {
      final fixedDate = DateTime(2026, 7, 2); // Thursday
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: CalendarTab(initialDate: fixedDate)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial date display is Thursday, July 2
      expect(find.text('Thursday, July 2, 2026'), findsOneWidget);

      // 2. Tap Next Sunday FAB -> date should jump to Sunday, July 5
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Next Sunday'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday, July 5, 2026'), findsOneWidget);

      // 3. Tap it again -> date should jump to Sunday, July 12
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Next Sunday'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday, July 12, 2026'), findsOneWidget);
    });
  });
}
