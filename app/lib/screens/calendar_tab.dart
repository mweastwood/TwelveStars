import 'package:flutter/material.dart';
import '../logic/liturgical_calendar.dart';
import '../logic/bible_database.dart'
    show LectionaryReading, BibleDatabaseHelper;
import '../widgets/mass_reading_card.dart';

class CalendarTab extends StatefulWidget {
  final DateTime? initialDate;

  const CalendarTab({super.key, this.initialDate});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final baseDate = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + offset,
      );
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      final firstOfTargetMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
        1,
      );
      final maxDays = DateTime(
        firstOfTargetMonth.year,
        firstOfTargetMonth.month + 1,
        0,
      ).day;
      final targetDay = _selectedDate.day.clamp(1, maxDays);
      _selectedDate = DateTime(
        firstOfTargetMonth.year,
        firstOfTargetMonth.month,
        targetDay,
      );
    });
  }

  String _formatFullDate(DateTime date) {
    final weekday = LiturgicalCalendar.getDayOfWeekName(date.weekday);
    final monthNames = [
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
    final month = monthNames[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    final monthNames = [
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

  List<DateTime> _generateMonthDays(DateTime date) {
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

  bool get _isTodaySelected {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  DateTime _getNextSunday(DateTime date) {
    final offset = 7 - date.weekday % 7;
    return DateTime(date.year, date.month, date.day + offset);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = LiturgicalCalendar.computeDay(_selectedDate);

    // Generate grid days for currently selected month
    final gridDays = _generateMonthDays(_selectedDate);
    final weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isTodaySelected) ...[
            FloatingActionButton.extended(
              heroTag: 'today_fab',
              onPressed: () {
                setState(() {
                  final now = DateTime.now();
                  _selectedDate = DateTime(now.year, now.month, now.day);
                });
              },
              icon: const Icon(Icons.restore),
              label: const Text('Today'),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton.extended(
            heroTag: 'next_sunday_fab',
            onPressed: () {
              setState(() {
                _selectedDate = _getNextSunday(_selectedDate);
              });
            },
            icon: const Icon(Icons.navigate_next),
            label: const Text('Next Sunday'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Month View (Constrained to 480px)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Month Navigation Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            onPressed: () => _changeMonth(-1),
                            tooltip: 'Previous Month',
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatMonthYear(_selectedDate),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () => _changeMonth(1),
                            tooltip: 'Next Month',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 2. Weekday Label Header
                      Row(
                        children: weekdayLabels.map((label) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),

                      // 3. Month Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1.0,
                              mainAxisSpacing: 4.0,
                              crossAxisSpacing: 4.0,
                            ),
                        itemCount: gridDays.length,
                        itemBuilder: (context, index) {
                          final date = gridDays[index];
                          final isCurrentMonth =
                              date.month == _selectedDate.month;
                          if (!isCurrentMonth) {
                            return const SizedBox.shrink();
                          }
                          final isSelected =
                              date.year == _selectedDate.year &&
                              date.month == _selectedDate.month &&
                              date.day == _selectedDate.day;
                          final isToday =
                              DateTime.now().year == date.year &&
                              DateTime.now().month == date.month &&
                              DateTime.now().day == date.day;

                          final dayData = LiturgicalCalendar.computeDay(date);

                          // Colors for cell styling
                          final baseColor = dayData.colorWidget;
                          final cellBg = baseColor.withValues(
                            alpha: isCurrentMonth ? 0.12 : 0.04,
                          );

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cellBg,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      )
                                    : isToday
                                    ? Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  // Star icon for Feasts/Solemnities
                                  if (dayData.name != null)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Icon(
                                        Icons.star,
                                        size: 8,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  // Day Number
                                  Center(
                                    child: Text(
                                      '${date.day}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: isSelected || isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isCurrentMonth
                                                ? theme.colorScheme.onSurface
                                                : theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.35),
                                          ),
                                    ),
                                  ),
                                  // Liturgical Color indicator bar (bottom of cell)
                                  Positioned(
                                    bottom: 4,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        width: 12,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: baseColor,
                                          borderRadius: BorderRadius.circular(
                                            1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Selected Day Text Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDay(-1),
                    tooltip: 'Previous Day',
                  ),
                  Expanded(
                    child: Text(
                      _formatFullDate(_selectedDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDay(1),
                    tooltip: 'Next Day',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 5. Main Liturgical Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 10, color: currentDay.colorWidget),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    currentDay.seasonName.toUpperCase(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.secondary,
                                          letterSpacing: 1.1,
                                        ),
                                  ),
                                  Text(
                                    'Cycle ${currentDay.sundayCycle} • Year ${currentDay.weekdayCycle}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                currentDay.weekName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lens,
                                    size: 10,
                                    color: currentDay.colorWidget,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Color: ${currentDay.colorName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 6. Special Solemnity / Feast Alert Card (if any)
              if (currentDay.name != null) ...[
                Card(
                  elevation: 0,
                  color: currentDay.colorWidget.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: currentDay.colorWidget.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.church,
                          color: currentDay.colorWidget,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOLEMNITY / FEAST',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: currentDay.colorWidget,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentDay.name!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              FutureBuilder<List<LectionaryReading>>(
                future: BibleDatabaseHelper.db.getReadings(
                  currentDay.lectionaryKey,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading readings: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    );
                  }
                  final readings = snapshot.data ?? [];
                  if (readings.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MASS READINGS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...readings.map((r) => MassReadingCard(reading: r)),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}
