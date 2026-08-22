import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/time_helper.dart';

class MissalCalendarGrid extends StatelessWidget {
  final DateTime selectedDate;
  final bool isExpanded;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int> onMonthChange;
  final ValueChanged<int> onDayChange;
  final VoidCallback onToggleExpand;
  final String Function(DateTime) formatMonthYear;
  final String Function(DateTime) formatFullDate;
  final List<DateTime> Function(DateTime) generateWeekDays;
  final List<DateTime> Function(DateTime) generateMonthGrid;
  final bool Function(DateTime date)? hasSaintFeast;

  const MissalCalendarGrid({
    super.key,
    required this.selectedDate,
    required this.isExpanded,
    required this.onDateSelected,
    required this.onMonthChange,
    required this.onDayChange,
    required this.onToggleExpand,
    required this.formatMonthYear,
    required this.formatFullDate,
    required this.generateWeekDays,
    required this.generateMonthGrid,
    this.hasSaintFeast,
  });

  static const List<String> _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Unified Navigation Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                isExpanded ? Icons.arrow_back_ios : Icons.chevron_left,
                size: isExpanded ? 16 : 24,
              ),
              onPressed: () => isExpanded ? onMonthChange(-1) : onDayChange(-1),
              tooltip: isExpanded ? 'Previous Month' : 'Previous Day',
            ),
            Expanded(
              child: InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isExpanded
                            ? formatMonthYear(selectedDate)
                            : formatFullDate(selectedDate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isExpanded ? Icons.arrow_forward_ios : Icons.chevron_right,
                size: isExpanded ? 16 : 24,
              ),
              onPressed: () => isExpanded ? onMonthChange(1) : onDayChange(1),
              tooltip: isExpanded ? 'Next Month' : 'Next Day',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Weekday Label Header
        Row(
          children: _weekdayLabels.map((label) {
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // 3. Calendar View with Smooth Animation
        AnimatedCrossFade(
          firstChild: _buildWeekRow(theme),
          secondChild: _buildMonthGrid(theme),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
        ),
      ],
    );
  }

  Widget _buildWeekRow(ThemeData theme) {
    return Row(
      children: generateWeekDays(selectedDate).map((date) {
        return Expanded(child: _buildDayCell(theme, date));
      }).toList(),
    );
  }

  Widget _buildMonthGrid(ThemeData theme) {
    final gridDays = generateMonthGrid(selectedDate);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ),
      itemCount: gridDays.length,
      itemBuilder: (context, index) {
        final date = gridDays[index];
        final isCurrentMonth = date.month == selectedDate.month;
        if (!isCurrentMonth) {
          return const SizedBox.shrink();
        }
        return _buildDayCell(
          theme,
          date,
          isCurrentMonth: true,
          onTap: () => onDateSelected(date),
        );
      },
    );
  }

  Widget _buildDayCell(
    ThemeData theme,
    DateTime date, {
    bool isCurrentMonth = true,
    VoidCallback? onTap,
  }) {
    final isSelected =
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
    final today = TimeHelper.now();
    final isToday =
        today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;

    final dayData = LiturgicalCalendar.computeDay(date);
    final baseColor = dayData.colorWidget;
    final cellBg = baseColor.withValues(alpha: isCurrentMonth ? 0.12 : 0.04);
    final hasFeast =
        dayData.name != null || (hasSaintFeast != null && hasSaintFeast!(date));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: InkWell(
          onTap: onTap ?? () => onDateSelected(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: cellBg,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : isToday
                  ? Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (hasFeast)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(Icons.star, size: 8, color: Colors.amber[800]),
                  ),
                Center(
                  child: Text(
                    '${date.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentMonth
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
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
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
