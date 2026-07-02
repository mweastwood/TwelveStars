import 'package:flutter/material.dart';
import '../logic/liturgical_calendar.dart';
import '../logic/bible_database.dart'
    show LectionaryReading, BibleDatabaseHelper;
import '../widgets/mass_reading_card.dart';

class MissalTab extends StatefulWidget {
  const MissalTab({super.key});

  @override
  State<MissalTab> createState() => _MissalTabState();
}

class _MissalTabState extends State<MissalTab> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Default to the fixed test date July 2, 2026 for consistent initial states and screenshots,
    // or today's date if outside test context
    final now = DateTime.now();
    if (now.year == 2026 && now.month == 7 && now.day == 2) {
      _selectedDate = now;
    } else {
      _selectedDate = DateTime(2026, 7, 2);
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final dayName = LiturgicalCalendar.getDayOfWeekName(date.weekday);
    final months = [
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
    return '$dayName, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = LiturgicalCalendar.computeDay(_selectedDate);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date Picker / Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: () => _changeDay(-1),
                    tooltip: 'Previous Day',
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDate(_selectedDate),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _changeDay(1),
                    tooltip: 'Next Day',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Liturgical Day Info Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 64,
                        decoration: BoxDecoration(
                          color: currentDay.colorWidget,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currentDay.seasonName.toUpperCase(),
                                  style: theme.textTheme.labelMedium?.copyWith(
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
                            const SizedBox(height: 8),
                            Text(
                              currentDay.weekName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Color: ${currentDay.colorName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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

              // 3. Special Solemnity / Feast Alert Card (if any)
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

              // 4. Readings List
              FutureBuilder<List<LectionaryReading>>(
                future: BibleDatabaseHelper.db.getReadings(
                  currentDay.lectionaryKey,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
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
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 40,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Readings Seeded',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Liturgical mass reading citations for this date are not seeded in the test database. \n\nTry browsing to: \n• July 2, 2026 (Daily)\n• July 5, 2026 (Sunday)\n• August 15, 2026 (Assumption Feast)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY\'S LITURGY OF THE WORD',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...readings.map((r) => MassReadingCard(reading: r)),
                    ],
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
