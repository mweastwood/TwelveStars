import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/time_helper.dart';
import 'package:twelve_stars/widgets/missal_calendar_grid.dart';
import '../test_helper.dart';

void main() {
  // Test Fixtures & Mock Builders
  String formatMonthYear(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  String formatFullDate(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<DateTime> generateWeekDays(DateTime date) {
    final startOffset = date.weekday % 7; // Sunday is 0
    final startOfWeek = DateTime(date.year, date.month, date.day - startOffset);
    return List.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );
  }

  List<DateTime> generateMonthGrid(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final startOffset = firstDayOfMonth.weekday % 7; // Sunday is 0
    final firstGridDay = DateTime(
      firstDayOfMonth.year,
      firstDayOfMonth.month,
      firstDayOfMonth.day - startOffset,
    );
    return List.generate(
      42,
      (index) => DateTime(
        firstGridDay.year,
        firstGridDay.month,
        firstGridDay.day + index,
      ),
    );
  }

  Widget buildCalendarWidget({
    required DateTime selectedDate,
    bool isExpanded = false,
    ValueChanged<DateTime>? onDateSelected,
    ValueChanged<int>? onMonthChange,
    ValueChanged<int>? onDayChange,
    VoidCallback? onToggleExpand,
    String Function(DateTime)? customFormatMonthYear,
    String Function(DateTime)? customFormatFullDate,
    List<DateTime> Function(DateTime)? customGenerateWeekDays,
    List<DateTime> Function(DateTime)? customGenerateMonthGrid,
    bool Function(DateTime)? hasSaintFeast,
  }) {
    return buildTestableWidget(
      child: Scaffold(
        body: SingleChildScrollView(
          child: MissalCalendarGrid(
            selectedDate: selectedDate,
            isExpanded: isExpanded,
            onDateSelected: onDateSelected ?? (_) {},
            onMonthChange: onMonthChange ?? (_) {},
            onDayChange: onDayChange ?? (_) {},
            onToggleExpand: onToggleExpand ?? () {},
            formatMonthYear: customFormatMonthYear ?? formatMonthYear,
            formatFullDate: customFormatFullDate ?? formatFullDate,
            generateWeekDays: customGenerateWeekDays ?? generateWeekDays,
            generateMonthGrid: customGenerateMonthGrid ?? generateMonthGrid,
            hasSaintFeast: hasSaintFeast,
          ),
        ),
      ),
    );
  }

  group('MissalCalendarGrid Widget Tests', () {
    tearDown(() {
      TimeHelper.setCustomTime(null);
    });

    group('1. Header & Weekday Labels', () {
      testWidgets('renders correctly in collapsed mode (isExpanded: false)', (
        tester,
      ) async {
        final testDate = DateTime(2026, 8, 25);
        await tester.pumpWidget(
          buildCalendarWidget(selectedDate: testDate, isExpanded: false),
        );
        await tester.pumpAndSettle();

        // Verify full date text is displayed
        expect(find.text('August 25, 2026'), findsOneWidget);

        // Verify collapse/expand dropdown icon
        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
        expect(find.byIcon(Icons.arrow_drop_up), findsNothing);

        // Verify previous/next day buttons and tooltips
        expect(find.byTooltip('Previous Day'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byTooltip('Next Day'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        // Verify all 7 weekday column headers render in order
        final expectedWeekdays = [
          'Sun',
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
        ];
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .where((t) => expectedWeekdays.contains(t))
            .toList();

        expect(texts, equals(expectedWeekdays));
      });

      testWidgets('renders correctly in expanded mode (isExpanded: true)', (
        tester,
      ) async {
        final testDate = DateTime(2026, 8, 25);
        await tester.pumpWidget(
          buildCalendarWidget(selectedDate: testDate, isExpanded: true),
        );
        await tester.pumpAndSettle();

        // Verify month/year text is displayed
        expect(find.text('August 2026'), findsOneWidget);
        expect(find.text('August 25, 2026'), findsNothing);

        // Verify collapse/expand dropdown icon
        expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
        expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

        // Verify previous/next month buttons and tooltips
        expect(find.byTooltip('Previous Month'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
        expect(find.byTooltip('Next Month'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
      });
    });

    group('2. Navigation Actions & Callbacks', () {
      testWidgets('triggers onDayChange on navigation in collapsed mode', (
        tester,
      ) async {
        int dayChangeDelta = 0;
        int monthChangeDelta = 0;

        await tester.pumpWidget(
          buildCalendarWidget(
            selectedDate: DateTime(2026, 8, 25),
            isExpanded: false,
            onDayChange: (delta) => dayChangeDelta = delta,
            onMonthChange: (delta) => monthChangeDelta = delta,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Previous Day
        await tester.tap(find.byTooltip('Previous Day'));
        await tester.pump();
        expect(dayChangeDelta, equals(-1));
        expect(monthChangeDelta, equals(0));

        // Tap Next Day
        await tester.tap(find.byTooltip('Next Day'));
        await tester.pump();
        expect(dayChangeDelta, equals(1));
        expect(monthChangeDelta, equals(0));
      });

      testWidgets('triggers onMonthChange on navigation in expanded mode', (
        tester,
      ) async {
        int dayChangeDelta = 0;
        int monthChangeDelta = 0;

        await tester.pumpWidget(
          buildCalendarWidget(
            selectedDate: DateTime(2026, 8, 25),
            isExpanded: true,
            onDayChange: (delta) => dayChangeDelta = delta,
            onMonthChange: (delta) => monthChangeDelta = delta,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Previous Month
        await tester.tap(find.byTooltip('Previous Month'));
        await tester.pump();
        expect(monthChangeDelta, equals(-1));
        expect(dayChangeDelta, equals(0));

        // Tap Next Month
        await tester.tap(find.byTooltip('Next Month'));
        await tester.pump();
        expect(monthChangeDelta, equals(1));
        expect(dayChangeDelta, equals(0));
      });

      testWidgets('triggers onToggleExpand when header title is tapped', (
        tester,
      ) async {
        bool expandToggled = false;

        await tester.pumpWidget(
          buildCalendarWidget(
            selectedDate: DateTime(2026, 8, 25),
            isExpanded: false,
            onToggleExpand: () => expandToggled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap header title area
        await tester.tap(find.text('August 25, 2026'));
        await tester.pump();
        expect(expandToggled, isTrue);
      });
    });

    group('3. Date Selection & Day Cells', () {
      testWidgets('taps unselected day cell in collapsed week row', (
        tester,
      ) async {
        DateTime? selectedDateResult;
        final selectedDate = DateTime(2026, 8, 25); // Tuesday

        await tester.pumpWidget(
          buildCalendarWidget(
            selectedDate: selectedDate,
            isExpanded: false,
            onDateSelected: (date) => selectedDateResult = date,
          ),
        );
        await tester.pumpAndSettle();

        // Scope to week row (Row within AnimatedCrossFade)
        final weekRow = find.descendant(
          of: find.byType(AnimatedCrossFade),
          matching: find.byType(Row),
        );
        final day24Text = find.descendant(
          of: weekRow,
          matching: find.text('24'),
        );

        // Tap 24 (Monday)
        await tester.tap(day24Text);
        await tester.pump();

        expect(selectedDateResult, equals(DateTime(2026, 8, 24)));
      });

      testWidgets('taps day cell in expanded month grid', (tester) async {
        DateTime? selectedDateResult;
        final selectedDate = DateTime(2026, 8, 25);

        await tester.pumpWidget(
          buildCalendarWidget(
            selectedDate: selectedDate,
            isExpanded: true,
            onDateSelected: (date) => selectedDateResult = date,
          ),
        );
        await tester.pumpAndSettle();

        // Tap day 10 of current month in GridView
        final day10Text = find.descendant(
          of: find.byType(GridView),
          matching: find.text('10'),
        );
        await tester.tap(day10Text);
        await tester.pump();

        expect(selectedDateResult, equals(DateTime(2026, 8, 10)));
      });

      testWidgets(
        'renders SizedBox.shrink for out-of-month dates in expanded month grid',
        (tester) async {
          final selectedDate = DateTime(2026, 8, 25);

          await tester.pumpWidget(
            buildCalendarWidget(selectedDate: selectedDate, isExpanded: true),
          );
          await tester.pumpAndSettle();

          // In August 2026, Aug 1 is Saturday (offset 6: Jul 26..31 out of month)
          // Total month days: 31, grid items: 42, out-of-month: 11
          final shrinkSizedBoxes = tester
              .widgetList<SizedBox>(
                find.descendant(
                  of: find.byType(GridView),
                  matching: find.byType(SizedBox),
                ),
              )
              .where((box) => box.width == 0.0 && box.height == 0.0)
              .toList();

          expect(shrinkSizedBoxes.length, equals(11));
        },
      );

      testWidgets('selected day cell has highlight border and bold text', (
        tester,
      ) async {
        final selectedDate = DateTime(2026, 8, 25);
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MissalCalendarGrid(
                selectedDate: selectedDate,
                isExpanded: false,
                onDateSelected: (_) {},
                onMonthChange: (_) {},
                onDayChange: (_) {},
                onToggleExpand: () {},
                formatMonthYear: formatMonthYear,
                formatFullDate: formatFullDate,
                generateWeekDays: generateWeekDays,
                generateMonthGrid: generateMonthGrid,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final weekRow = find.descendant(
          of: find.byType(AnimatedCrossFade),
          matching: find.byType(Row),
        );
        final day25TextFinder = find.descendant(
          of: weekRow,
          matching: find.text('25'),
        );

        // Check text style of selected day '25'
        final text25 = tester.widget<Text>(day25TextFinder);
        expect(text25.style?.fontWeight, equals(FontWeight.bold));

        // Check border decoration of selected day '25'
        final inkWell = tester.widget<InkWell>(
          find.ancestor(of: day25TextFinder, matching: find.byType(InkWell)),
        );
        final container = inkWell.child as Container;
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
        expect(decoration.border?.top.color, equals(theme.colorScheme.primary));
        expect(decoration.border?.top.width, equals(2.0));
      });

      testWidgets('today day cell receives outline border and bold text', (
        tester,
      ) async {
        TimeHelper.setCustomTime(DateTime(2026, 8, 24));
        final selectedDate = DateTime(2026, 8, 25); // Different from today
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MissalCalendarGrid(
                selectedDate: selectedDate,
                isExpanded: false,
                onDateSelected: (_) {},
                onMonthChange: (_) {},
                onDayChange: (_) {},
                onToggleExpand: () {},
                formatMonthYear: formatMonthYear,
                formatFullDate: formatFullDate,
                generateWeekDays: generateWeekDays,
                generateMonthGrid: generateMonthGrid,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final weekRow = find.descendant(
          of: find.byType(AnimatedCrossFade),
          matching: find.byType(Row),
        );
        final day24TextFinder = find.descendant(
          of: weekRow,
          matching: find.text('24'),
        );

        // Check today day '24' has bold text
        final text24 = tester.widget<Text>(day24TextFinder);
        expect(text24.style?.fontWeight, equals(FontWeight.bold));

        // Check today day '24' has outlineVariant border
        final inkWell24 = tester.widget<InkWell>(
          find.ancestor(of: day24TextFinder, matching: find.byType(InkWell)),
        );
        final container24 = inkWell24.child as Container;
        final decoration24 = container24.decoration as BoxDecoration;
        expect(decoration24.border, isNotNull);
        expect(
          decoration24.border?.top.color,
          equals(theme.colorScheme.outlineVariant),
        );
        expect(decoration24.border?.top.width, equals(1.0));

        // Check non-today, non-selected day '26' has normal weight and no border
        final day26TextFinder = find.descendant(
          of: weekRow,
          matching: find.text('26'),
        );
        final text26 = tester.widget<Text>(day26TextFinder);
        expect(text26.style?.fontWeight, equals(FontWeight.normal));

        final inkWell26 = tester.widget<InkWell>(
          find.ancestor(of: day26TextFinder, matching: find.byType(InkWell)),
        );
        final container26 = inkWell26.child as Container;
        final decoration26 = container26.decoration as BoxDecoration;
        expect(decoration26.border, isNull);
      });
    });

    group('4. Liturgical Color & Feast Day Indicators', () {
      testWidgets(
        'renders liturgical color indicator bar and tinted cell background',
        (tester) async {
          // August 15 is Solemnity of Assumption (White / Liturgical Gold)
          final date = DateTime(2026, 8, 15);
          final dayData = LiturgicalCalendar.computeDay(date);

          await tester.pumpWidget(
            buildCalendarWidget(selectedDate: date, isExpanded: false),
          );
          await tester.pumpAndSettle();

          final weekRow = find.descendant(
            of: find.byType(AnimatedCrossFade),
            matching: find.byType(Row),
          );
          final day15TextFinder = find.descendant(
            of: weekRow,
            matching: find.text('15'),
          );

          final inkWell = tester.widget<InkWell>(
            find.ancestor(of: day15TextFinder, matching: find.byType(InkWell)),
          );
          final container = inkWell.child as Container;
          final decoration = container.decoration as BoxDecoration;

          // Cell background is tinted with liturgical color (alpha 0.12 for current month)
          expect(
            decoration.color,
            equals(dayData.colorWidget.withValues(alpha: 0.12)),
          );

          // Find the liturgical bottom indicator bar within the day cell
          final cell15AspectRatio = find.ancestor(
            of: day15TextFinder,
            matching: find.byType(AspectRatio),
          );
          final bottomBarFinder = find.descendant(
            of: cell15AspectRatio,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.constraints?.maxWidth == 12 &&
                  w.constraints?.maxHeight == 3,
            ),
          );
          expect(bottomBarFinder, findsOneWidget);
          final bottomBarContainer = tester.widget<Container>(bottomBarFinder);
          final bottomBarDecoration =
              bottomBarContainer.decoration as BoxDecoration;
          expect(bottomBarDecoration.color, equals(dayData.colorWidget));
        },
      );

      testWidgets(
        'renders feast star indicator when feast is present and hides star when absent',
        (tester) async {
          // Aug 15 has Solemnity of the Assumption (computeDay.name != null)
          // Week of Aug 15 is Aug 9..15 (Aug 12 is Wednesday, Aug 13 is Thursday)
          final testDate = DateTime(2026, 8, 15);

          await tester.pumpWidget(
            buildCalendarWidget(
              selectedDate: testDate,
              isExpanded: false,
              hasSaintFeast: (date) =>
                  date.day == 12, // custom saint feast on 12th
            ),
          );
          await tester.pumpAndSettle();

          final weekRow = find.descendant(
            of: find.byType(AnimatedCrossFade),
            matching: find.byType(Row),
          );

          // Cell 15 has liturgical feast name -> star should be present
          final day15TextFinder = find.descendant(
            of: weekRow,
            matching: find.text('15'),
          );
          final cell15 = find.ancestor(
            of: day15TextFinder,
            matching: find.byType(AspectRatio),
          );
          final star15Finder = find.descendant(
            of: cell15,
            matching: find.byIcon(Icons.star),
          );
          expect(star15Finder, findsOneWidget);
          final star15Icon = tester.widget<Icon>(star15Finder);
          expect(star15Icon.color, equals(Colors.amber[800]));
          expect(star15Icon.size, equals(8));

          // Cell 12 has hasSaintFeast returning true -> star should be present
          final day12TextFinder = find.descendant(
            of: weekRow,
            matching: find.text('12'),
          );
          final cell12 = find.ancestor(
            of: day12TextFinder,
            matching: find.byType(AspectRatio),
          );
          final star12Finder = find.descendant(
            of: cell12,
            matching: find.byIcon(Icons.star),
          );
          expect(star12Finder, findsOneWidget);

          // Cell 13 (Thursday, no feast name and hasSaintFeast false) -> no star
          final day13TextFinder = find.descendant(
            of: weekRow,
            matching: find.text('13'),
          );
          final cell13 = find.ancestor(
            of: day13TextFinder,
            matching: find.byType(AspectRatio),
          );
          final star13Finder = find.descendant(
            of: cell13,
            matching: find.byIcon(Icons.star),
          );
          expect(star13Finder, findsNothing);
        },
      );
    });

    group('5. Animated Cross-Fade Transition', () {
      testWidgets('configures CrossFadeState based on isExpanded', (
        tester,
      ) async {
        // Collapsed
        await tester.pumpWidget(
          buildCalendarWidget(
            selectedDate: DateTime(2026, 8, 25),
            isExpanded: false,
          ),
        );
        await tester.pumpAndSettle();

        final crossFadeCollapsed = tester.widget<AnimatedCrossFade>(
          find.byType(AnimatedCrossFade),
        );
        expect(crossFadeCollapsed.crossFadeState, CrossFadeState.showFirst);

        // Expanded
        await tester.pumpWidget(
          buildCalendarWidget(
            selectedDate: DateTime(2026, 8, 25),
            isExpanded: true,
          ),
        );
        await tester.pumpAndSettle();

        final crossFadeExpanded = tester.widget<AnimatedCrossFade>(
          find.byType(AnimatedCrossFade),
        );
        expect(crossFadeExpanded.crossFadeState, CrossFadeState.showSecond);
      });
    });
  });
}
