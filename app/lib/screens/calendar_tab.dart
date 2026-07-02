import 'package:flutter/material.dart';
import '../logic/liturgical_calendar.dart';

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
    // Normalize to midnight
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
      _selectedDate = _selectedDate.add(Duration(days: offset));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = LiturgicalCalendar.computeDay(_selectedDate);

    // Calculate start of week (Sunday)
    final sunday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );
    final weekDays = List.generate(7, (i) => sunday.add(Duration(days: i)));

    // Calculate upcoming days
    final upcomingDays = List.generate(
      5,
      (i) => _selectedDate.add(Duration(days: i + 1)),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date Navigation & Picker Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDay(-1),
                    tooltip: 'Previous Day',
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _formatFullDate(_selectedDate),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to choose date',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDay(1),
                    tooltip: 'Next Day',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Interactive Week Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays.map((date) {
                  final isSelected =
                      date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  final dayData = LiturgicalCalendar.computeDay(date);
                  final isToday =
                      DateTime.now().year == date.year &&
                      DateTime.now().month == date.month &&
                      DateTime.now().day == date.day;

                  final dayAbbr = LiturgicalCalendar.getDayOfWeekName(
                    date.weekday,
                  ).substring(0, 3);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : isToday
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  )
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                dayAbbr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Liturgical Color Dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dayData.colorWidget,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 3. Main Liturgical Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Liturgical Color Accent Strip
                      Container(width: 12, color: currentDay.colorWidget),
                      // Card Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Season & Cycles Row
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
                                          letterSpacing: 1.2,
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
                              const SizedBox(height: 12),
                              // Liturgical Week / Day Name
                              Text(
                                currentDay.weekName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Liturgical Color Indicator Text
                              Row(
                                children: [
                                  Icon(
                                    Icons.lens,
                                    size: 12,
                                    color: currentDay.colorWidget,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Liturgical Color: ${currentDay.colorName}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
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
              const SizedBox(height: 16),

              // 4. Special Solemnity / Feast Alert Card (if any)
              if (currentDay.name != null) ...[
                Card(
                  elevation: 0,
                  color: currentDay.colorWidget.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: currentDay.colorWidget.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.church,
                          color: currentDay.colorWidget,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TODAY\'S SOLEMNITY / FEAST',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: currentDay.colorWidget,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentDay.name!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 5. Upcoming Liturgical Days
              Text(
                'Upcoming Days',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingDays.length,
                itemBuilder: (context, index) {
                  final nextDate = upcomingDays[index];
                  final nextDay = LiturgicalCalendar.computeDay(nextDate);
                  final isSunday = nextDate.weekday == DateTime.sunday;
                  final displayLabel = nextDay.name ?? nextDay.weekName;

                  // Format day abbreviation and number: e.g. "Fri 3"
                  final dayStr = LiturgicalCalendar.getDayOfWeekName(
                    nextDate.weekday,
                  ).substring(0, 3);
                  final dateStr = '${nextDate.day}';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedDate = nextDate;
                        });
                      },
                      leading: Container(
                        width: 44,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSunday
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSunday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        displayLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: nextDay.name != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        nextDay.seasonName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: nextDay.colorWidget,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 16),
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
    );
  }
}
