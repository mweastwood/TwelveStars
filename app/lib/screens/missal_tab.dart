import 'package:flutter/foundation.dart' show setEquals;
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
import 'package:twelve_stars/widgets/reader/missal_ordinary_sections.dart';
import 'package:twelve_stars/widgets/reader/missal_section_widgets.dart';
import 'package:twelve_stars/widgets/missal_creed_carousel.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import 'package:twelve_stars/widgets/anima_christi_sheet.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

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
  MissalPrayerFilterOption(id: 'universal_prayer', label: 'Universal Prayer'),
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
  static const Map<String, int> _readingTypeOrder = {
    'first': 0,
    'psalm': 1,
    'second': 2,
    'gospel': 3,
  };

  static const List<String> _monthNames = [
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

  late DateTime _selectedDate;
  bool _calendarExpanded = false;
  bool _loading = true;
  String? _error;
  Map<String, Prayer>? _prayersById;
  UserSettings? _settings;
  bool _readingsOnly = false;
  Set<String> _hiddenPrayers = const {};
  List<Saint>? _saints;
  Map<String, List<Saint>>? _feastDayMap;
  late PrayerLanguage _primaryLanguage;
  PrayerLanguage? _compareLanguage;
  MassReadingSelection? _activeSelection;

  Future<List<LectionaryReading>>? _readingsFuture;
  String? _cachedLectionaryKey;

  Future<List<LectionaryReading>> _getReadingsForDay(String lectionaryKey) {
    if (_readingsFuture == null || _cachedLectionaryKey != lectionaryKey) {
      _cachedLectionaryKey = lectionaryKey;
      _activeSelection = null;
      _readingsFuture = BibleDatabaseHelper.db
          .getReadings(lectionaryKey)
          .then(
            (list) => list.toList()
              ..sort((a, b) {
                final orderA =
                    _readingTypeOrder[a.readingType.toLowerCase()] ?? 99;
                final orderB =
                    _readingTypeOrder[b.readingType.toLowerCase()] ?? 99;
                final cmp = orderA.compareTo(orderB);
                return cmp != 0 ? cmp : a.id.compareTo(b.id);
              }),
          );
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
    UserSettingsController.instance.addListener(_onSettingsChanged);
    _loadData();
  }

  @override
  void dispose() {
    UserSettingsController.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final settings = UserSettingsController.instance.value;
    final nextHidden = (settings.missalHiddenPrayers ?? const []).toSet();
    final changed =
        _primaryLanguage != settings.primaryLanguage ||
        _compareLanguage != settings.compareLanguage ||
        _readingsOnly != settings.missalReadingsOnly ||
        !setEquals(_hiddenPrayers, nextHidden);
    _settings = settings;
    if (changed) {
      setState(() {
        _readingsOnly = settings.missalReadingsOnly;
        _hiddenPrayers = nextHidden;
        _primaryLanguage = settings.primaryLanguage;
        _compareLanguage = settings.compareLanguage;
      });
    }
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
      final settings = await UserSettingsController.instance.load();
      final saints = await SaintDatabase.loadSaints();
      if (mounted) {
        setState(() {
          _prayersById = {for (final p in prayers) p.prayerId: p};
          _settings = settings;
          _readingsOnly = settings.missalReadingsOnly;
          _hiddenPrayers = (settings.missalHiddenPrayers ?? const []).toSet();
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
      _activeSelection = null;
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
      _activeSelection = null;
    });
  }

  String _formatFullDate(DateTime date) {
    final weekday = LiturgicalCalendar.getDayOfWeekName(date.weekday);
    final month = _monthNames[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
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

  Prayer? _findPrayer(String id) => _prayersById?[id];

  @visibleForTesting
  Prayer? findPrayerForTesting(String id) => _findPrayer(id);

  @visibleForTesting
  Map<String, Prayer>? get prayersByIdForTesting => _prayersById;

  @visibleForTesting
  Set<String> get hiddenPrayersForTesting => _hiddenPrayers;

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
    final initialVersion = _settings?.getPreferredVersionIndex(prefKey) ?? 0;

    return PrayerCard(
      prayer: prayer,
      selectedLanguage: _primaryLanguage,
      compareLanguage: _compareLanguage,
      initialVersionIndex: initialVersion,
      fontSize: widget.fontSize,
      onVersionChanged: (newIndex) async {
        await UserSettingsController.instance.mutate((s) {
          s.setPreferredVersionIndex(prefKey, newIndex);
        });
      },
    );
  }

  bool get _isReadingsOnly => _readingsOnly;

  bool _isPrayerVisible(String id) {
    if (_settings == null) return true;
    if (_readingsOnly) return false;
    return !_hiddenPrayers.contains(id);
  }

  Future<void> _toggleReadingsOnly(bool enabled) async {
    if (_settings == null) return;
    await UserSettingsController.instance.mutate((s) {
      s.missalReadingsOnly = enabled;
    });
  }

  Future<void> _togglePrayerFilter(String prayerId, bool enabled) async {
    if (_settings == null) return;
    final updated = Set<String>.of(_hiddenPrayers);
    if (enabled) {
      updated.remove(prayerId);
    } else {
      updated.add(prayerId);
    }
    await UserSettingsController.instance.mutate((s) {
      s.missalHiddenPrayers = updated.toList();
      if (s.missalReadingsOnly) {
        s.missalReadingsOnly = false;
      }
    });
  }

  Widget _buildFilterChips(BuildContext context) {
    final isReadingsOnly = _settings?.missalReadingsOnly ?? false;

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
                !isReadingsOnly && !_hiddenPrayers.contains(option.id);
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
    final universalPrayer = _findPrayer('universal_prayer');
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
      floatingActionButton: _activeSelection != null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_isTodaySelected) ...[
                  FloatingActionButton.extended(
                    key: const Key('missal_today_fab'),
                    heroTag: 'missal_today_fab',
                    onPressed: () {
                      setState(() {
                        final now = TimeHelper.now();
                        _selectedDate = DateTime(now.year, now.month, now.day);
                        _activeSelection = null;
                      });
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Today'),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton.extended(
                  key: const Key('missal_next_sunday_fab'),
                  heroTag: 'missal_next_sunday_fab',
                  onPressed: () {
                    setState(() {
                      _selectedDate = _getNextSunday(_selectedDate);
                      _activeSelection = null;
                    });
                  },
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Next Sunday'),
                ),
              ],
            ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                                _activeSelection = null;
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
                              onTap: () =>
                                  SaintDetailsSheet.show(context, saint),
                            ),
                          ),
                        ),
                      ],

                      // Filter Chips
                      _buildFilterChips(context),
                      const SizedBox(height: 12),

                      // 4. Introductory Rites Section
                      if (!_isReadingsOnly)
                        MissalIntroductoryRitesSection(
                          isPrayerVisible: _isPrayerVisible,
                          buildPrayerCard: _buildPrayerCard,
                          massGreeting: massGreeting,
                          confiteor: confiteor,
                          kyrieEleison: kyrieEleison,
                          gloria: gloria,
                        ),

                      // 5. Liturgy of the Word Section
                      const MissalSectionHeader(title: 'LITURGY OF THE WORD'),
                      FutureBuilder<List<LectionaryReading>>(
                        future: _getReadingsForDay(currentDay.lectionaryKey),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            if (_activeSelection != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _activeSelection != null) {
                                  setState(() {
                                    _activeSelection = null;
                                  });
                                }
                              });
                            }
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
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
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
                          final readings = snapshot.data ?? const [];

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
                                ...readings.map((r) {
                                  final readingIdentifier =
                                      '${r.readingKey}_${r.readingType}_${r.id}';
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: MassReadingCard(
                                      reading: r,
                                      fontSize: widget.fontSize,
                                      primaryLanguage: _primaryLanguage,
                                      compareLanguage: _compareLanguage,
                                      isSelected:
                                          _activeSelection?.readingIdentifier ==
                                          readingIdentifier,
                                      onSelectionChanged: (selection) {
                                        setState(() {
                                          _activeSelection = selection;
                                        });
                                      },
                                    ),
                                  );
                                }),
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
                  if (_isPrayerVisible('universal_prayer')) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: universalPrayer != null
                          ? _buildPrayerCard(universalPrayer)
                          : const MissalMassPartPlaceholder(
                              title:
                                  'Universal Prayer (Prayers of the Faithful)',
                              description:
                                  'Petitions for the Church, the world, and those in need',
                              icon: Icons.people,
                            ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  MissalLiturgyOfTheEucharistSection(
                    isPrayerVisible: _isPrayerVisible,
                    buildPrayerCard: _buildPrayerCard,
                    offertoryResponse: offertoryResponse,
                    orateFratres: orateFratres,
                    prefaceDialogue: prefaceDialogue,
                    sanctus: sanctus,
                    mysteryOfFaith: mysteryOfFaith,
                    ourFather: ourFather,
                    embolism: embolism,
                    signOfPeace: signOfPeace,
                    agnusDei: agnusDei,
                    domineNonSumDignus: domineNonSumDignus,
                    animaChristi: animaChristi,
                    onOpenAnimaChristi: _openAnimaChristiModal,
                  ),
                ],
                if (!_isReadingsOnly && _isPrayerVisible('dismissal')) ...[
                  const SizedBox(height: 12),
                  MissalConcludingRitesSection(
                    buildPrayerCard: _buildPrayerCard,
                    dismissal: dismissal,
                  ),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
          if (_activeSelection != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ReaderSelectionActionBar(
                      title: _activeSelection!.citation,
                      selectedCount: _activeSelection!.selectedCount,
                      itemLabel: 'verse',
                      onSaveFavorite: _activeSelection!.onSaveFavorite,
                      onCopy: _activeSelection!.onCopy,
                      onAddComment: _activeSelection!.onAddComment,
                      onClearSelection: () {
                        _activeSelection!.onClearSelection();
                        setState(() {
                          _activeSelection = null;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
