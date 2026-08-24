import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/time_helper.dart';
import 'package:twelve_stars/logic/bible_database.dart'
    show LectionaryReading, BibleDatabaseHelper;
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import 'package:twelve_stars/widgets/missal_calendar_grid.dart';
import 'package:twelve_stars/widgets/homily_reflection_sheet.dart';
import 'package:twelve_stars/widgets/reader/missal_section_widgets.dart';
import 'package:twelve_stars/widgets/missal_creed_carousel.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import 'package:twelve_stars/widgets/anima_christi_sheet.dart';

class MissalPrayerFilterOption {
  final String id;
  final String label;

  const MissalPrayerFilterOption({required this.id, required this.label});
}

const List<MissalPrayerFilterOption> kMissalPrayerFilterOptions = [
  MissalPrayerFilterOption(id: 'mass_greeting', label: 'Mass Greeting'),
  MissalPrayerFilterOption(id: 'confiteor', label: 'Confiteor'),
  MissalPrayerFilterOption(id: 'kyrie_eleison', label: 'Kyrie Eleison'),
  MissalPrayerFilterOption(id: 'gloria', label: 'Gloria'),
  MissalPrayerFilterOption(id: 'creed', label: 'Creed (Nicene / Apostles\')'),
  MissalPrayerFilterOption(
    id: 'offertory_response',
    label: 'Offertory Response',
  ),
  MissalPrayerFilterOption(id: 'orate_fratres', label: 'Orate Fratres'),
  MissalPrayerFilterOption(id: 'preface_dialogue', label: 'Preface Dialogue'),
  MissalPrayerFilterOption(id: 'sanctus', label: 'Sanctus'),
  MissalPrayerFilterOption(id: 'mystery_of_faith', label: 'Mystery of Faith'),
  MissalPrayerFilterOption(id: 'our_father', label: 'Our Father'),
  MissalPrayerFilterOption(id: 'embolism', label: 'Embolism & Doxology'),
  MissalPrayerFilterOption(id: 'sign_of_peace', label: 'Sign of Peace'),
  MissalPrayerFilterOption(id: 'agnus_dei', label: 'Agnus Dei'),
  MissalPrayerFilterOption(
    id: 'domine_non_sum_dignus',
    label: 'Domine Non Sum Dignus',
  ),
  MissalPrayerFilterOption(id: 'dismissal', label: 'Dismissal'),
];

class MissalTab extends StatefulWidget {
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final DateTime? initialDate;
  final Animation<double>? languageSelectorAnimation;
  final ScrollController? scrollController;
  final double fontSize;

  const MissalTab({
    super.key,
    required this.primaryLanguage,
    this.compareLanguage,
    this.initialDate,
    this.languageSelectorAnimation,
    this.scrollController,
    this.fontSize = 16.0,
  });

  @override
  State<MissalTab> createState() => _MissalTabState();
}

class _MissalTabState extends State<MissalTab> {
  late DateTime _selectedDate;
  bool _calendarExpanded = false;
  bool _loading = true;
  String? _error;
  List<Prayer>? _prayers;
  UserSettings? _settings;
  List<Saint>? _saints;
  Map<String, List<Saint>>? _feastDayMap;
  late PrayerLanguage _primaryLanguage;
  PrayerLanguage? _compareLanguage;

  Future<List<LectionaryReading>>? _readingsFuture;
  String? _cachedLectionaryKey;

  Future<List<LectionaryReading>> _getReadingsForDay(String lectionaryKey) {
    if (_readingsFuture == null || _cachedLectionaryKey != lectionaryKey) {
      _cachedLectionaryKey = lectionaryKey;
      _readingsFuture = BibleDatabaseHelper.db.getReadings(lectionaryKey);
    }
    return _readingsFuture!;
  }

  @override
  void initState() {
    super.initState();
    final baseDate = widget.initialDate ?? TimeHelper.now();
    _selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    _primaryLanguage = widget.primaryLanguage;
    _compareLanguage = widget.compareLanguage;
    _loadData();
  }

  @override
  void didUpdateWidget(MissalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryLanguage != widget.primaryLanguage ||
        oldWidget.compareLanguage != widget.compareLanguage) {
      setState(() {
        _primaryLanguage = widget.primaryLanguage;
        _compareLanguage = widget.compareLanguage;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final prayers = await PrayerDatabase.loadPrayers();
      final settings = await PrayerDatabase.loadSettings();
      final saints = await SaintDatabase.loadSaints();
      if (mounted) {
        setState(() {
          _prayers = prayers;
          _settings = settings;
          _saints = saints;
          _feastDayMap = SaintDatabase.buildFeastDayMap(saints);
          _primaryLanguage = settings.primaryLanguage;
          _compareLanguage = settings.compareLanguage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
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

  List<DateTime> _generateWeekDays(DateTime date) {
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

  Prayer? _findPrayer(String id) {
    if (_prayers == null) return null;
    try {
      return _prayers!.firstWhere((p) => p.prayerId == id);
    } catch (_) {
      return null;
    }
  }

  bool get _isTodaySelected {
    final now = TimeHelper.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  DateTime _getNextSunday(DateTime date) {
    final offset = 7 - date.weekday % 7;
    return DateTime(date.year, date.month, date.day + offset);
  }

  Widget _buildPrayerCard(Prayer prayer) {
    final prefKey = '${prayer.prayerId}_${_primaryLanguage.code}';
    final initialVersion =
        _settings?.preferredVersions
            ?.firstWhere(
              (p) => p.key == prefKey,
              orElse: () => PrayerVersionPreference(),
            )
            .versionIndex ??
        0;

    return PrayerCard(
      prayer: prayer,
      selectedLanguage: _primaryLanguage,
      compareLanguage: _compareLanguage,
      initialVersionIndex: initialVersion,
      fontSize: widget.fontSize,
      onVersionChanged: (newIndex) async {
        if (_settings != null) {
          final list = _settings!.preferredVersions ?? [];
          final idx = list.indexWhere((p) => p.key == prefKey);
          if (idx >= 0) {
            list[idx].versionIndex = newIndex;
          } else {
            list.add(PrayerVersionPreference(prefKey, newIndex));
          }
          _settings!.preferredVersions = list;
          await PrayerDatabase.saveSettings(_settings!);
        }
      },
    );
  }

  bool get _isReadingsOnly => _settings?.missalReadingsOnly ?? false;

  bool _isPrayerVisible(String id) {
    if (_settings == null) return true;
    if (_settings!.missalReadingsOnly) return false;
    final hidden = _settings!.missalHiddenPrayers ?? [];
    return !hidden.contains(id);
  }

  Future<void> _toggleReadingsOnly(bool enabled) async {
    if (_settings == null) return;
    setState(() {
      _settings!.missalReadingsOnly = enabled;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await UserSettingsController.instance.update(_settings!);
  }

  Future<void> _togglePrayerFilter(String prayerId, bool enabled) async {
    if (_settings == null) return;
    setState(() {
      final list = List<String>.from(_settings!.missalHiddenPrayers ?? []);
      if (enabled) {
        list.remove(prayerId);
      } else {
        if (!list.contains(prayerId)) {
          list.add(prayerId);
        }
      }
      _settings!.missalHiddenPrayers = list;
      if (_settings!.missalReadingsOnly) {
        _settings!.missalReadingsOnly = false;
      }
    });
    await PrayerDatabase.saveSettings(_settings!);
    await UserSettingsController.instance.update(_settings!);
  }

  Widget _buildFilterChips(BuildContext context) {
    final isReadingsOnly = _settings?.missalReadingsOnly ?? false;
    final hiddenPrayers = _settings?.missalHiddenPrayers ?? <String>[];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            key: const ValueKey('missal_filter_readings_only'),
            label: const Text('Readings Only'),
            selected: isReadingsOnly,
            onSelected: (selected) => _toggleReadingsOnly(selected),
          ),
          const SizedBox(width: 8),
          ...kMissalPrayerFilterOptions.map((option) {
            final isSelected =
                !isReadingsOnly && !hiddenPrayers.contains(option.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                key: ValueKey('missal_filter_${option.id}'),
                label: Text(option.label),
                selected: isSelected,
                onSelected: (selected) =>
                    _togglePrayerFilter(option.id, selected),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openHomilyReflection(
    BuildContext context,
    LiturgicalDay day,
    List<LectionaryReading> readings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => HomilyReflectionSheet(
        celebrationTitle: day.name ?? day.weekName,
        readings: readings,
      ),
    );
  }

  void _openAnimaChristiModal(BuildContext context, Prayer prayer) {
    AnimaChristiSheet.show(
      context,
      prayer: prayer,
      primaryLanguage: _primaryLanguage,
      compareLanguage: _compareLanguage,
      fontSize: widget.fontSize,
      settings: _settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading missal data: $_error',
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentDay = LiturgicalCalendar.computeDay(_selectedDate);
    final saintsForSelectedDate =
        _feastDayMap?['${_selectedDate.month}_${_selectedDate.day}'] ??
        (_saints != null
            ? SaintDatabase.getSaintsForDate(_selectedDate, _saints!)
            : <Saint>[]);

    final massGreeting = _findPrayer('mass_greeting');
    final confiteor = _findPrayer('confiteor');
    final kyrieEleison = _findPrayer('kyrie_eleison');
    final gloria = _findPrayer('gloria');
    final niceneCreed = _findPrayer('nicene_creed');
    final apostlesCreed = _findPrayer('apostles_creed');
    final sanctus = _findPrayer('sanctus');
    final offertoryResponse = _findPrayer('offertory_response');
    final orateFratres = _findPrayer('orate_fratres');
    final prefaceDialogue = _findPrayer('preface_dialogue');
    final mysteryOfFaith = _findPrayer('mystery_of_faith');
    final ourFather = _findPrayer('our_father');
    final embolism = _findPrayer('embolism');
    final signOfPeace = _findPrayer('sign_of_peace');
    final agnusDei = _findPrayer('agnus_dei');
    final domineNonSumDignus = _findPrayer('domine_non_sum_dignus');
    final dismissal = _findPrayer('dismissal');
    final animaChristi = _findPrayer('anima_christi');

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isTodaySelected) ...[
            FloatingActionButton.extended(
              heroTag: 'missal_today_fab',
              onPressed: () {
                setState(() {
                  final now = TimeHelper.now();
                  _selectedDate = DateTime(now.year, now.month, now.day);
                });
              },
              icon: const Icon(Icons.restore),
              label: const Text('Today'),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton.extended(
            heroTag: 'missal_next_sunday_fab',
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
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.languageSelectorAnimation != null)
                    SizeTransition(
                      sizeFactor: widget.languageSelectorAnimation!,
                      alignment: Alignment.topCenter,
                      child: const SizedBox(height: 92.0),
                    ),
                  Center(
                    child: Text(
                      'Mass Missal',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Collapsible Calendar View (Constrained to 480px)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: MissalCalendarGrid(
                        selectedDate: _selectedDate,
                        isExpanded: _calendarExpanded,
                        hasSaintFeast: (date) =>
                            _feastDayMap?.containsKey(
                              '${date.month}_${date.day}',
                            ) ??
                            false,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                            _calendarExpanded = false;
                          });
                        },
                        onMonthChange: _changeMonth,
                        onDayChange: _changeDay,
                        onToggleExpand: () {
                          setState(() {
                            _calendarExpanded = !_calendarExpanded;
                          });
                        },
                        formatMonthYear: _formatMonthYear,
                        formatFullDate: _formatFullDate,
                        generateWeekDays: _generateWeekDays,
                        generateMonthGrid: _generateMonthDays,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Main Liturgical Card
                  MissalLiturgicalCard(currentDay: currentDay),
                  const SizedBox(height: 8),

                  // 3. Special Solemnity / Feast Alert Card (if any)
                  if (currentDay.name != null) ...[
                    MissalFeastAlertCard(currentDay: currentDay),
                    const SizedBox(height: 8),
                  ],

                  // Saint Feast / Memorial Cards (if any)
                  if (saintsForSelectedDate.isNotEmpty) ...[
                    ...saintsForSelectedDate.map(
                      (saint) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: MissalSaintFeastCard(
                          saint: saint,
                          onTap: () => SaintDetailsSheet.show(context, saint),
                        ),
                      ),
                    ),
                  ],

                  // Filter Chips
                  _buildFilterChips(context),
                  const SizedBox(height: 12),

                  // 4. Introductory Rites Section
                  if (!_isReadingsOnly) ...[
                    const MissalSectionHeader(title: 'INTRODUCTORY RITES'),
                    const MissalMassPartPlaceholder(
                      title: 'Entrance Chant',
                      description: 'Entrance Antiphon of the day',
                      icon: Icons.music_note,
                    ),
                    const SizedBox(height: 12),
                    if (_isPrayerVisible('mass_greeting') &&
                        massGreeting != null) ...[
                      _buildPrayerCard(massGreeting),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('confiteor') && confiteor != null) ...[
                      _buildPrayerCard(confiteor),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('kyrie_eleison')) ...[
                      if (kyrieEleison != null)
                        _buildPrayerCard(kyrieEleison)
                      else
                        const MissalMassPartPlaceholder(
                          title: 'Kyrie Eleison',
                          description: 'Kyrie, eleison (Lord, have mercy...)',
                          icon: Icons.volunteer_activism,
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('gloria') && gloria != null) ...[
                      _buildPrayerCard(gloria),
                      const SizedBox(height: 12),
                    ],
                    const MissalMassPartPlaceholder(
                      title: 'Collect (Opening Prayer)',
                      description: 'Opening prayer of the day',
                      icon: Icons.bookmark_border,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 5. Liturgy of the Word Section
                  const MissalSectionHeader(title: 'LITURGY OF THE WORD'),
                  FutureBuilder<List<LectionaryReading>>(
                    future: _getReadingsForDay(currentDay.lectionaryKey),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            MissalHomilySectionCard(
                              currentDay: currentDay,
                              readings: const [],
                              onOpenHomilyReflection: _openHomilyReflection,
                            ),
                          ],
                        );
                      }
                      if (snapshot.hasError) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Error loading readings: ${snapshot.error}',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 4),
                            MissalHomilySectionCard(
                              currentDay: currentDay,
                              readings: const [],
                              onOpenHomilyReflection: _openHomilyReflection,
                            ),
                          ],
                        );
                      }
                      final readings = (snapshot.data ?? []).toList();

                      // Sort readings: First Reading, Responsorial Psalm, Second Reading, Gospel
                      readings.sort((a, b) {
                        const order = {
                          'first': 0,
                          'psalm': 1,
                          'second': 2,
                          'gospel': 3,
                        };
                        final indexA = order[a.readingType] ?? 99;
                        final indexB = order[b.readingType] ?? 99;
                        return indexA.compareTo(indexB);
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (readings.isEmpty) ...[
                            Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerHigh,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 32,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No readings seeded for this date.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            MissalHomilySectionCard(
                              currentDay: currentDay,
                              readings: const [],
                              onOpenHomilyReflection: _openHomilyReflection,
                            ),
                          ] else ...[
                            ...readings.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: MassReadingCard(
                                  reading: r,
                                  fontSize: widget.fontSize,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            MissalHomilySectionCard(
                              currentDay: currentDay,
                              readings: readings,
                              onOpenHomilyReflection: _openHomilyReflection,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (!_isReadingsOnly && _isPrayerVisible('creed')) ...[
              const SizedBox(height: 12),
              // Creed swipeable carousel
              MissalCreedCarousel(
                niceneCard: niceneCreed != null
                    ? _buildPrayerCard(niceneCreed)
                    : null,
                apostlesCard: apostlesCreed != null
                    ? _buildPrayerCard(apostlesCreed)
                    : null,
              ),
            ],
            if (!_isReadingsOnly) ...[
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: MissalMassPartPlaceholder(
                  title: 'Universal Prayer (Prayers of the Faithful)',
                  description:
                      'Petitions for the Church, the world, and those in need',
                  icon: Icons.people,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 6. Liturgy of the Eucharist Section
                    const MissalSectionHeader(
                      title: 'LITURGY OF THE EUCHARIST',
                    ),
                    const MissalMassPartPlaceholder(
                      title: 'Preparation of the Altar (Offertory)',
                      description:
                          'Presentation and preparation of bread and wine',
                      icon: Icons.restaurant,
                    ),
                    const SizedBox(height: 12),
                    if (_isPrayerVisible('offertory_response') &&
                        offertoryResponse != null) ...[
                      _buildPrayerCard(offertoryResponse),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('orate_fratres') &&
                        orateFratres != null) ...[
                      _buildPrayerCard(orateFratres),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('preface_dialogue') &&
                        prefaceDialogue != null) ...[
                      _buildPrayerCard(prefaceDialogue),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('sanctus')) ...[
                      if (sanctus != null)
                        _buildPrayerCard(sanctus)
                      else
                        const MissalMassPartPlaceholder(
                          title: 'Sanctus (Holy, Holy, Holy)',
                          description: 'Holy, Holy, Holy Lord God of hosts...',
                          icon: Icons.notifications_active,
                        ),
                      const SizedBox(height: 12),
                    ],
                    const MissalMassPartPlaceholder(
                      title: 'Eucharistic Prayer & Consecration',
                      description:
                          'Eucharistic prayer and consecration of bread and wine',
                      icon: Icons.brightness_high,
                    ),
                    const SizedBox(height: 12),
                    if (_isPrayerVisible('mystery_of_faith') &&
                        mysteryOfFaith != null) ...[
                      _buildPrayerCard(mysteryOfFaith),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('our_father') &&
                        ourFather != null) ...[
                      _buildPrayerCard(ourFather),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('embolism') && embolism != null) ...[
                      _buildPrayerCard(embolism),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('sign_of_peace')) ...[
                      if (signOfPeace != null)
                        _buildPrayerCard(signOfPeace)
                      else
                        const MissalMassPartPlaceholder(
                          title: 'Sign of Peace',
                          description:
                              'Greeting one another with a sign of peace',
                          icon: Icons.handshake,
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('agnus_dei')) ...[
                      if (agnusDei != null)
                        _buildPrayerCard(agnusDei)
                      else
                        const MissalMassPartPlaceholder(
                          title: 'Agnus Dei (Lamb of God)',
                          description:
                              'Lamb of God, you take away the sins of the world...',
                          icon: Icons.spa,
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (_isPrayerVisible('domine_non_sum_dignus') &&
                        domineNonSumDignus != null) ...[
                      _buildPrayerCard(domineNonSumDignus),
                      const SizedBox(height: 12),
                    ],
                    MissalCommunionSectionCard(
                      animaChristi: animaChristi,
                      onOpenAnimaChristi: _openAnimaChristiModal,
                    ),
                  ],
                ),
              ),
            ],
            if (!_isReadingsOnly && _isPrayerVisible('dismissal')) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 7. Concluding Rites Section
                    const MissalSectionHeader(title: 'CONCLUDING RITES'),
                    if (dismissal != null) ...[
                      _buildPrayerCard(dismissal),
                      const SizedBox(height: 12),
                    ] else ...[
                      const MissalMassPartPlaceholder(
                        title: 'Concluding Blessing & Dismissal',
                        description:
                            'Blessing and sending forth: "Go in peace..."',
                        icon: Icons.logout,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
